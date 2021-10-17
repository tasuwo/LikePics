//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ClipItemContentConfiguration {
    public var image: UIImage?
    public var fileName: String
    public var imageSize: CGSize
    public var dataSize: Int
    public var page: Int
    public var numberOfPage: Int
    var isOverlayViewHidden: Bool

    var displayFileName: String {
        fileName.isEmpty ? L10n.clipItemCellNoTitle : fileName
    }

    var displayDataSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .binary)
    }

    // MARK: - Initializers

    public init() {
        self.image = nil
        self.fileName = ""
        self.imageSize = .zero
        self.dataSize = 0
        self.page = 0
        self.numberOfPage = 0
        self.isOverlayViewHidden = true
    }
}

extension ClipItemContentConfiguration: UIContentConfiguration {
    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        return ClipItemContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> ClipItemContentConfiguration {
        guard let state = state as? UICellConfigurationState else { return self }

        var configuration = self

        if state.isEditing {
            configuration.isOverlayViewHidden = !state.isSelected
        } else {
            configuration.isOverlayViewHidden = true
        }

        return configuration
    }
}
