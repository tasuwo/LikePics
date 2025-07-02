//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

extension View {
    func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = .command,
        action: @escaping () -> Void
    ) -> some View {
        background(
            Button(action: action) {
                Color.clear
            }
            .focusable(false)
            .opacity(0)
            .padding(0)
            .frame(width: 0, height: 0)
            .keyboardShortcut(key, modifiers: modifiers)
        )
    }

    func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = .command,
        localization: KeyboardShortcut.Localization,
        action: @escaping () -> Void
    ) -> some View {
        background(
            Button(action: action) {
                Color.clear
            }
            .focusable(false)
            .opacity(0)
            .padding(0)
            .frame(width: 0, height: 0)
            .keyboardShortcut(key, modifiers: modifiers, localization: localization)
        )
    }
}
