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
    @State private var isPresentingUpdateAlbumFailureAlert = false
    @State private var isPresentingRemoveAlbumFailureAlert = false

    @FetchRequest private var tags: FetchedResults<Persistence.Tag>
    @FetchRequest private var albums: FetchedResults<Persistence.Album>

    @Namespace private var animation
    @Environment(\.managedObjectContext) private var context

    init(selectedItem: Binding<SidebarItem?>, showHiddenItems: Bool) {
        self._selectedItem = selectedItem
        _tags = .init(sortDescriptors: [.init(keyPath: \Persistence.Tag.name, ascending: true)],
                      predicate: showHiddenItems ? nil : NSPredicate(format: "isHidden == false"),
                      animation: .default)
        _albums = .init(sortDescriptors: [.init(keyPath: \Persistence.Album.index, ascending: true)],
                        predicate: showHiddenItems ? nil : NSPredicate(format: "isHidden == false"),
                        animation: .default)
    }

    var body: some View {
        List(selection: $selectedItem) {
            Section(String(localized: "Library", bundle: .module, comment: "Sidebar Section Title")) {
                HStack {
                    Label {
                        Text("All", bundle: .module, comment: "Sidebar Item")
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
                        .opacity(album.isHidden ? 0.5 : 1)
                        .tag(SidebarItem.album(album.id))
                        .contextMenu {
                            Button {
                                do {
                                    try context.updateAlbum(having: album.id, isHidden: !album.isHidden)
                                } catch {
                                    isPresentingUpdateAlbumFailureAlert = true
                                }
                            } label: {
                                if album.isHidden {
                                    Text("Show Album", bundle: .module, comment: "Context Menu")
                                } else {
                                    Text("Hide Album", bundle: .module, comment: "Context Menu")
                                }
                            }

                            Button {
                                do {
                                    try context.removeAlbum(having: album.id)
                                } catch {
                                    isPresentingRemoveAlbumFailureAlert = true
                                }
                            } label: {
                                Text("Remove Album", bundle: .module, comment: "Context Menu")
                            }
                        }
                    }
                } label: {
                    HStack {
                        Label {
                            Text("Albums", bundle: .module, comment: "Sidebar Item")
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
                            Text("New Album", bundle: .module, comment: "Context Menu")
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

            Section(String(localized: "Tags", bundle: .module, comment: "Sidebar Section Title")) {
                HMasonryGrid(tags.compactMap({ $0.map(to: Domain.Tag.self) })) { tag in
                    TagButton(tag: tag, isSelected: selectedItem?.tagId() == tag.id)
                        .onTapGesture {
                            if selectedItem?.tagId() == tag.id {
                                selectedItem = nil
                            } else {
                                selectedItem = .tag(tag.id)
                            }
                        }
                        .opacity(tag.isHidden ? 0.5 : 1)
                        .matchedGeometryEffect(id: tag.id, in: animation)
                } width: { tag in
                    TagButton.preferredWidth(for: tag.name)
                }
                .environment(\.frameTrackingMode, .debounce(0.15))
            }
        }
        .alert(Text("Failed to Update Album", bundle: .module, comment: "Alert title."), isPresented: $isPresentingUpdateAlbumFailureAlert) {
            Button {
                isPresentingUpdateAlbumFailureAlert = false
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("Album could not be updated because an error occurred.", bundle: .module, comment: "Alert message.")
        }
        .alert(Text("Failed to Remove Album", bundle: .module, comment: "Alert title."), isPresented: $isPresentingRemoveAlbumFailureAlert) {
            Button {
                isPresentingRemoveAlbumFailureAlert = false
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("Album could not be removed because an error occurred.", bundle: .module, comment: "Alert message.")
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

        (0 ... 20).forEach { index in
            let tag = Persistence.Tag(context: container.viewContext)
            tag.id = UUID()
            tag.name = randomTagName()
            tag.isHidden = index % 2 == 0
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
                Sidebar(selectedItem: $selectedItem, showHiddenItems: false)
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
