//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipSearchHistoryHeaderCell: UICollectionViewListCell {
    public var isRemoveAllButtonEnabled: Bool = false
    public var removeAllHistoriesHandler: (() -> Void)?

    override public func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = ClipSearchHistoryHeaderConfiguration().updated(for: state)
        newConfiguration.isRemoveAllButtonEnabled = isRemoveAllButtonEnabled
        newConfiguration.removeAllHistoriesHandler = removeAllHistoriesHandler
        contentConfiguration = newConfiguration
    }
}
