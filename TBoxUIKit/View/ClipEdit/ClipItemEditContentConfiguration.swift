//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipItemEditContentDelegate: AnyObject {
    func didTapSiteUrl(_ url: URL?, sender: UIView)
    func didTapSiteUrlEditButton(_ url: URL?, sender: UIView)
}

public struct ClipItemEditContentConfiguration {
    public var siteUrl: URL?
    public var isSiteUrlEditable = true
    public var dataSize: Int?
    public var thumbnail: UIImage?
    public var imageWidth: Double?
    public var imageHeight: Double?
    public weak var delegate: ClipItemEditContentDelegate?
    public weak var interactionDelegate: UIContextMenuInteractionDelegate?

    public var siteUrlDisabledForce = false

    public init() {
        self.siteUrl = nil
        self.dataSize = nil
        self.thumbnail = nil
    }
}

extension ClipItemEditContentConfiguration: UIContentConfiguration {
    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        return ClipItemEditContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> ClipItemEditContentConfiguration {
        guard let state = state as? UICellConfigurationState else { return self }
        var newConfiguration = self
        newConfiguration.siteUrlDisabledForce = state.isEditing
        return newConfiguration
    }
}
