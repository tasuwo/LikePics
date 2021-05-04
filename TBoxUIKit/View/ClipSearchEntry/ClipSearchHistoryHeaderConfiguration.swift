//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ClipSearchHistoryHeaderConfiguration {
    public var isRemoveAllButtonEnabled = false
    public var removeAllHistoriesHandler: (() -> Void)?

    public init() {}
}

extension ClipSearchHistoryHeaderConfiguration: UIContentConfiguration {
    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        return ClipSearchHistoryHeaderContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> ClipSearchHistoryHeaderConfiguration {
        return self
    }
}
