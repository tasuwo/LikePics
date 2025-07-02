//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct ClipView: View {
    static let cornerRadius: CGFloat = 12

    let clip: Clip
    @Environment(\.imageQueryService) var imageQueryService
    @Environment(\.clipThumbnailProcessingQueue) var processingQueue

    var body: some View {
        if let primaryItem = clip.primaryItem {
            VStack(spacing: 0) {
                LazyImage {
                    try? imageQueryService.read(having: primaryItem.imageId)
                } content: { image in
                    if let image {
                        image
                            .resizable()
                            .overlay {
                                GeometryReader { geometry in
                                    let markSize = min(geometry.size.width / 5, 40)
                                    HiddenMark(size: markSize)
                                        .offset(
                                            x: geometry.frame(in: .local).maxX - markSize - 12,
                                            y: geometry.frame(in: .local).maxY - markSize - 12
                                        )
                                }
                                .opacity(clip.isHidden ? 1 : 0)
                            }
                    } else {
                        Color(NSColor.secondarySystemFill)
                    }
                } placeholder: {
                    Color(NSColor.secondarySystemFill)
                }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                .aspectRatio(primaryItem.imageSize.aspectRatio, contentMode: .fit)
                .environment(\.lazyImageCacheInfo, .init(key: "item-\(primaryItem.imageId.uuidString)", originalImageSize: primaryItem.imageSize.cgSize))
                .background {
                    if let secondaryItem = clip.secondaryItem {
                        GeometryReader { geometry in
                            ZStack(alignment: .top) {
                                LazyImage {
                                    try? imageQueryService.read(having: secondaryItem.imageId)
                                } content: { image in
                                    if let image {
                                        image
                                            .resizable()
                                            .overlay(content: {
                                                Color.black
                                                    .opacity(0.4)
                                            })
                                    } else {
                                        Color(NSColor.secondarySystemFill)
                                    }
                                } placeholder: {
                                    Color(NSColor.secondarySystemFill)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                                .environment(\.lazyImageCacheInfo, .init(key: "item-\(secondaryItem.imageId.uuidString)", originalImageSize: secondaryItem.imageSize.cgSize))
                                .frame(width: geometry.size.width)
                                .aspectRatio(secondaryItem.imageSize.aspectRatio, contentMode: .fit)
                                .fixedSize(horizontal: false, vertical: true)
                                .offset(y: 16)
                                .frame(height: geometry.size.height, alignment: .bottom)
                                .background {
                                    if let tertiaryItem = clip.tertiaryItem {
                                        LazyImage {
                                            try? imageQueryService.read(having: tertiaryItem.imageId)
                                        } content: { image in
                                            if let image {
                                                image
                                                    .resizable()
                                                    .overlay(content: {
                                                        Color.black
                                                            .opacity(0.6)
                                                    })
                                            } else {
                                                Color(NSColor.secondarySystemFill)
                                            }
                                        } placeholder: {
                                            Color(NSColor.secondarySystemFill)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                                        .environment(\.lazyImageCacheInfo, .init(key: "item-\(tertiaryItem.imageId.uuidString)", originalImageSize: tertiaryItem.imageSize.cgSize))
                                        .frame(width: geometry.size.width)
                                        .aspectRatio(tertiaryItem.imageSize.aspectRatio, contentMode: .fit)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .offset(y: 32)
                                        .frame(height: geometry.size.height, alignment: .bottom)
                                    }
                                }

                                Color.clear
                                    .frame(
                                        width: geometry.size.width,
                                        height: geometry.size.height + (clip.secondaryItem != nil ? (clip.tertiaryItem != nil ? 32 : 16) : 0)
                                    )
                                    .fixedSize()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                        }
                    }
                }
                .environment(\.imageProcessingQueue, processingQueue)

                Color.clear
                    .frame(height: clip.secondaryItem != nil ? (clip.tertiaryItem != nil ? 32 : 16) : 0)
            }
        } else {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .aspectRatio(1, contentMode: .fit)
        }
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }

    return ClipView(
        clip: .init(
            id: UUID(),
            description: "",
            items: [
                .init(
                    id: UUID(),
                    url: nil,
                    clipId: UUID(),
                    clipIndex: 0,
                    imageId: UUID(),
                    imageFileName: "",
                    imageUrl: nil,
                    imageSize: .init(height: 150, width: 100),
                    imageDataSize: 0,
                    registeredDate: Date(),
                    updatedDate: Date()
                ),
                .init(
                    id: UUID(),
                    url: nil,
                    clipId: UUID(),
                    clipIndex: 0,
                    imageId: UUID(),
                    imageFileName: "",
                    imageUrl: nil,
                    imageSize: .init(height: 100, width: 150),
                    imageDataSize: 0,
                    registeredDate: Date(),
                    updatedDate: Date()
                ),
                .init(
                    id: UUID(),
                    url: nil,
                    clipId: UUID(),
                    clipIndex: 0,
                    imageId: UUID(),
                    imageFileName: "",
                    imageUrl: nil,
                    imageSize: .init(height: 1000, width: 150),
                    imageDataSize: 0,
                    registeredDate: Date(),
                    updatedDate: Date()
                ),
            ],
            isHidden: false,
            dataSize: 0,
            registeredDate: Date(),
            updatedDate: Date()
        )
    )
    .environment(\.imageQueryService, _ImageQueryService())
}
