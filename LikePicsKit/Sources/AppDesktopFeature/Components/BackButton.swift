//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct BackButton: NSViewRepresentable {
    class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func backButtonTapped() {
            action()
        }
    }

    let action: () -> Void

    func makeNSView(context: Context) -> NSButton {
        let backButton = NSButton()
        backButton.isBordered = true
        backButton.image = NSImage(named: NSImage.goBackTemplateName)!
        backButton.target = context.coordinator
        backButton.action = #selector(context.coordinator.backButtonTapped)
        return backButton
    }

    func updateNSView(_ nsView: NSButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
}
