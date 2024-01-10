//
//  FileProperty.swift
//  AppCommon
//
//  Created by zxq on 2023/9/26.
//

import Foundation
import WCDBSwift

public final class FileAttribute {
    public enum AttributeType: Int32 {
        static let `default`: AttributeType = .bool
        case bool = 0
        case `enum`
        case txt
        case number
        case date
        case reference
    }
    public init() {}
    public var id: UUID = .default
    public var name: String = .default
    public var type: AttributeType = .default
    public var allowMulti: Bool = .default
    public var option: String?
}

public final class FileAttributeValue {
    public init() {}
    public var attributeId: UUID?
    public var fileId: UUID?
    public var stringValue: String?
    public var numberValue: Int32?
    public var referenceValue: UUID?
}

public final class FileRefAttributeValue: NodeP {

    public var type: NodeType = .default

    public var id: UUID = .default

    public var name: String = ""

    public var parent: UUID?

    public var path: String = ""

    public init() {}

    public var attributeId: UUID?

    public var data: String?
}

extension FileAttribute.AttributeType: ColumnCodable {
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: value.int32Value)
    }

    public func archivedValue() -> WCDBSwift.Value {
        .init(self.rawValue)
    }

    public static var columnType: WCDBSwift.ColumnType {
        .integer32
    }
}

extension FileAttribute: UUIDNamedTableCodable {
    public static var TableName = "file_attributes"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = FileAttribute

        case id

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
    }
}
