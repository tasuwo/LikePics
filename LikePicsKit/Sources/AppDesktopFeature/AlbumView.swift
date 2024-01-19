//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct AlbumView: View {
    static let cornerRadius: CGFloat = 12

    let album: Album
    @State private var isEditingTitle = false
    @State private var editingTitle = ""
    @FocusState private var isTitleTextFieldFocused
    @Environment(\.imageQueryService) var imageQueryService
    @Environment(\.albumThumbnailProcessingQueue) var processingQueue
    @Environment(\.managedObjectContext) var context
    @AppStorage(\.showHiddenItems, store: .appGroup) var showHiddenItems

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let primaryItem = album.clips.first(where: { showHiddenItems ? true : $0.isHidden == false })?.primaryItem {
                LazyImage {
                    try? imageQueryService.read(having: primaryItem.imageId)
                } content: { image in
                    if let image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(NSColor.secondarySystemFill)
                    }
                } placeholder: {
                    Color(NSColor.secondarySystemFill)
                }
                .environment(\.lazyImageCacheInfo, .init(key: "album-\(primaryItem.imageId.uuidString)", originalImageSize: primaryItem.imageSize.cgSize))
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                .clipped()
                .overlay {
                    GeometryReader { geometry in
                        let markSize = min(geometry.size.width / 5, 40)
                        HiddenMark(size: markSize)
                            .offset(x: geometry.frame(in: .local).maxX - markSize - 12,
                                    y: geometry.frame(in: .local).maxY - markSize - 12)
                    }
                    .opacity(album.isHidden ? 1 : 0)
                }
                .environment(\.imageProcessingQueue, processingQueue)
            } else {
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .aspectRatio(1, contentMode: .fit)
            }

            VStack(alignment: .leading, spacing: 2) {
                Group {
                    if isEditingTitle {
                        TextField(text: $editingTitle) {
                            EmptyView()
                        }
                        .focused($isTitleTextFieldFocused)
                        .onSubmit {
                            do {
                                guard !editingTitle.isEmpty else { return }
                                try context.updateAlbum(having: album.id, title: editingTitle)
                                isEditingTitle = false
                            } catch {
                            }
                        }
                        .keyboardShortcut(.escape, modifiers: []) {
                            isEditingTitle = false
                        }
                        .onChange(of: isTitleTextFieldFocused) { _, isFocused in
                            if !isFocused {
                                isEditingTitle = false
                            }
                        }
                    } else {
                        Text(album.title)
                            .font(.body)
                            .lineLimit(1)
                            .onTapGesture {
                                editingTitle = album.title
                                isEditingTitle = true
                                isTitleTextFieldFocused = true
                            }
                    }
                }
                .frame(height: 24)

                Text("\(album.clips.count)", bundle: .module, comment: "Clips count in album.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }
    UserDefaults.appGroup = UserDefaults(suiteName: "net.tasuwo.TBox.preview")!

    return AlbumView(album: Album(id: UUID(),
                                  title: "Test Album",
                                  clips: [
                                      .init(id: UUID(),
                                            description: "",
                                            items: [
                                                .init(id: UUID(),
                                                      url: nil,
                                                      clipId: UUID(),
                                                      clipIndex: 0,
                                                      imageId: UUID(),
                                                      imageFileName: "",
                                                      imageUrl: nil,
                                                      imageSize: .init(height: 150, width: 100),
                                                      imageDataSize: 0,
                                                      registeredDate: Date(),
                                                      updatedDate: Date()),
                                            ],
                                            isHidden: false,
                                            dataSize: 0,
                                            registeredDate: Date(),
                                            updatedDate: Date())
                                  ],
                                  isHidden: false,
                                  registeredDate: Date(),
                                  updatedDate: Date()))
        .padding()
        .environment(\.imageQueryService, _ImageQueryService())
}
