//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ClipSearchHistoryContentConfiguration {
    public var clipSearchHistory: ClipSearchHistory?

    public init() {
        self.clipSearchHistory = nil
    }
}

extension ClipSearchHistoryContentConfiguration: UIContentConfiguration {
    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        return ClipSearchHistoryContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> ClipSearchHistoryContentConfiguration {
        return self
    }
}
