//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct ClipItemGrid: View {
    struct ClipItem: Swift.Identifiable {
        let id: UUID
        let imageFileName: String
        let imageDataSize: Int
    }

    static let spacing: CGFloat = 8.0

    let clipItems: [ClipItem]

    var layout: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: horizontalItemCount)
    }

    var horizontalItemCount: Int {
        switch sizeClass {
        case .compact:
            return 3

        case .regular:
            return 6

        default:
            return 3
        }
    }

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: layout, alignment: .center, spacing: Self.spacing) {
                ForEach(Array(zip(clipItems.indices, clipItems)), id: \.0) { index, item in
                    ClipItemCell(image: Self.imageWithColor(color: .red, size: .init(width: 100, height: 100)),
                                 fileName: item.imageFileName,
                                 dataSize: item.imageDataSize,
                                 page: index,
                                 numberOfPage: clipItems.count)
                }
            }
            .padding(.all, Self.spacing)
        }
    }

    static func imageWithColor(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // swiftlint:disable:next force_unwrapping
        return image!
    }
}

struct ClipItemGrid_Previews: PreviewProvider {
    static var previews: some View {
        ClipItemGrid(clipItems: [
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024),
            .init(id: UUID(), imageFileName: "hoge", imageDataSize: 1024)
        ])
    }
}
