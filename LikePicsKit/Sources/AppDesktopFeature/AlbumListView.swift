//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import SwiftUI

class AlbumsStore: ObservableObject {
    @Published var albums: [Album]

    init(albums: [Album]) {
        self.albums = albums
    }
}

extension AlbumsStore: ReorderableItemStore {
    var reorderableItems: [Album] { albums }
    var reorderableItemsPublisher: AnyPublisher<[Album], Never> { $albums.eraseToAnyPublisher() }

    func apply(reorderedItems: [Album]) {
        self.albums = reorderedItems
    }
}

struct AlbumListView: View {
    @StateObject var controller: DragAndDropInteractionController<AlbumsStore>
    @State var layout: MultiColumnLayout = .default

    var body: some View {
        ScrollView {
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: layout.columns, spacing: MultiColumnLayout.spacing) {
                    ForEach(controller.displayItems) { album in
                        AlbumView(album: album)
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
                                Button(role: .destructive) {
                                    // TODO:
                                } label: {
                                    Text("削除")
                                }
                            }
                            .onDrag {
                                controller.onDragStart(forItemHaving: album.id)
                                let provider = NSItemProvider()
                                provider.registerDataRepresentation(for: .text, visibility: .ownProcess) { completion in
                                    completion(Data(), nil)
                                    return nil
                                }
                                return provider
                            }
                            .onDrop(of: [.text], delegate: AlbumListDropDelegate(id: album.id, store: controller))
                    }
                }
                .frame(minWidth: MultiColumnLayout.column4.minRowWidth, maxWidth: layout.maxRowWidth)
                .padding(.all, 41)
            }
        }
        .onChangeFrame { size in
            layout = MultiColumnLayout.layout(forWidth: size.width - 41 * 2)
        }
    }
}

struct AlbumListDropDelegate: DropDelegate {
    let id: Album.ID
    let store: DragAndDropInteractionController<AlbumsStore>

    func performDrop(info: DropInfo) -> Bool {
        return store.onPerformDrop(forItemHaving: id)
    }

    func dropEntered(info: DropInfo) {
        store.onDragEnter(toItemHaving: id)
    }

    func dropExited(info: DropInfo) {
        store.onDragExit(fromItemHaving: id)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return .init(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        return store.isValidDrop(forItemHaving: id)
    }
}

#Preview {
    let albums: [Album] = Array((0 ... 6).map { _ in Album(id: UUID(), title: randomAlbumName(), clips: [], isHidden: false, registeredDate: Date(), updatedDate: Date()) })

    func randomAlbumName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 8 ... 15)).map { _ in letters.randomElement()! })
    }

    return AlbumListView(controller: DragAndDropInteractionController(underlying: AlbumsStore(albums: albums)))
}
