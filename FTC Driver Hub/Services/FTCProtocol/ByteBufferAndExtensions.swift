//
//  ByteBufferAndExtensions.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 17. 10. 25.
//

import Foundation

extension Data {
    // MARK: - Safe Unaligned Load Helper
    private func loadUnaligned<T: FixedWidthInteger>(as type: T.Type) -> T {
        precondition(count >= MemoryLayout<T>.size)
        return withUnsafeBytes { $0.loadUnaligned(as: T.self) }
    }

    // MARK: - Generic Reads

    mutating func readInt8() -> Int8? {
        guard count >= 1 else { return nil }
        return Int8(bitPattern: removeFirst())
    }

    mutating func readUInt8() -> UInt8? {
        guard count >= 1 else { return nil }
        return removeFirst()
    }

    mutating func readInt16() -> Int16? {
        guard count >= 2 else { return nil }
        let value = prefix(2).withUnsafeBytes { ptr -> Int16 in
            let raw = ptr.loadUnaligned(as: UInt16.self)
            return Int16(bitPattern: raw.bigEndian)
        }
        removeFirst(2)
        return value
    }

    mutating func readUInt16() -> UInt16? {
        guard count >= 2 else { return nil }
        let value = prefix(2).withUnsafeBytes { ptr -> UInt16 in
            ptr.loadUnaligned(as: UInt16.self).bigEndian
        }
        removeFirst(2)
        return value
    }

    mutating func readInt32() -> Int32? {
        guard count >= 4 else { return nil }
        let value = prefix(4).withUnsafeBytes { ptr -> Int32 in
            let raw = ptr.loadUnaligned(as: UInt32.self)
            return Int32(bitPattern: raw.bigEndian)
        }
        removeFirst(4)
        return value
    }

    mutating func readUInt32() -> UInt32? {
        guard count >= 4 else { return nil }
        let value = prefix(4).withUnsafeBytes { ptr -> UInt32 in
            ptr.loadUnaligned(as: UInt32.self).bigEndian
        }
        removeFirst(4)
        return value
    }

    mutating func readInt64() -> Int64? {
        guard count >= 8 else { return nil }
        let value = prefix(8).withUnsafeBytes { ptr -> Int64 in
            let raw = ptr.loadUnaligned(as: UInt64.self)
            return Int64(bitPattern: raw.bigEndian)
        }
        removeFirst(8)
        return value
    }

    mutating func readUInt64() -> UInt64? {
        guard count >= 8 else { return nil }
        let value = prefix(8).withUnsafeBytes { ptr -> UInt64 in
            ptr.loadUnaligned(as: UInt64.self).bigEndian
        }
        removeFirst(8)
        return value
    }

    mutating func readFloat32() -> Float? {
        guard count >= 4 else { return nil }
        let bits = prefix(4).withUnsafeBytes { ptr -> UInt32 in
            ptr.loadUnaligned(as: UInt32.self).bigEndian
        }
        removeFirst(4)
        return Float(bitPattern: bits)
    }

    mutating func readString(length: Int) -> String? {
        guard count >= length else { return nil }
        let sub = prefix(length)
        removeFirst(length)
        return String(data: sub, encoding: .utf8)
    }

    // MARK: - Appends (Big Endian)
    mutating func appendBE<T: FixedWidthInteger>(_ value: T) {
        var big = value.bigEndian
        Swift.withUnsafeBytes(of: &big) { buffer in
            append(contentsOf: buffer)
        }
    }

    mutating func appendString(_ str: String) {
        if let data = str.data(using: .utf8) {
            append(data)
        }
    }
}
