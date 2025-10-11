//
//  FloatEntry.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct FloatEntry: Equatable {
    var key: String
    var value: Float

    static func read(from cursor: inout Int, data: Data) -> FloatEntry? {
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            defer { cursor += size }
            return data[cursor..<cursor + size].withUnsafeBytes { $0.load(as: T.self) }
        }

        func readString(length: Int) -> String {
            let range = cursor..<cursor + length
            let strData = data.subdata(in: range)
            cursor += length
            return String(data: strData, encoding: .utf8) ?? ""
        }

        let keyLen = Int(UInt16(littleEndian: read(UInt16.self)))
        let key = readString(length: keyLen)
        let valBits = UInt32(littleEndian: read(UInt32.self))
        let value = Float(bitPattern: valBits)
        return FloatEntry(key: key, value: value)
    }
}
