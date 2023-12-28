//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct ClipItemView: View {
    let item: ClipItem
    @Environment(\.imageQueryService) var imageQueryService
    @Environment(\.clipThumbnailProcessingQueue) var processingQueue

    var body: some View {
        LazyImage(originalSize: item.imageSize.cgSize, cacheKey: "clip-item-\(item.imageId.uuidString)") {
            try? imageQueryService.read(having: item.imageId)
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
        .aspectRatio(item.imageSize.aspectRatio, contentMode: .fit)
        .environment(\.imageProcessingQueue, processingQueue)
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }

    return ClipItemView(item: .init(id: UUID(),
                                    url: nil,
                                    clipId: UUID(),
                                    clipIndex: 0,
                                    imageId: UUID(),
                                    imageFileName: "",
                                    imageUrl: nil,
                                    imageSize: .init(height: 150, width: 100),
                                    imageDataSize: 0,
                                    registeredDate: Date(),
                                    updatedDate: Date()))
        .environment(\.imageQueryService, _ImageQueryService())
}
