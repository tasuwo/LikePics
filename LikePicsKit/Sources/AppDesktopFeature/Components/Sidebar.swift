//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import MasonryGrid
import Persistence
import SwiftUI

struct Sidebar: View {
    @Binding var selectedItem: SidebarItem?

    @State private var isAlbumHovered = false
    @State private var isAlbumExpanded = false

    @FetchRequest(sortDescriptors: [.init(keyPath: \Persistence.Tag.name, ascending: true)]) private var tags: FetchedResults<Persistence.Tag>
    @FetchRequest(sortDescriptors: [.init(keyPath: \Persistence.Album.index, ascending: true)]) private var albums: FetchedResults<Persistence.Album>

    @Namespace private var animation

    init(selectedItem: Binding<SidebarItem?>) {
        self._selectedItem = selectedItem
    }

    var body: some View {
        List(selection: $selectedItem) {
            Section("ライブラリ") {
                HStack {
                    Label {
                        Text("全て")
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
                .tag(SidebarItem.all)

                DisclosureGroup(isExpanded: $isAlbumExpanded) {
                    ForEach(albums.compactMap({ $0.map(to: Domain.ListingAlbumTitle.self) })) { album in
                        Label {
                            Text(album.title)
                        } icon: {
                            Image(systemName: "square.stack")
                        }
                        .contextMenu {
                            Button {
                                // TODO:
                            } label: {
                                Text("タイトルの変更")
                            }
                            Button {
                                // TODO:
                            } label: {
                                Text("隠す")
                            }
                            Button {
                                // TODO:
                            } label: {
                                Text("削除")
                            }
                        }
                        .tag(SidebarItem.album(album.id))
                    }
                } label: {
                    HStack {
                        Label {
                            Text("アルバム")
                        } icon: {
                            Image(systemName: "square.stack")
                        }

                        Spacer()

                        Button {
                            // TODO:
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderless)
                        .opacity(isAlbumHovered ? 1 : 0)
                    }
                    .contextMenu {
                        Button {
                            // TODO:
                        } label: {
                            Text("新規アルバム")
                        }
                    }
                    .tag(SidebarItem.albums)
                }
                .listRowBackground(
                    Color.clear
                        .onHover(perform: { hovering in
                            isAlbumHovered = hovering
                        })
                )
            }

            Section("タグ") {
                HMasonryGrid(tags.compactMap({ $0.map(to: Domain.Tag.self) })) { tag in
                    TagButton(tag: tag, isSelected: selectedItem?.tagId() == tag.id)
                        .onTapGesture {
                            if selectedItem?.tagId() == tag.id {
                                selectedItem = nil
                            } else {
                                selectedItem = .tag(tag.id)
                            }
                        }
                        .matchedGeometryEffect(id: tag.id, in: animation)
                } width: { tag in
                    TagButton.preferredWidth(for: tag.name)
                }
            }
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

        (0 ... 20).forEach { _ in
            let tag = Persistence.Tag(context: container.viewContext)
            tag.id = UUID()
            tag.name = randomTagName()
        }

        (0 ... 6).forEach { index in
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

    struct PreviewView: View {
        @State var selectedItem: SidebarItem? = .all

        var body: some View {
            NavigationSplitView {
                Sidebar(selectedItem: $selectedItem)
            } detail: {
                Color.clear
            }
        }
    }

    func randomTagName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 3 ... 15)).map { _ in letters.randomElement()! })
    }

    func randomAlbumName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 8 ... 15)).map { _ in letters.randomElement()! })
    }

    return PreviewView()
        .environment(\.managedObjectContext, persistentContainer.viewContext)
}
