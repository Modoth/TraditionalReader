//
//  LibraryView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/19.
//

import AppCommon
import SwiftUI
import WCDBSwift

extension File: Identifiable {}

struct LibraryView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    @SceneStorage("currentFolderPath") var currentFolderPath: String = ""
    let imagePath = Bundle.main.path(forResource: "bgs/bg1.jpeg", ofType: nil)!

    @State var presentingCreateFolder = false
    @State var presentingImportFile = false
    @State var newFolderName = ""
    @State var currentFolder: File? = nil
    @State var items: [File] = []
    @State var selectedBook: File? = nil
    @State private var searchText: String = ""

    private let initPath: String
    private let onSelect: ((File) -> Void)?

    init(initPath: String = "", onSelect: ((File) -> Void)? = nil) {
        self.initPath = initPath
        self.onSelect = onSelect
    }

    func createFolder() {
        tryDo {
            let folderName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
            newFolderName = ""
            if folderName == "" {
                return
            }
            let filesService: any FilesService = locate()
            let folder = try filesService.createFolder(name: folderName, in: currentFolder?.id)
            items.insert(folder, at: 0)
        }
    }

    func deleteBook(_ book: File) {
        tryDo {
            let filesService: any FilesService = locate()
            try filesService.deleteFile(id: book.id)
            items.remove(at: items.firstIndex(of: book)!)
        }
    }

    func importFiles(_ urls: [URL]) {
        if urls.isEmpty {
            return
        }
        tryDo {
            for url in urls {
                if url.startAccessingSecurityScopedResource() {
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    let filesService: FilesService = locate()
                    let book = try filesService.import(url: url, in: currentFolder?.id)
                    items.insert(book, at: 0)
                } else {
                    throw BusinessError.default
                }
            }
        }
    }

    func openFolder(folder: File?) {
        tryDo {
            currentFolder = folder
            currentFolderPath = currentFolder?.path ?? ""
            let rep: any FilesRepository = locate()
            items = try rep.read$(by: .parent, value: currentFolder?.id)
            selectedBook = nil
        }
    }

    func openFolder(path: String) {
        if path == "" {
            openFolder(folder: nil)
            return
        }
        let rep: any FilesRepository = locate()
        openFolder(folder: try? rep.readOne(by: .path, value: path))
    }

    func openFolder(id: UUID?) {
        if id == nil {
            openFolder(folder: nil)
            return
        }
        let rep: any FilesRepository = locate()
        openFolder(folder: try? rep.readOne(by: .id, value: id!))
    }

    @ViewBuilder
    private func fileView(_ file: File) -> some View {
        if file.isFolder {
            FileIconV(file).contextMenu {
                Button("Delete", role: .destructive) {
                    notifyServices.toast(msg: BusinessErrorType.notImplemented.stringKey)
                }
            }.onTapGesture {
                openFolder(id: file.id)
            }
        } else {
            FileIconV(file, highlight: file == selectedBook).onTapGesture {
                if onSelect != nil {
                    onSelect!(file)
                    return
                }
                if selectedBook == file {
                    selectedBook = nil
                } else {
                    selectedBook = file
                }
            }.contextMenu {
                Button("Delete", role: .destructive) {
                    deleteBook(file)
                }
            }
        }
    }

    var body: some View {
        let _ = Self._printTrace()
        ZStack {
            NavigationStack {
                ScrollView {
                    LazyVGrid(
                        columns: (0..<4).map { _ in
                            GridItem(.adaptive(minimum: 80))
                        }
                    ) {
                        if currentFolder != nil {
                            FileIconV(File().with(\.name, "..").with(\.type, .branch))
                                .onTapGesture {
                                    openFolder(id: currentFolder?.parent)
                                }
                        }
                        ForEach(items) { item in
                            fileView(item)
                        }
                    }.padding([.bottom, .horizontal])
                        .task {
                            openFolder(path: currentFolderPath)
                        }
                }
                .searchable(text: $searchText)
                .onTapGesture {
                    selectedBook = nil
                }.navigationTitle(
                    currentFolder != nil
                        ? currentFolder!.name
                        : Bundle.main.localizedString(forKey: "Library", value: nil, table: nil)
                )
                .toolbar(content: {
                    Menu(
                        content: {
                            Button {
                                presentingCreateFolder = true
                            } label: {
                                Label("New Folder", image: "folder.badge.plus")
                            }
                            Button {
                                presentingImportFile = true
                            } label: {
                                Label("Import File", image: "doc.badge.plus")
                            }
                        },
                        label: {
                            Image(systemName: "plus")
                        })
                })
            }.alert("Create Folder", isPresented: $presentingCreateFolder) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancle") {
                    newFolderName = ""
                }
                Button("OK") {
                    createFolder()
                }
            }
            .fileImporter(
                isPresented: $presentingImportFile,
                allowedContentTypes: [.text, .pdf, .zip],
                allowsMultipleSelection: true
            ) {
                result in
                switch result {
                case .failure(_):
                    return
                case .success(let urls):
                    guard urls.count > 0 else {
                        return
                    }
                    importFiles(urls)
                }
            }
            .onAppear {
                if currentFolderPath == "" {
                    currentFolderPath = initPath
                }
            }
            if selectedBook != nil {
                VStack {
                    Spacer()
                    BookDetailView(selectedBook!).clipped().padding()
                        .background(.ultraThinMaterial)
                        .border(.black.opacity(0.1), width: 0.5, edges: [.bottom])
                    //                    .toolbar(.hidden, for: .tabBar)
                }
            }
        }
    }
}

#Preview {
    LibraryView(initPath: "/some/path/asdsad").usePreviewServices()
}
