//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct AppView: View {
    @State private var selectedItem: SidebarItem? = .all
    @EnvironmentObject private var container: AppContainer
    @AppStorage(\.showHiddenItems) var showHiddenItems

    /// ## HACK
    /// `managedObjectContext` は iCloud 同期の切り替え時に別インスタンスに差し替えられる
    /// この時、古い `managedObjectContext` を参照した `FetchRequest` が残っていると、CoreDataオブジェクト参照時に
    /// クラッシュしてしまう
    /// これを避けるためには `FetchRequest` を再生成するしかないようなので、View 自体を再描画するために用意しているプロパティ
    @State var refreshId = UUID()

    var body: some View {
        let minWidth = min(
            AlbumListLayout.minimum.minWidth,
            ClipListLayout.minimum.minWidth
        )

        NavigationSplitView {
            Sidebar(selectedItem: $selectedItem, showHiddenItems: showHiddenItems)
                .animation(.default, value: showHiddenItems)
        } detail: {
            switch selectedItem {
            case .all:
                AppStack {
                    ClipListQueryView(.all) {
                        ClipListView(clips: $0)
                    }
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case .albums:
                AppStack {
                    AlbumListView(showHiddenItems: showHiddenItems)
                        .animation(.default, value: showHiddenItems)
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case let .album(id):
                AppStack {
                    ClipListQueryView(.album(id)) {
                        ClipListView(clips: $0)
                    }
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case let .tag(id):
                AppStack {
                    ClipListQueryView(.tagged(id)) {
                        ClipListView(clips: $0)
                    }
                }
                .navigationSplitViewColumnWidth(min: minWidth, ideal: minWidth)

            case nil:
                EmptyView()
            }
        }
        .environment(\.managedObjectContext, container.viewContext)
        .id(refreshId)
        .onChange(of: container.viewContext) { _, _ in
            refreshId = UUID()
        }
    }
}
