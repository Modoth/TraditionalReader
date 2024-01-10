//
//  BooksService.swift
//  AppCommon
//
//  Created by zxq on 2023/9/23.
//

import Foundation

public protocol FilesService {
    func createFolder(name: String, in: UUID?) throws -> File
    func `import`(url: URL, in currentPath: UUID?) throws -> File
    func deleteFile(id: UUID) throws
    func deleteFolder(id: UUID) throws
}

extension FilesService {
    public func `import`(url: URL, in currentPath: UUID? = nil) throws -> File {
        try `import`(url: url, in: currentPath)
    }
}

public let FilesService$ = { FilesServiceImpl() as any FilesService }

private class FilesServiceImpl: FilesService, Service {
    func deleteFile(id: UUID) throws {
        let bookRep: any FilesRepository = locate()
        let file: File? = (try bookRep.read$(by: .id, value: id)).first
        if file?.type != .leaf {
            throw BusinessError(.failed)
        }
        let fileManager: FileResourceManager = locate()
        do {
            try fileManager.delete(id: id, resource: nil)
        } catch {
            print("\(error)")
        }
        try bookRep.delete(by: .id, value: id)
    }

    func deleteFolder(id: UUID) throws {
        let bookRep: any FilesRepository = locate()
        let folder: File? = try bookRep.readOne(by: .id, value: id)
        if folder?.type != .branch {
            throw BusinessError(.failed)
        }
        //        let files = bookRep.readOne
    }

    func `import`(url: URL, in currentPath: UUID?) throws -> File {
        let bookRep: any FilesRepository = locate()
        let folder: File? =
            currentPath == nil ? nil : (try bookRep.readOne(by: .id, value: currentPath))
        let bookId = try bookRep.createIds(count: 1)[0]
        let fileManager: FileResourceManager = locate()
        try fileManager.copy(fromUrl: url, toId: bookId, resource: "content")

        let name = url.deletingPathExtension().lastPathComponent
        let type = FileType(rawValue: url.pathExtension.lowercased()) ?? .default

        let book = File()
        book.id = bookId
        book.name = name
        book.type = .leaf
        book.fileType = type
        book.parent = folder?.id
        book.path = (book.path ?? "") + "/" + name

        do {
            try bookRep.create(book)
        } catch {
            try fileManager.delete(id: bookId, resource: nil)
            throw error
        }

        return book
    }

    func createFolder(name: String, in parendId: UUID?) throws -> File {
        let rep: any FilesRepository = locate()
        let parentFolder = parendId == nil ? nil : try rep.readOne(by: .id, value: parendId)
        let newPath = (parentFolder?.path ?? "") + "/" + name
        if let _ = try rep.readOne(by: .path, value: newPath) {
            throw BusinessError(.nameExisted)
        }
        let folder = File()
        folder.type = .branch
        folder.id = UUID()
        folder.name = name
        folder.path = newPath
        folder.parent = parendId
        try rep.create(folder)
        return folder
    }
}
