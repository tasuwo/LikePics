//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct AlbumView: View {
    let album: Album

    // TODO: Previewを表示できるようにする
    @EnvironmentObject var container: AppContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageId = album.clips.first?.primaryItem?.imageId {
                Color.clear
                    .overlay {
                        LazyImage(request: .init(source: .provider(ImageDataProvider(imageId: imageId,
                                                                                     cacheKey: "album-\(imageId.uuidString)",
                                                                                     imageQueryService: container.imageQueryService))),
                        processingQueue: container.albumThumbnailProcessingQueue) { image in
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
    AlbumView(album: Album(id: UUID(),
                           title: "Test Album",
                           clips: [],
                           isHidden: false,
                           registeredDate: Date(),
                           updatedDate: Date()))
        .padding()
}
