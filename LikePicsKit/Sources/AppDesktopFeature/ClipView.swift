//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct ClipView: View {
    let clip: Clip
    @State var primaryThumbnailSize: CGSize?
    // TODO: Previewを表示できるようにする
    @EnvironmentObject var container: AppContainer

    var body: some View {
        if let primaryItem = clip.primaryItem {
            LazyImage(processingQueue: container.clipThumbnailProcessingQueue, cacheKey: "item-\(primaryItem.imageId.uuidString)") { [container] in
                try? container.imageQueryService.read(having: primaryItem.imageId)
            } content: { image in
                if let image {
                    image
                        .resizable()
                } else {
                    Color.gray
                }
            } placeholder: {
                Color.gray
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .aspectRatio(primaryItem.imageSize.aspectRatio, contentMode: .fit)
            .onChangeFrame { size in
                primaryThumbnailSize = size
            }
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
    ClipView(clip: .init(id: UUID(),
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
}
