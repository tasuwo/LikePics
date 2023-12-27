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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageId = album.clips.first?.primaryItem?.imageId {
                Color.clear
                    .overlay {
                        LazyImage(cacheKey: "album-\(imageId.uuidString)") {
                            try? imageQueryService.read(having: imageId)
                        } content: { image in
                            if let image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        } placeholder: {
                            Color.gray
                        }
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
                                  updatedDate: Date()))
        .padding()
        .environment(\.imageQueryService, _ImageQueryService())
}
