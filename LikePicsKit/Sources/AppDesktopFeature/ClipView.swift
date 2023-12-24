//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct ClipView: View {
    let clip: Clip
    @State var primaryThumbnailSize: CGSize?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .aspectRatio(clip.primaryItem?.imageSize.aspectRatio ?? 1, contentMode: .fit)
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
