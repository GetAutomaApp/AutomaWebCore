// AnyEncodable.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Foundation

struct AnyEncodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let v as Bool:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Int8:
            try container.encode(v)
        case let v as Int16:
            try container.encode(v)
        case let v as Int32:
            try container.encode(v)
        case let v as Int64:
            try container.encode(v)
        case let v as UInt:
            try container.encode(v)
        case let v as UInt8:
            try container.encode(v)
        case let v as UInt16:
            try container.encode(v)
        case let v as UInt32:
            try container.encode(v)
        case let v as UInt64:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as Float:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        case let v as [Any]:
            try container.encode(v.map { AnyEncodable($0) })
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyEncodable($0) })
        case Optional<Any>.none:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported type: \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
