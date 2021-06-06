//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ListSectionHeaderConfiguration {
    public let title: String

    public init() {
        self.title = ""
    }

    public init(title: String) {
        self.title = title
    }
}

extension ListSectionHeaderConfiguration: UIContentConfiguration {
    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        return ListSectionHeaderContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> ListSectionHeaderConfiguration {
        return self
    }
}
