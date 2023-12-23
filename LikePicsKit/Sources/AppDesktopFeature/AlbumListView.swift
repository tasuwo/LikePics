//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct DropCandidate<ID: Equatable> {
    enum Direction: Equatable {
        case left
        case right
    }

    let targetId: ID
    let direction: Direction

    func offset(of id: ID, width: CGFloat) -> CGFloat {
        guard id == targetId else { return 0 }
        return switch direction {
        case .left: width / 2
        case .right: -1 * width / 2
        }
    }
}

struct DragContext<ID: Equatable> {
    var needsDisplayOverlayView: Bool { isDraggingOnView }
    var shouldHideBaseView: Bool { isDraggingOnView }
    var sourceId: ID? {
        guard isDraggingOnView else { return nil }
        return _sourceId
    }

    var isDraggingOnView: Bool = false
    private var _sourceId: ID?

    init(sourceId: ID) {
        _sourceId = sourceId
    }
}

class AlbumsStore: ObservableObject {
    @Published var albums: [Album]
    /// 破棄漏れが生じる可能性があるので注意
    @Published var dragContext: DragContext<Album.ID>?
    @Published var dropCandidate: DropCandidate<Album.ID>?

    init(albums: [Album]) {
        self.albums = albums
    }
}

struct AlbumListView: View {
    @StateObject var albumsStore: AlbumsStore

    @State var layout: MultiColumnLayout = .default
    @State var albumFrame: CGSize?

    var body: some View {
        ScrollView {
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: layout.columns, spacing: MultiColumnLayout.spacing) {
                    ForEach(Array(albumsStore.albums.enumerated()), id: \.element) { index, album in
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
                            .onChangeFrame { size in
                                albumFrame = size
                            }
                            .onDrag {
                                albumsStore.dragContext = .init(sourceId: album.id)
                                let provider = NSItemProvider()
                                provider.registerDataRepresentation(for: .text, visibility: .ownProcess) { completion in
                                    completion(Data(), nil)
                                    return nil
                                }
                                return provider
                            }
                            .onDrop(of: [.text], delegate: AlbumListDropDelegate(id: album.id, frame: albumFrame, store: albumsStore))
                            .opacity(albumsStore.dragContext?.shouldHideBaseView == true ? 0 : 1)
                            .overlay {
                                AlbumView(album: album)
                                    .opacity(albumsStore.dragContext?.needsDisplayOverlayView == true ? 1 : 0)
                                    .offset(x: albumsStore.dragContext?.sourceId == album.id ? 0 : (albumFrame.flatMap({ albumsStore.dropCandidate?.offset(of: album.id, width: $0.width) }) ?? 0))
                                    .allowsHitTesting(false)
                            }
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
    let frame: CGSize?
    let store: AlbumsStore

    func performDrop(info: DropInfo) -> Bool {
        defer {
            store.dragContext = nil
        }

        let direction = store.dropCandidate?.direction ?? .right
        guard let fromIndex = store.albums.firstIndex(where: { $0.id == store.dragContext?.sourceId }),
              let _toIndex = store.albums.firstIndex(where: { $0.id == id })
        else {
            return false
        }
        let toIndex = switch direction {
        case .left: fromIndex <= _toIndex ? max(0, _toIndex - 1) : _toIndex
        case .right: fromIndex <= _toIndex ? _toIndex : min(_toIndex + 1, store.albums.count - 1)
        }

        guard toIndex != fromIndex else { return false }

        withAnimation {
            let removed = store.albums.remove(at: fromIndex)
            store.albums.insert(removed, at: toIndex)
        }

        return true
    }

    func dropEntered(info: DropInfo) {
        // NOP
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        if let frame {
            store.dragContext?.isDraggingOnView = true
            withAnimation {
                store.dropCandidate = .init(targetId: id, direction: info.location.x < frame.width / 2 ? .left : .right)
            }
        }
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        withAnimation {
            store.dragContext?.isDraggingOnView = false
            store.dropCandidate = nil
        }
    }

    func validateDrop(info: DropInfo) -> Bool {
        return store.dragContext?.isDraggingOnView == true
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
