//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class URLButtonInteractionHandler: NSObject {
    weak var baseView: UIView?
}

extension URLButtonInteractionHandler: UIContextMenuInteractionDelegate {
    // MARK: - UIContextMenuInteractionDelegate

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let button = interaction.view as? UIButton,
              let text = button.titleLabel?.text,
              let url = URL(string: text)
        else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: self.makePreviewProvider(for: url),
                                          actionProvider: self.makeActionProvider(for: url))
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, interaction: interaction)
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, interaction: interaction)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration, interaction: UIContextMenuInteraction) -> UITargetedPreview? {
        guard let view = interaction.view else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: view, parameters: parameters)
    }

    private func makePreviewProvider(for url: URL) -> (() -> UIViewController) {
        let viewController = UIViewController()

        let label = UILabel()
        label.text = url.absoluteString
        label.textColor = Asset.Color.likePicsRedClient.color
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0

        viewController.view = label

        let labelSize = label.sizeThatFits(baseView?.frame.size ?? .zero)
        viewController.preferredContentSize = CGSize(width: labelSize.width + 16 * 2,
                                                     height: labelSize.height + 16 * 2)

        return { viewController }
    }

    private func makeActionProvider(for url: URL) -> UIContextMenuActionProvider {
        let open = UIAction(title: L10n.urlContextMenuOpen, image: UIImage(systemName: "globe")) { [weak self] _ in
            self?.baseView?.window?.windowScene?.open(url, options: nil, completionHandler: nil)
        }
        let copy = UIAction(title: L10n.urlContextMenuCopy, image: UIImage(systemName: "square.on.square.fill")) { _ in
            UIPasteboard.general.string = url.absoluteString
        }
        return { _ in UIMenu(title: "", children: [open, copy]) }
    }
}
