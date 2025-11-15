//
//  ProcessManager.swift
//  MemoryInjector
//
//  Gerenciamento de processos e conexão com processo alvo
//

import Foundation
import MachO

class ProcessManager {
    static let shared = ProcessManager()
    
    private var targetTask: mach_port_t = MACH_PORT_NULL
    private var targetPID: pid_t = 0
    private var isAttached: Bool = false
    
    private init() {}
    
    // MARK: - Process Discovery
    
    /// Lista todos os processos em execução
    func listRunningProcesses() -> [(pid: pid_t, name: String)] {
        var processes: [(pid: pid_t, name: String)] = []
        
        var count: UInt32 = 0
        var pids = [pid_t](repeating: 0, count: 1024)
        
        let result = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(MemoryLayout<pid_t>.size * pids.count))
        
        if result > 0 {
            count = UInt32(result) / UInt32(MemoryLayout<pid_t>.size)
            
            for i in 0..<Int(count) {
                let pid = pids[i]
                if pid > 0 {
                    if let name = getProcessName(pid: pid) {
                        processes.append((pid: pid, name: name))
                    }
                }
            }
        }
        
        return processes
    }
    
    /// Obtém o nome de um processo pelo PID
    func getProcessName(pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
        let ret = proc_pidpath(pid, &buffer, UInt32(PROC_PIDPATHINFO_MAXSIZE))
        
        if ret > 0 {
            let path = String(cString: buffer)
            return (path as NSString).lastPathComponent
        }
        
        return nil
    }
    
    /// Encontra PID por nome do processo
    func findProcessByName(_ name: String) -> pid_t? {
        let processes = listRunningProcesses()
        return processes.first(where: { $0.name.lowercased().contains(name.lowercased()) })?.pid
    }
    
    // MARK: - Process Attachment
    
    /// Anexa ao processo alvo
    func attach(pid: pid_t) -> Bool {
        if isAttached && targetPID == pid {
            return true
        }
        
        // Desanexa do processo anterior se houver
        detach()
        
        var task: mach_port_t = MACH_PORT_NULL
        let kr = task_for_pid(mach_task_self_, pid, &task)
        
        if kr == KERN_SUCCESS {
            targetTask = task
            targetPID = pid
            isAttached = true
            print("✅ Attached to process \(pid)")
            return true
        } else {
            print("❌ Failed to attach to process \(pid): \(machErrorString(kr))")
            return false
        }
    }
    
    /// Anexa ao processo por nome
    func attach(processName: String) -> Bool {
        guard let pid = findProcessByName(processName) else {
            print("❌ Process '\(processName)' not found")
            return false
        }
        return attach(pid: pid)
    }
    
    /// Desanexa do processo atual
    func detach() {
        if isAttached {
            mach_port_deallocate(mach_task_self_, targetTask)
            targetTask = MACH_PORT_NULL
            targetPID = 0
            isAttached = false
            print("🔌 Detached from process")
        }
    }
    
    // MARK: - Process Info
    
    /// Verifica se está anexado a um processo
    func isProcessAttached() -> Bool {
        return isAttached
    }
    
    /// Obtém o PID do processo atual
    func getCurrentPID() -> pid_t {
        return targetPID
    }
    
    /// Obtém o task port do processo atual
    func getCurrentTask() -> mach_port_t {
        return targetTask
    }
    
    /// Obtém informações do processo
    func getProcessInfo() -> String? {
        guard isAttached else { return nil }
        
        var info = proc_taskinfo()
        var size = MemoryLayout<proc_taskinfo>.size
        
        let result = proc_pidinfo(targetPID, PROC_PIDTASKINFO, 0, &info, Int32(size))
        
        if result == Int32(size) {
            let virtualSize = Double(info.pti_virtual_size) / 1024.0 / 1024.0
            let residentSize = Double(info.pti_resident_size) / 1024.0 / 1024.0
            
            return """
            PID: \(targetPID)
            Virtual Size: \(String(format: "%.2f", virtualSize)) MB
            Resident Size: \(String(format: "%.2f", residentSize)) MB
            Threads: \(info.pti_threadnum)
            """
        }
        
        return nil
    }
    
    // MARK: - Memory Regions
    
    /// Enumera todas as regiões de memória do processo
    func enumerateMemoryRegions(callback: (MemoryRegion) -> Bool) {
        guard isAttached else { return }
        
        var address: mach_vm_address_t = 0
        var size: mach_vm_size_t = 0
        var info = vm_region_basic_info_data_64_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_region_basic_info_data_64_t>.size / MemoryLayout<natural_t>.size)
        var objectName: mach_port_t = MACH_PORT_NULL
        
        while true {
            let kr = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: Int32.self, capacity: 1) {
                    mach_vm_region(targetTask, &address, &size, VM_REGION_BASIC_INFO_64, $0, &count, &objectName)
                }
            }
            
            if kr != KERN_SUCCESS {
                break
            }
            
            let region = MemoryRegion(
                address: address,
                size: size,
                protection: info.protection
            )
            
            if !callback(region) {
                break
            }
            
            address += size
        }
    }
    
    // MARK: - Utilities
    
    private func machErrorString(_ kr: kern_return_t) -> String {
        if let cString = mach_error_string(kr) {
            return String(cString: cString)
        }
        return "Unknown error (\(kr))"
    }
}
