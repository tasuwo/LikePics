//
//  Copyright © 2024 Tasuku Tozawa. All rights reserved.
//

import ShareExtensionDesktopFeature
import SwiftUI

let bundleIdentifier = {
    guard var components = Bundle.main.bundleIdentifier?.components(separatedBy: ".") else { fatalError() }
    components.removeLast()
    return components.joined(separator: ".")
}()

final class ShareViewController: NSViewController {
    private let container = Container(bundleIdentifier: bundleIdentifier)

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    @IBOutlet weak var contentView: NSView!

    override func loadView() {
        super.loadView()

        let view = NSHostingView(rootView: ShareExtensionView(context: extensionContext!, container: container))
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}
