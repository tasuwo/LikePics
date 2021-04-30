//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ClipSearchHistoryContentConfiguration {
    public struct QueryConfiguration {
        public let title: String
        public let sortName: String
        public let displaySettingName: String
        public let isDisplaySettingHidden: Bool

        public init(title: String, sortName: String, displaySettingName: String, isDisplaySettingHidden: Bool) {
            self.title = title
            self.sortName = sortName
            self.displaySettingName = displaySettingName
            self.isDisplaySettingHidden = isDisplaySettingHidden
        }
    }

    public var queryConfiguration: QueryConfiguration?

    public init() {
        self.queryConfiguration = nil
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
