//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import AppKit
import Domain
import SwiftUI

struct PreviewItemView: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.body)
            .padding([.leading, .trailing], 6)
            .padding([.top, .bottom], 4)
            .background { Color(NSColor.secondarySystemFill) }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    static func preferredWidth(for name: String) -> CGFloat {
        return name.labelBoundingRect(with: Font.body.nsFont).width + 6 * 2
    }
}

private extension String {
    func labelBoundingRect(with font: NSFont) -> CGRect {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let options: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let rect = self.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: options, attributes: attributes, context: nil)
        return rect
    }
}

private extension Font {
    var nsFont: NSFont {
        switch self {
        case .largeTitle: NSFont.preferredFont(forTextStyle: .largeTitle)
        case .title: NSFont.preferredFont(forTextStyle: .title1)
        case .title2: NSFont.preferredFont(forTextStyle: .title2)
        case .title3: NSFont.preferredFont(forTextStyle: .title3)
        case .headline: NSFont.preferredFont(forTextStyle: .headline)
        case .subheadline: NSFont.preferredFont(forTextStyle: .subheadline)
        case .callout: NSFont.preferredFont(forTextStyle: .callout)
        case .caption: NSFont.preferredFont(forTextStyle: .caption1)
        case .caption2: NSFont.preferredFont(forTextStyle: .caption2)
        case .footnote: NSFont.preferredFont(forTextStyle: .footnote)
        case .body: NSFont.preferredFont(forTextStyle: .body)
        default: NSFont.preferredFont(forTextStyle: .body)
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var isSelected = false

        var body: some View {
            PreviewItemView(name: "hoge")
                .padding()
        }
    }

    return PreviewView()
}
