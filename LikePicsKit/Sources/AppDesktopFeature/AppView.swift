//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct AppView: View {
    @State private var selectedItem: SidebarItem? = .all

    @StateObject private var clipStore: ClipStore
    @StateObject private var albumStore: AlbumStore
    @StateObject private var tagStore: TagStore

    @StateObject private var allTabRouter = Router()
    @StateObject private var albumTabRouter = Router()

    init(clipStore: ClipStore, albumStore: AlbumStore, tagStore: TagStore) {
        self._clipStore = .init(wrappedValue: clipStore)
        self._albumStore = .init(wrappedValue: albumStore)
        self._tagStore = .init(wrappedValue: tagStore)
    }

    var body: some View {
        let minWidth = max(
            AlbumListLayout.minimum.minWidth,
            ClipListLayout.minimum.minWidth
        )

        NavigationSplitView {
            Sidebar(selectedItem: $selectedItem, tags: tagStore.tags, albums: albumStore.albums)
        } detail: {
            switch selectedItem {
            case .all:
                AppStack {
                    ClipListView(clips: clipStore.clips)
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case .albums:
                AppStack {
                    AlbumListView(controller: .init(underlying: albumStore))
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case let .album(album):
                AppStack {
                    ClipListView(clips: album.clips)
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case nil:
                // TODO: 実装する
                EmptyView()
            }
        }
        .onAppear(perform: {
            clipStore.load()
            albumStore.load()
            tagStore.load()
        })
    }
}
