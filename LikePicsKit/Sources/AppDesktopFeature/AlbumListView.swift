//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

class AlbumsStore: ObservableObject {
    @Published var draggingAlbumId: Album.ID?
    @Published var albums: [Album]

    init(albums: [Album]) {
        self.albums = albums
    }
}

struct AlbumListView: View {
    @StateObject var albumsStore: AlbumsStore
    @State var layout: MultiColumnLayout = .default

    var body: some View {
        ScrollView {
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: layout.columns, spacing: MultiColumnLayout.spacing) {
                    ForEach(albumsStore.albums) { album in
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
                                albumsStore.draggingAlbumId = album.id
                                let provider = NSItemProvider()
                                provider.registerDataRepresentation(for: .text, visibility: .ownProcess) { completion in
                                    completion(Data(), nil)
                                    return nil
                                }
                                return provider
                            }
                            .onDrop(of: [.text], delegate: AlbumListDropDelegate(at: album.id, store: albumsStore))
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
    let store: AlbumsStore

    init(at id: Album.ID, store: AlbumsStore) {
        self.id = id
        self.store = store
    }

    func performDrop(info: DropInfo) -> Bool {
        let fromIndex = store.albums.firstIndex(where: { $0.id == store.draggingAlbumId }) ?? 0
        let toIndex = store.albums.firstIndex(where: { $0.id == id }) ?? 0
        guard fromIndex != toIndex else { return true }
        withAnimation {
            store.draggingAlbumId = nil
            let removed = store.albums.remove(at: fromIndex)
            store.albums.insert(removed, at: toIndex)
        }
        return true
    }

    func dropEntered(info: DropInfo) {
        // NOP
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        return store.draggingAlbumId != nil
    }
}

#Preview {
    let albums: [Album] = Array((0 ... 6).map { _ in Album(id: UUID(), title: randomAlbumName(), clips: [], isHidden: false, registeredDate: Date(), updatedDate: Date()) })

    func randomAlbumName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 8 ... 15)).map { _ in letters.randomElement()! })
    }

    return AlbumListView(albumsStore: AlbumsStore(albums: albums))
}
