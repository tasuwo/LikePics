//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct ClipItemGridDropDelegate: DropDelegate {
    let item: ClipItemGrid.ClipItem
    @Binding var clipItems: [ClipItemGrid.ClipItem]
    @Binding var dragging: ClipItemGrid.ClipItem?

    // MARK: - DropDelegate

    func validateDrop(info: DropInfo) -> Bool {
        true
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return false
    }

    func dropEntered(info: DropInfo) {
        guard dragging != item,
              let dragging = dragging,
              let from = clipItems.firstIndex(of: dragging),
              let to = clipItems.firstIndex(of: item),
              from != to
        else {
            return
        }

        clipItems.move(fromOffsets: IndexSet(integer: from),
                       toOffset: to > from ? to + 1 : to)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct ClipItemGrid: View {
    struct ClipItem: Equatable, Hashable, Swift.Identifiable {
        let id: UUID
        let imageFileName: String
        let imageDataSize: Int
    }

    static let spacing: CGFloat = 8.0

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

    @State var clipItems: [ClipItem]
    @State private var dragging: ClipItem?

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: layout, alignment: .center, spacing: Self.spacing) {
                ForEach(Array(zip(clipItems.indices, clipItems)), id: \.1) { index, item in
                    if dragging == item {
                        clipItemCell(item, at: index)
                            .hidden()
                    } else {
                        clipItemCell(item, at: index)
                            .onDrag {
                                dragging = item
                                return NSItemProvider(object: item.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], delegate: ClipItemGridDropDelegate(item: item, clipItems: $clipItems, dragging: $dragging))
                    }
                }
            }
            .animation(.default, value: clipItems)
            .padding(.all, Self.spacing)
        }
    }

    func clipItemCell(_ item: ClipItem, at index: Int) -> ClipItemCell {
        return ClipItemCell(image: Self.imageWithColor(color: .red, size: .init(width: 100, height: 100)),
                            fileName: item.imageFileName,
                            dataSize: item.imageDataSize,
                            page: index,
                            numberOfPage: clipItems.count)
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

// MARK: - Preview

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
