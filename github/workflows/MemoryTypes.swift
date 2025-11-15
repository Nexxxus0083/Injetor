//
//  MemoryTypes.swift
//  MemoryInjector
//
//  Definições de tipos de dados para manipulação de memória
//

import Foundation

/// Tipos de dados suportados para busca e edição de memória
enum MemoryType: String {
    case i32 = "I32"  // Integer 32-bit
    case i64 = "I64"  // Integer 64-bit
    case f32 = "F32"  // Float 32-bit
    case f64 = "F64"  // Float 64-bit (adicional)
    
    var size: Int {
        switch self {
        case .i32, .f32: return 4
        case .i64, .f64: return 8
        }
    }
}

/// Resultado de uma busca na memória
struct MemorySearchResult {
    let address: UInt64
    let value: Any
    let type: MemoryType
    
    var addressString: String {
        return String(format: "0x%llX", address)
    }
}

/// Range de valores para busca
struct ValueRange {
    let min: Any
    let max: Any
    let type: MemoryType
    
    static func parse(_ string: String, type: MemoryType) -> ValueRange? {
        let components = string.components(separatedBy: "~")
        guard components.count == 2 else { return nil }
        
        switch type {
        case .i32:
            guard let min = Int32(components[0]),
                  let max = Int32(components[1]) else { return nil }
            return ValueRange(min: min, max: max, type: type)
        case .i64:
            guard let min = Int64(components[0]),
                  let max = Int64(components[1]) else { return nil }
            return ValueRange(min: min, max: max, type: type)
        case .f32:
            guard let min = Float(components[0]),
                  let max = Float(components[1]) else { return nil }
            return ValueRange(min: min, max: max, type: type)
        case .f64:
            guard let min = Double(components[0]),
                  let max = Double(components[1]) else { return nil }
            return ValueRange(min: min, max: max, type: type)
        }
    }
}

/// Região de memória
struct MemoryRegion {
    let address: UInt64
    let size: UInt64
    let protection: vm_prot_t
    
    var isReadable: Bool {
        return (protection & VM_PROT_READ) != 0
    }
    
    var isWritable: Bool {
        return (protection & VM_PROT_WRITE) != 0
    }
    
    var isExecutable: Bool {
        return (protection & VM_PROT_EXECUTE) != 0
    }
}

/// Extensões para conversão de tipos
extension Data {
    func toValue<T>(type: T.Type) -> T? {
        guard self.count == MemoryLayout<T>.size else { return nil }
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}

extension Int32 {
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<Int32>.size)
    }
}

extension Int64 {
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<Int64>.size)
    }
}

extension Float {
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<Float>.size)
    }
}

extension Double {
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<Double>.size)
    }
}

/// Utilitários para conversão de valores
class MemoryValueConverter {
    static func stringToValue(_ string: String, type: MemoryType) -> Any? {
        switch type {
        case .i32:
            return Int32(string)
        case .i64:
            return Int64(string)
        case .f32:
            return Float(string)
        case .f64:
            return Double(string)
        }
    }
    
    static func valueToData(_ value: Any, type: MemoryType) -> Data? {
        switch type {
        case .i32:
            guard let val = value as? Int32 else { return nil }
            return val.data
        case .i64:
            guard let val = value as? Int64 else { return nil }
            return val.data
        case .f32:
            guard let val = value as? Float else { return nil }
            return val.data
        case .f64:
            guard let val = value as? Double else { return nil }
            return val.data
        }
    }
    
    static func dataToValue(_ data: Data, type: MemoryType) -> Any? {
        switch type {
        case .i32:
            return data.toValue(type: Int32.self)
        case .i64:
            return data.toValue(type: Int64.self)
        case .f32:
            return data.toValue(type: Float.self)
        case .f64:
            return data.toValue(type: Double.self)
        }
    }
}
