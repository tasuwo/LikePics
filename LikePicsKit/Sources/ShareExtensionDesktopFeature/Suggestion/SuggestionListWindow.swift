//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import AppKit

final class SuggestionListWindow: NSWindow {
    convenience init(contentRect: NSRect, defer flag: Bool) {
        self.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        hasShadow = true
        backgroundColor = .clear
        isOpaque = false
    }
}
