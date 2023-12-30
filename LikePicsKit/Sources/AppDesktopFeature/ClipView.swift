//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct ClipView: View {
    let clip: Clip
    @State var primaryThumbnailSize: CGSize?
    @Environment(\.imageQueryService) var imageQueryService
    @Environment(\.clipThumbnailProcessingQueue) var processingQueue

    var body: some View {
        if let primaryItem = clip.primaryItem {
            LazyImage {
                try? imageQueryService.read(having: primaryItem.imageId)
            } content: { image in
                if let image {
                    image
                        .resizable()
                } else {
                    Color(NSColor.secondarySystemFill)
                }
            } placeholder: {
                Color(NSColor.secondarySystemFill)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .aspectRatio(primaryItem.imageSize.aspectRatio, contentMode: .fit)
            .onChangeFrame { size in
                primaryThumbnailSize = size
            }
            .environment(\.imageProcessingQueue, processingQueue)
            .environment(\.lazyImageCacheInfo, .init(key: "item-\(primaryItem.imageId.uuidString)", originalImageSize: primaryItem.imageSize.cgSize))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .aspectRatio(1, contentMode: .fit)
                .onChangeFrame { size in
                    primaryThumbnailSize = size
                }
        }
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }

    return ClipView(clip: .init(id: UUID(),
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
                                          updatedDate: Date())
                                ],
                                isHidden: false,
                                dataSize: 0,
                                registeredDate: Date(),
                                updatedDate: Date()))
        .environment(\.imageQueryService, _ImageQueryService())
}
