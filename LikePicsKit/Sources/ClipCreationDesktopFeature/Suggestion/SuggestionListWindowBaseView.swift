//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import AppKit

final class SuggestionListWindowBaseView: NSView {
    static let cornerRadius: CGFloat = 10

    override func draw(_ dirtyRect: NSRect) {
        let borderPath = NSBezierPath(roundedRect: bounds, xRadius: Self.cornerRadius, yRadius: Self.cornerRadius)
        NSColor.windowBackgroundColor.setFill()
        borderPath.fill()
    }
}
