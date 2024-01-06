//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Common
import MasonryGrid
import Persistence
import SwiftUI

public struct ClipCreateView: View {
    private let images: [ImageSource]
    private let onSave: () -> Void
    private let onCancel: () -> Void

    @State private var url: String
    @State private var tags: Set<TagPreview>
    @State private var albums: Set<AlbumPreview>
    @State private var combineIntoClip: Bool = false
    @State private var isHidden: Bool = false
    @State private var selectedImageIds: [UUID] = []

    @State private var creatingTagName: String?
    @State private var creatingAlbumName: String?
    @State private var isTagDuplicateAlertPresenting = false
    @State private var isTagCreateErrorAlertPresenting = false
    @State private var isAlbumCreateErrorAlertPresenting = false
    @State private var isClipCreateErrorAlertPresenting = false

    @Namespace var namespace

    @Environment(\.managedObjectContext) var context
    @AppStorage(\.showHiddenItems, store: .appGroup) var showHiddenItems

    public init(images: [ImageSource],
                url: String? = nil,
                tags: Set<TagPreview> = .init(),
                albums: Set<AlbumPreview> = .init(),
                onSave: @escaping () -> Void,
                onCancel: @escaping () -> Void)
    {
        self.images = images
        self.url = url ?? ""
        self.tags = tags
        self.albums = albums
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SuggestTextField<TagPreview>(placeholder: NSLocalizedString("Add Tags...", bundle: .module, comment: "Form on ClipCreateView")) { text in
                        fetchTags(beginWith: text)
                    } fallbackItemTitle: { text in
                        String(localized: "Create new tag \"\(text)\"", bundle: .module, comment: "Fallback on suggest list.")
                    } onSelect: { selection in
                        do {
                            switch selection {
                            case let .fallback(name):
                                creatingTagName = name
                                let newTag = try createTag(with: name)
                                creatingTagName = nil
                                withAnimation {
                                    _ = tags.insert(newTag)
                                }

                            case let .item(tag):
                                withAnimation {
                                    _ = tags.insert(tag)
                                }
                            }
                        } catch TagError.duplicate {
                            isTagDuplicateAlertPresenting = true
                        } catch {
                            isTagCreateErrorAlertPresenting = true
                        }
                    }
                    .padding(.horizontal)

                    if !tags.isEmpty {
                        HMasonryGrid(tags.sorted(by: { $0.title > $1.title })) { tag in
                            PreviewItemView(name: tag.title)
                                .matchedGeometryEffect(id: tag.id, in: namespace)
                                .contextMenu {
                                    Button {
                                        withAnimation {
                                            _ = tags.remove(tag)
                                        }
                                    } label: {
                                        Text("Remove tag", bundle: .module, comment: "Context menu")
                                    }
                                }
                        } width: { tag in
                            PreviewItemView.preferredWidth(for: tag.title)
                        }
                        .padding(.horizontal)
                    }

                    Divider()

                    SuggestTextField<AlbumPreview>(placeholder: String(localized: "Add Albums...", bundle: .module, comment: "Form on CilpCreateView")) { text in
                        fetchAlbums(beginWith: text)
                    } fallbackItemTitle: { text in
                        String(localized: "Create new album \"\(text)\"", bundle: .module, comment: "Fallback on suggest list.")
                    } onSelect: { selection in
                        do {
                            switch selection {
                            case let .fallback(name):
                                creatingAlbumName = name
                                let newAlbum = try createAlbum(with: name)
                                creatingAlbumName = nil
                                withAnimation {
                                    _ = albums.insert(newAlbum)
                                }

                            case let .item(album):
                                withAnimation {
                                    _ = albums.insert(album)
                                }
                            }
                        } catch {
                            isAlbumCreateErrorAlertPresenting = true
                        }
                    }
                    .padding(.horizontal)

                    if !albums.isEmpty {
                        HMasonryGrid(albums.sorted(by: { $0.title > $1.title })) { album in
                            PreviewItemView(name: album.title)
                                .matchedGeometryEffect(id: album.id, in: namespace)
                                .contextMenu {
                                    Button {
                                        withAnimation {
                                            _ = albums.remove(album)
                                        }
                                    } label: {
                                        Text("Remove album", bundle: .module, comment: "Context menu")
                                    }
                                }
                        } width: { album in
                            PreviewItemView.preferredWidth(for: album.title)
                        }
                        .padding(.horizontal)
                    }

                    Divider()

                    TextField(String(localized: "URL", bundle: .module, comment: "Form on ClipCreateView"), text: $url)
                        .textFieldStyle(.plain)
                        .padding(.horizontal)

                    Divider()

                    Form {
                        Toggle(String(localized: "Combine into Clip", bundle: .module, comment: "Toggle on CilpCreateView"), isOn: $combineIntoClip)
                            .gridCellColumns(2)
                        Text("Combie multiple images into a single clip.", bundle: .module, comment: "Toggle description on ClipCreateView")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                            .gridCellColumns(2)
                        Toggle(String(localized: "Save as hidden items", bundle: .module, comment: "Toggle on CilpCreateView"), isOn: $isHidden)
                            .gridCellColumns(2)
                    }
                    .padding(.horizontal)

                    Divider()

                    ImageEntryListView(images: images, displayOrder: combineIntoClip, selectedIds: $selectedImageIds)
                        .padding(.top)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .alert(
                    Text("Failed to Create Tag", bundle: .module, comment: "Alert title"),
                    isPresented: $isTagDuplicateAlertPresenting,
                    presenting: creatingTagName
                ) { _ in
                    Button {
                        creatingTagName = nil
                        isTagDuplicateAlertPresenting = false
                    } label: {
                        Text("OK", bundle: .module, comment: "Button on alert")
                    }
                    .keyboardShortcut(.defaultAction)
                } message: { name in
                    Text("Tag \"\(name)\" could not be created because an error occurred. A duplicate name was specified.", bundle: .module, comment: "Alert description")
                }
                .alert(
                    Text("Failed to Create Tag", bundle: .module, comment: "Alert title"),
                    isPresented: $isTagCreateErrorAlertPresenting,
                    presenting: creatingTagName
                ) { _ in
                    Button {
                        creatingTagName = nil
                        isTagCreateErrorAlertPresenting = false
                    } label: {
                        Text("OK", bundle: .module, comment: "Button on alert")
                    }
                    .keyboardShortcut(.defaultAction)
                } message: { name in
                    Text("Tag \"\(name)\" could not be created because an error occurred.", bundle: .module, comment: "Alert description")
                }
                .alert(
                    Text("Failed to Create Album", bundle: .module, comment: "Alert title"),
                    isPresented: $isAlbumCreateErrorAlertPresenting,
                    presenting: creatingAlbumName
                ) { _ in
                    Button {
                        creatingAlbumName = nil
                        isAlbumCreateErrorAlertPresenting = false
                    } label: {
                        Text("OK", bundle: .module, comment: "Button on alert")
                    }
                    .keyboardShortcut(.defaultAction)
                } message: { name in
                    Text("Album \"\(name)\" could not be created because an error occurred.", bundle: .module, comment: "Alert description")
                }
                .alert(Text("Failed to Create Clip", bundle: .module, comment: "Alert title"),
                       isPresented: $isClipCreateErrorAlertPresenting)
                {
                    Button {
                        creatingAlbumName = nil
                        isClipCreateErrorAlertPresenting = false
                    } label: {
                        Text("OK", bundle: .module, comment: "Button on alert")
                    }
                    .keyboardShortcut(.defaultAction)
                } message: {
                    Text("Clip could not be created because an error occurred.", bundle: .module, comment: "Alert description")
                }
            }

            Divider()

            HStack {
                Spacer()

                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Text("Cancel", bundle: .module, comment: "Button on footer")
                        .frame(minWidth: 60)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    Task { @MainActor in
                        do {
                            try await createClip()
                            onSave()
                        } catch {
                            isClipCreateErrorAlertPresenting = true
                        }
                    }
                } label: {
                    Text("Save", bundle: .module, comment: "Button on footer")
                        .frame(minWidth: 60)
                }
            }
            .padding(.vertical)
            .padding(.trailing, 24)
        }
    }

    @MainActor
    private func fetchTags(beginWith text: String) -> [TagPreview] {
        guard let tags = try? Tag.fetch(beginsWith: text, showHiddenItems: showHiddenItems, context: context) else {
            return []
        }

        var results: [TagPreview] = []
        for tag in tags {
            guard let id = tag.id, let title = tag.name else { continue }
            if title == text {
                results.insert(TagPreview(id: id, title: title), at: 0)
            } else {
                results.append(TagPreview(id: id, title: title))
            }
        }

        return results
    }

    @MainActor
    private func createTag(with name: String) throws -> TagPreview {
        let newId = try Tag.create(withName: name, in: context)
        return .init(id: newId, title: name)
    }

    @MainActor
    private func fetchAlbums(beginWith text: String) -> [AlbumPreview] {
        guard let albums = try? Album.fetch(beginsWith: text, showHiddenItems: showHiddenItems, context: context) else {
            return []
        }

        var results: [AlbumPreview] = []
        for album in albums {
            guard let id = album.id, let title = album.title else { continue }
            if title == text {
                results.insert(AlbumPreview(id: id, title: title), at: 0)
            } else {
                results.append(AlbumPreview(id: id, title: title))
            }
        }

        return results
    }

    @MainActor
    private func createAlbum(with title: String) throws -> AlbumPreview {
        let newId = try Album.create(withTitle: title, in: context)
        return .init(id: newId, title: title)
    }

    @MainActor
    private func createClip() async throws {
        struct ClipItemEntry {
            let index: Int
            let width: CGFloat
            let height: CGFloat
            let fileName: String
            let data: Data
        }

        enum Error: Swift.Error { case failedToSizeCalculation }

        let orderedImageAndIndex = selectedImageIds
            .compactMap({ id in images.first(where: { $0.id == id }) })
            .enumerated()

        let timestamp = Date().timeIntervalSince1970
        let clipItemEntries = try await withThrowingTaskGroup(of: ClipItemEntry.self) { group in
            for imageAndIndex in orderedImageAndIndex {
                group.addTask {
                    let result = try await ImageLoader().image(from: imageAndIndex.element)

                    guard let size = ImageUtility.resolveSize(for: result.data) else {
                        throw Error.failedToSizeCalculation
                    }

                    // 空文字だと画像の保存に失敗するので、適当なファイル名を付与する
                    let fileName = result.fileName ?? "IMG_\(timestamp)_\(imageAndIndex.offset)"

                    return ClipItemEntry(index: imageAndIndex.offset,
                                         width: size.width,
                                         height: size.height,
                                         fileName: fileName,
                                         data: result.data)
                }
            }

            var results: [ClipItemEntry] = []
            for try await result in group {
                results.append(result)
            }

            return results
        }

        do {
            var appendingTags: [Tag] = []
            for tag in tags {
                let request = Tag.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                guard let tag = try context.fetch(request).first else { continue }
                appendingTags.append(tag)
            }

            let clipId = UUID()
            let currentDate = Date()
            let clip = Clip(context: context)
            clip.id = clipId

            let items = NSMutableSet()
            for entry in clipItemEntries {
                let imageId = UUID()

                let item = Item(context: context)
                item.id = UUID()
                item.siteUrl = URL(string: url)
                item.clipId = clipId
                item.index = Int64(entry.index)
                item.imageId = imageId
                item.imageFileName = entry.fileName
                item.imageHeight = entry.height
                item.imageWidth = entry.width
                item.imageSize = Int64(entry.data.count)
                item.createdDate = currentDate
                item.updatedDate = currentDate
                items.add(item)

                let image = Image(context: context)
                image.id = imageId
                image.data = entry.data
            }

            clip.clipItems = items
            clip.tags = NSSet(array: appendingTags)

            clip.imagesSize = Int64(clipItemEntries.map(\.data.count).reduce(0, +))
            clip.isHidden = isHidden
            clip.createdDate = currentDate
            clip.updatedDate = currentDate

            for album in albums {
                let request = Album.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", album.id as CVarArg)
                guard let album = try context.fetch(request).first else { continue }

                let albumItems = album.mutableSetValue(forKey: "items")

                let maxIndex = albumItems
                    .compactMap { $0 as? AlbumItem }
                    .max(by: { $0.index < $1.index })?
                    .index ?? 0

                let albumItem = AlbumItem(context: context)
                albumItem.id = UUID()
                albumItem.index = maxIndex + 1
                albumItem.clip = clip
                albumItems.add(albumItem)

                album.updatedDate = Date()
            }

            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

#Preview {
    let persistentContainer: NSPersistentContainer = {
        let model = NSManagedObjectModel(contentsOf: ManagedObjectModelUrl)!
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [persistentStoreDescription]

        container.loadPersistentStores { _, _ in }

        (0 ... 1000).forEach { index in
            let tag = Persistence.Tag(context: container.viewContext)
            tag.id = UUID()
            tag.name = randomTagName()
            tag.isHidden = index % 2 == 0
        }

        (0 ... 1000).forEach { index in
            let album = Persistence.Album(context: container.viewContext)
            album.id = UUID()
            album.title = randomAlbumName()
            album.index = Int64(index)
            album.updatedDate = Date()
            album.createdDate = Date()
        }

        try! container.viewContext.save()

        return container
    }()

    UserDefaults.appGroup = .standard

    func randomTagName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 3 ... 15)).map { _ in letters.randomElement()! })
    }

    func randomAlbumName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 8 ... 15)).map { _ in letters.randomElement()! })
    }

    return ClipCreateView(
        images: [
            .init(fileURL: URL(string: "https://localhost")!),
            .init(fileURL: URL(string: "https://localhost")!),
            .init(fileURL: URL(string: "https://localhost")!),
            .init(fileURL: URL(string: "https://localhost")!),
            .init(fileURL: URL(string: "https://localhost")!),
            .init(fileURL: URL(string: "https://localhost")!),
        ],
        url: nil,
        tags: .init(),
        albums: .init()
    ) {
        print("Done!")
    } onCancel: {
        print("Cancelled")
    }
    .environment(\.managedObjectContext, persistentContainer.viewContext)
}
