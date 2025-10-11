//
//  TelemetryEntry.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct TelemetryEntry: Equatable {
    var key: String
    var value: String

    static func read(from cursor: inout Int, data: Data) -> TelemetryEntry? {
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

        let valLen = Int(UInt16(littleEndian: read(UInt16.self)))
        let value = readString(length: valLen)

        return TelemetryEntry(key: key, value: value)
    }
}
