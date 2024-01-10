//
//  File.swift
//  AppCommon
//
//  Created by zxq on 2023/9/21.
//

import Foundation
import WCDBSwift

public final class File: NodeP {
    public static let `default` = File()
    public init() {}

    // branch node
    public var id: UUID = UUID.default
    public var name: String = .default
    public var parent: UUID?
    public var path: String = .default

    // node
    public var type: NodeType = .branch

    // file
    public var fileType: FileType = .default
    public var created: Date = .default
    public var modified: Date = .default
    public var accessed: Date = .default
}

public typealias FilesRepository = UUIDRepository<File>

extension File: UUIDNamedTableCodable {
    public static var TableName = "files"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = File
        case id
        case name
        case parent
        case path
        case type
        case fileType
        case created
        case modified
        case accessed

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            BindColumnConstraint(name, isNotNull: true, defaultTo: Self.Root.default.name)
            //            BindColumnConstraint(parentId)
            BindColumnConstraint(path, isNotNull: true, defaultTo: Self.Root.default.path)
            BindColumnConstraint(type, isNotNull: true, defaultTo: Self.Root.default.fileType)
            //            BindColumnConstraint(fileType)
            BindColumnConstraint(created, isNotNull: true, defaultTo: Self.Root.default.created)
            BindColumnConstraint(modified, isNotNull: true, defaultTo: Self.Root.default.modified)
            BindColumnConstraint(accessed, isNotNull: true, defaultTo: Self.Root.default.accessed)

            BindForeginKey(
                parent,
                foreignKey: ForeignKey().references(with: Self.Root.TableName).columns(
                    Self.Root.Properties.id
                ).onDelete(.setNull))
        }
    }
}
