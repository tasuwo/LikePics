//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import MasonryGrid
import SwiftUI

struct ClipListView: View {
    let clips: [Clip]

    @State var layout: ClipListLayout = .default
    @Namespace var animation

    var body: some View {
        ScrollView {
            VMasonryGrid(clips,
                         numberOfColumns: layout.numberOfColumns,
                         columnSpacing: layout.spacing,
                         contentSpacing: layout.spacing)
            { clip in
                let columnWidth: CGFloat = 100
                guard let primaryItem = clip.primaryItem else { return columnWidth }
                return columnWidth / primaryItem.imageSize.cgSize.width * primaryItem.imageSize.cgSize.height
            } content: { clip in
                ClipView(clip: clip)
                    .matchedGeometryEffect(id: clip.id, in: animation)
            }
            .frame(minWidth: ClipListLayout.minimum.minRowWidth)
            .padding(.all, 20)
        }
        .onChangeFrame { size in
            layout = ClipListLayout.layout(forWidth: size.width - 20 * 2)
        }
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }

    func makeClip(size: ImageSize) -> Clip {
        return .init(id: UUID(),
                     description: "",
                     items: [
                         .init(id: UUID(),
                               url: nil,
                               clipId: UUID(),
                               clipIndex: 0,
                               imageId: UUID(),
                               imageFileName: "",
                               imageUrl: nil,
                               imageSize: size,
                               imageDataSize: 0,
                               registeredDate: Date(),
                               updatedDate: Date())
                     ],
                     isHidden: false,
                     dataSize: 0,
                     registeredDate: Date(),
                     updatedDate: Date())
    }

    return ClipListView(clips: (0 ... 100).map { _ in
        makeClip(size: .init(height: CGFloat((100 ... 150).randomElement()!), width: 100))
    })
    .environment(\.imageQueryService, _ImageQueryService())
}
