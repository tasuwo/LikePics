//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct ClipItemCell: View {
    let image: UIImage
    let fileName: String?
    let dataSize: Int

    var displayFileName: String {
        fileName ?? L10n.clipItemCellNoTitle
    }

    var displayDataSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .binary)
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(displayFileName)
                .font(.caption)
                .foregroundColor(.primary)
            Text(displayDataSize)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct ClipItemCell_Previews: PreviewProvider {
    static func imageWithColor(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // swiftlint:disable:next force_unwrapping
        return image!
    }

    static var previews: some View {
        HStack {
            ClipItemCell(image: imageWithColor(color: .red, size: .init(width: 10, height: 10)),
                         fileName: "Hoge",
                         dataSize: 1024)
                .frame(width: 100, height: 100)

            ClipItemCell(image: imageWithColor(color: .blue, size: .init(width: 10, height: 20)),
                         fileName: nil,
                         dataSize: 1024)
                .frame(width: 100, height: 100)
        }
    }
}
