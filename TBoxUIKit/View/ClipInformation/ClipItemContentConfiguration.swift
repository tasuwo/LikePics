//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ClipItemContentConfiguration {
    public var image: UIImage?
    public var fileName: String
    public var dataSize: Int
    public var page: Int
    public var numberOfPage: Int

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
        self.dataSize = 0
        self.page = 0
        self.numberOfPage = 0
    }
}

extension ClipItemContentConfiguration: UIContentConfiguration {
    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        return ClipItemContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> ClipItemContentConfiguration {
        return self
    }
}
