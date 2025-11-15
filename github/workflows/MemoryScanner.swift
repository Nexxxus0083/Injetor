//
//  MemoryScanner.swift
//  MemoryInjector
//
//  Scanner de memória com algoritmos de busca eficientes
//

import Foundation

class MemoryScanner {
    static let shared = MemoryScanner()
    
    private var searchResults: [MemorySearchResult] = []
    private let processManager = ProcessManager.shared
    
    private init() {}
    
    // MARK: - Search Operations
    
    /// Busca um valor específico na memória
    func searchNumber(_ value: String, type: MemoryType, startAddress: UInt64, endAddress: UInt64) -> Int {
        guard processManager.isProcessAttached() else {
            print("❌ No process attached")
            return 0
        }
        
        // Limpa resultados anteriores
        searchResults.removeAll()
        
        // Verifica se é um range (ex: "0.1035~0.1070")
        if value.contains("~") {
            return searchRange(value, type: type, startAddress: startAddress, endAddress: endAddress)
        }
        
        // Converte o valor string para o tipo apropriado
        guard let searchValue = MemoryValueConverter.stringToValue(value, type: type) else {
            print("❌ Invalid value format")
            return 0
        }
        
        let task = processManager.getCurrentTask()
        var foundCount = 0
        
        // Enumera regiões de memória e busca o valor
        processManager.enumerateMemoryRegions { region in
            // Filtra apenas regiões legíveis dentro do range especificado
            guard region.isReadable,
                  region.address >= startAddress,
                  region.address < endAddress else {
                return true
            }
            
            // Lê a região de memória
            if let data = readMemory(task: task, address: region.address, size: Int(region.size)) {
                foundCount += scanDataForValue(data: data, baseAddress: region.address, value: searchValue, type: type)
            }
            
            return true
        }
        
        print("🔍 Found \(foundCount) results")
        return foundCount
    }
    
    /// Busca valores em um range
    private func searchRange(_ rangeString: String, type: MemoryType, startAddress: UInt64, endAddress: UInt64) -> Int {
        guard let range = ValueRange.parse(rangeString, type: type) else {
            print("❌ Invalid range format")
            return 0
        }
        
        let task = processManager.getCurrentTask()
        var foundCount = 0
        
        processManager.enumerateMemoryRegions { region in
            guard region.isReadable,
                  region.address >= startAddress,
                  region.address < endAddress else {
                return true
            }
            
            if let data = readMemory(task: task, address: region.address, size: Int(region.size)) {
                foundCount += scanDataForRange(data: data, baseAddress: region.address, range: range)
            }
            
            return true
        }
        
        print("🔍 Found \(foundCount) results in range")
        return foundCount
    }
    
    /// Busca valores próximos a um endereço (offset)
    func searchNearby(_ value: String, type: MemoryType, offset: String) -> Int {
        guard !searchResults.isEmpty else {
            print("❌ No previous search results")
            return 0
        }
        
        let offsetValue = Int64(offset.replacingOccurrences(of: "0x", with: ""), radix: 16) ?? 0
        var newResults: [MemorySearchResult] = []
        
        let task = processManager.getCurrentTask()
        
        for result in searchResults {
            let nearbyAddress = UInt64(Int64(result.address) + offsetValue)
            
            if let data = readMemory(task: task, address: nearbyAddress, size: type.size),
               let nearbyValue = MemoryValueConverter.dataToValue(data, type: type) {
                
                // Se é um range, verifica se está dentro
                if value.contains("~") {
                    if let range = ValueRange.parse(value, type: type),
                       isValueInRange(nearbyValue, range: range) {
                        newResults.append(MemorySearchResult(address: nearbyAddress, value: nearbyValue, type: type))
                    }
                } else {
                    // Busca exata
                    if let searchValue = MemoryValueConverter.stringToValue(value, type: type),
                       valuesAreEqual(nearbyValue, searchValue, type: type) {
                        newResults.append(MemorySearchResult(address: nearbyAddress, value: nearbyValue, type: type))
                    }
                }
            }
        }
        
        searchResults = newResults
        print("🔍 Found \(newResults.count) nearby results")
        return newResults.count
    }
    
    // MARK: - Results Management
    
    /// Obtém a contagem de resultados
    func getResultsCount() -> Int {
        return searchResults.count
    }
    
    /// Obtém os resultados da busca
    func getResults(_ count: Int) -> [MemorySearchResult] {
        let actualCount = min(count, searchResults.count)
        return Array(searchResults.prefix(actualCount))
    }
    
    /// Limpa os resultados
    func clearResults() {
        searchResults.removeAll()
    }
    
    // MARK: - Memory Reading
    
    private func readMemory(task: mach_port_t, address: UInt64, size: Int) -> Data? {
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
    
    // MARK: - Data Scanning
    
    private func scanDataForValue(data: Data, baseAddress: UInt64, value: Any, type: MemoryType) -> Int {
        var count = 0
        let stride = type.size
        
        for offset in stride(from: 0, to: data.count - stride + 1, by: stride) {
            let chunk = data.subdata(in: offset..<offset + stride)
            
            if let foundValue = MemoryValueConverter.dataToValue(chunk, type: type),
               valuesAreEqual(foundValue, value, type: type) {
                let address = baseAddress + UInt64(offset)
                searchResults.append(MemorySearchResult(address: address, value: foundValue, type: type))
                count += 1
            }
        }
        
        return count
    }
    
    private func scanDataForRange(data: Data, baseAddress: UInt64, range: ValueRange) -> Int {
        var count = 0
        let stride = range.type.size
        
        for offset in stride(from: 0, to: data.count - stride + 1, by: stride) {
            let chunk = data.subdata(in: offset..<offset + stride)
            
            if let foundValue = MemoryValueConverter.dataToValue(chunk, type: range.type),
               isValueInRange(foundValue, range: range) {
                let address = baseAddress + UInt64(offset)
                searchResults.append(MemorySearchResult(address: address, value: foundValue, type: range.type))
                count += 1
            }
        }
        
        return count
    }
    
    // MARK: - Value Comparison
    
    private func valuesAreEqual(_ a: Any, _ b: Any, type: MemoryType) -> Bool {
        switch type {
        case .i32:
            guard let val1 = a as? Int32, let val2 = b as? Int32 else { return false }
            return val1 == val2
        case .i64:
            guard let val1 = a as? Int64, let val2 = b as? Int64 else { return false }
            return val1 == val2
        case .f32:
            guard let val1 = a as? Float, let val2 = b as? Float else { return false }
            return abs(val1 - val2) < Float.ulpOfOne * 10
        case .f64:
            guard let val1 = a as? Double, let val2 = b as? Double else { return false }
            return abs(val1 - val2) < Double.ulpOfOne * 10
        }
    }
    
    private func isValueInRange(_ value: Any, range: ValueRange) -> Bool {
        switch range.type {
        case .i32:
            guard let val = value as? Int32,
                  let min = range.min as? Int32,
                  let max = range.max as? Int32 else { return false }
            return val >= min && val <= max
        case .i64:
            guard let val = value as? Int64,
                  let min = range.min as? Int64,
                  let max = range.max as? Int64 else { return false }
            return val >= min && val <= max
        case .f32:
            guard let val = value as? Float,
                  let min = range.min as? Float,
                  let max = range.max as? Float else { return false }
            return val >= min && val <= max
        case .f64:
            guard let val = value as? Double,
                  let min = range.min as? Double,
                  let max = range.max as? Double else { return false }
            return val >= min && val <= max
        }
    }
}
