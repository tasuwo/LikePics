//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct AlbumView: View {
    let album: Album
    @Environment(\.imageQueryService) var imageQueryService
    @Environment(\.albumThumbnailProcessingQueue) var processingQueue
    @AppStorage(StorageKey.showHiddenItems.rawValue) var showHiddenItems: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let primaryItem = album.clips.first(where: { showHiddenItems ? true : $0.isHidden == false })?.primaryItem {
                Color.clear
                    .overlay {
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
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .clipped()
                    .environment(\.imageProcessingQueue, processingQueue)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .aspectRatio(1, contentMode: .fit)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.body)
                Text("\(album.clips.count)")
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

    return AlbumView(album: Album(id: UUID(),
                                  title: "Test Album",
                                  clips: [],
                                  isHidden: false,
                                  registeredDate: Date(),
                                  updatedDate: Date()),
                     showHiddenItems: true)
        .padding()
        .environment(\.imageQueryService, _ImageQueryService())
}
