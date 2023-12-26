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

    init(clipStore: ClipStore, albumStore: AlbumStore, tagStore: TagStore) {
        self._clipStore = .init(wrappedValue: clipStore)
        self._albumStore = .init(wrappedValue: albumStore)
        self._tagStore = .init(wrappedValue: tagStore)
    }

    var body: some View {
        NavigationSplitView {
            Sidebar(selectedItem: $selectedItem, tags: tagStore.tags, albums: albumStore.albums)
        } detail: {
            switch selectedItem {
            case .all:
                ClipListView(clips: clipStore.clips)

            case .albums:
                AlbumListView(controller: .init(underlying: albumStore))

            case let .album(id):
                ClipListView(clips: [])

            case .browse:
                // TODO: 実装する
                EmptyView()

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
