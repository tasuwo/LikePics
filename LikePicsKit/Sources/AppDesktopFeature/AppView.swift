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
        NavigationSplitView {
            Sidebar(selectedItem: $selectedItem, tags: tagStore.tags, albums: albumStore.albums)
        } detail: {
            switch selectedItem {
            case .all:
                NavigationStack(path: $allTabRouter.path) {
                    ClipListView(clips: clipStore.clips)
                        .navigationDestination(for: Route.ClipItem.self) { route in
                            ClipItemView(item: route.clipItem)
                                .environmentObject(allTabRouter)
                        }
                }
                .environmentObject(allTabRouter)

            case .albums:
                NavigationStack(path: $albumTabRouter.path) {
                    AlbumListView(controller: .init(underlying: albumStore))
                        .navigationDestination(for: Route.ClipList.self) { route in
                            ClipListView(clips: route.clips)
                                .environmentObject(albumTabRouter)
                        }
                        .navigationDestination(for: Route.ClipItem.self) { route in
                            ClipItemView(item: route.clipItem)
                                .environmentObject(albumTabRouter)
                        }
                }
                .environmentObject(albumTabRouter)

            case let .album(album):
                ClipListView(clips: album.clips)

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
