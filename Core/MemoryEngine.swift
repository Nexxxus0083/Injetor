//
//  MemoryEngine.swift
//  MemoryInjector
//
//  Engine principal de injeção de memória (API h5gg-like)
//

import Foundation

class MemoryEngine {
    static let shared = MemoryEngine()
    
    private let processManager = ProcessManager.shared
    private let memoryScanner = MemoryScanner.shared
    
    private init() {}
    
    // MARK: - Process Management
    
    /// Anexa ao processo alvo
    func attachProcess(_ processName: String) -> Bool {
        return processManager.attach(processName: processName)
    }
    
    /// Anexa ao processo por PID
    func attachProcess(pid: pid_t) -> Bool {
        return processManager.attach(pid: pid)
    }
    
    /// Desanexa do processo
    func detachProcess() {
        processManager.detach()
    }
    
    /// Verifica se está anexado
    func isAttached() -> Bool {
        return processManager.isProcessAttached()
    }
    
    // MARK: - Search Operations (h5gg API)
    
    /// Busca um número na memória
    /// - Parameters:
    ///   - value: Valor a buscar (pode ser exato ou range "min~max")
    ///   - type: Tipo de dado (I32, I64, F32)
    ///   - startAddress: Endereço inicial (hex string)
    ///   - endAddress: Endereço final (hex string)
    func searchNumber(_ value: String, _ type: String, _ startAddress: String, _ endAddress: String) -> Int {
        guard let memType = MemoryType(rawValue: type) else {
            print("❌ Invalid memory type: \(type)")
            return 0
        }
        
        let start = parseAddress(startAddress)
        let end = parseAddress(endAddress)
        
        return memoryScanner.searchNumber(value, type: memType, startAddress: start, endAddress: end)
    }
    
    /// Busca valores próximos (nearby)
    func searchNearby(_ value: String, _ type: String, _ offset: String) -> Int {
        guard let memType = MemoryType(rawValue: type) else {
            print("❌ Invalid memory type: \(type)")
            return 0
        }
        
        return memoryScanner.searchNearby(value, type: memType, offset: offset)
    }
    
    /// Limpa os resultados da busca
    func clearResults() {
        memoryScanner.clearResults()
    }
    
    /// Obtém a contagem de resultados
    func getResultsCount() -> Int {
        return memoryScanner.getResultsCount()
    }
    
    /// Obtém os resultados da busca
    func getResults(_ count: Int) -> [[String: Any]] {
        let results = memoryScanner.getResults(count)
        return results.map { result in
            return [
                "address": result.addressString,
                "value": "\(result.value)",
                "type": result.type.rawValue
            ]
        }
    }
    
    // MARK: - Edit Operations (h5gg API)
    
    /// Edita todos os resultados encontrados
    func editAll(_ value: String, _ type: String) -> Int {
        guard let memType = MemoryType(rawValue: type) else {
            print("❌ Invalid memory type: \(type)")
            return 0
        }
        
        guard let newValue = MemoryValueConverter.stringToValue(value, type: memType) else {
            print("❌ Invalid value format")
            return 0
        }
        
        let results = memoryScanner.getResults(memoryScanner.getResultsCount())
        var editedCount = 0
        
        for result in results {
            if setValue(result.addressString, value, type) {
                editedCount += 1
            }
        }
        
        print("✏️ Edited \(editedCount) values")
        return editedCount
    }
    
    /// Define um valor em um endereço específico
    func setValue(_ address: String, _ value: String, _ type: String) -> Bool {
        guard processManager.isProcessAttached() else {
            print("❌ No process attached")
            return false
        }
        
        guard let memType = MemoryType(rawValue: type) else {
            print("❌ Invalid memory type: \(type)")
            return false
        }
        
        guard let newValue = MemoryValueConverter.stringToValue(value, type: memType) else {
            print("❌ Invalid value format")
            return false
        }
        
        guard let data = MemoryValueConverter.valueToData(newValue, type: memType) else {
            print("❌ Failed to convert value to data")
            return false
        }
        
        let addr = parseAddress(address)
        return writeMemory(address: addr, data: data)
    }
    
    // MARK: - Memory Operations
    
    private func writeMemory(address: UInt64, data: Data) -> Bool {
        let task = processManager.getCurrentTask()
        
        var kr: kern_return_t
        
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            kr = mach_vm_write(
                task,
                address,
                vm_offset_t(UInt(bitPattern: bytes.baseAddress)),
                mach_msg_type_number_t(data.count)
            )
        }
        
        if kr == KERN_SUCCESS {
            print("✅ Wrote \(data.count) bytes to \(String(format: "0x%llX", address))")
            return true
        } else {
            print("❌ Failed to write memory: \(machErrorString(kr))")
            return false
        }
    }
    
    func readMemory(address: UInt64, size: Int) -> Data? {
        guard processManager.isProcessAttached() else { return nil }
        
        let task = processManager.getCurrentTask()
        var data: vm_offset_t = 0
        var dataSize: mach_msg_type_number_t = 0
        
        let kr = mach_vm_read(task, address, mach_vm_size_t(size), &data, &dataSize)
        
        if kr == KERN_SUCCESS {
            let buffer = UnsafeRawPointer(bitPattern: UInt(data))
            let result = Data(bytes: buffer!, count: Int(dataSize))
            vm_deallocate(mach_task_self_, data, vm_size_t(dataSize))
            return result
        }
        
        return nil
    }
    
    // MARK: - Utilities
    
    private func parseAddress(_ address: String) -> UInt64 {
        let cleaned = address.replacingOccurrences(of: "0x", with: "")
        return UInt64(cleaned, radix: 16) ?? 0
    }
    
    private func machErrorString(_ kr: kern_return_t) -> String {
        if let cString = mach_error_string(kr) {
            return String(cString: cString)
        }
        return "Unknown error (\(kr))"
    }
    
    // MARK: - Info
    
    func getProcessInfo() -> String {
        return processManager.getProcessInfo() ?? "No process attached"
    }
}
