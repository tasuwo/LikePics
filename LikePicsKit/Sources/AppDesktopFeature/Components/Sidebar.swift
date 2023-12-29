//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import MasonryGrid
import SwiftUI

struct Sidebar: View {
    @Binding var selectedItem: SidebarItem?

    let tags: [Tag]
    let albums: [Album]

    @State private var isAlbumHovered = false
    @State private var isAlbumExpanded = false

    @Namespace private var animation

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
                    ForEach(albums) { album in
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
                        .tag(SidebarItem.album(album))
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
                HMasonryGrid(tags) { tag in
                    TagButton(tag: tag, isSelected: selectedItem?.tagId() == tag.id)
                        .onTapGesture {
                            if selectedItem?.tagId() == tag.id {
                                selectedItem = nil
                            } else {
                                selectedItem = .tag(tag)
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
    struct PreviewView: View {
        @State var selectedItem: SidebarItem? = .all
        @State var tags: [Tag] = Array((0 ... 20).map { _ in Tag(id: UUID(), name: randomTagName(), isHidden: false) })
        @State var albums: [Album] = Array((0 ... 6).map { _ in Album(id: UUID(), title: randomAlbumName(), clips: [], isHidden: false, registeredDate: Date(), updatedDate: Date()) })

        var body: some View {
            NavigationSplitView {
                Sidebar(selectedItem: $selectedItem, tags: tags, albums: albums)
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
}
