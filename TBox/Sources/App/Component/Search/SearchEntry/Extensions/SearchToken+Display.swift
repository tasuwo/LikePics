//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

extension ClipSearchToken {
    var uiSearchToken: UISearchToken {
        let token = UISearchToken(icon: kind.icon, text: title)
        token.representedObject = self
        return token
    }
}

extension ClipSearchToken.Kind {
    var icon: UIImage {
        switch self {
        case .tag:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "tag.fill")!.withRenderingMode(.alwaysTemplate)

        case .album:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "square.stack.fill")!.withRenderingMode(.alwaysTemplate)
        }
    }
}

extension ClipSearchToken {
    var attributedTitle: NSAttributedString {
        let string = NSMutableAttributedString(string: title)

        let spacer = NSTextAttachment()
        spacer.bounds = .init(x: 0, y: 0, width: 8, height: CGFloat.leastNormalMagnitude)
        string.insert(NSAttributedString(attachment: spacer), at: 0)

        let iconAttachment = NSTextAttachment()
        iconAttachment.image = kind.icon
        let iconAttachmentString = NSAttributedString(attachment: iconAttachment)
        string.insert(iconAttachmentString, at: 0)

        string.addAttribute(.foregroundColor,
                            value: UIColor.label,
                            range: NSRange(location: 0, length: iconAttachmentString.length))

        return string
    }
}

extension UISearchToken {
    var underlyingToken: ClipSearchToken? {
        return self.representedObject as? ClipSearchToken
    }
}
