//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipSearchHistoryHeaderCell: UICollectionViewListCell {
    private var _contentConfiguration: ClipSearchHistoryHeaderConfiguration {
        return (contentConfiguration as? ClipSearchHistoryHeaderConfiguration) ?? ClipSearchHistoryHeaderConfiguration()
    }

    override public func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = _contentConfiguration.updated(for: state)
    }
}
