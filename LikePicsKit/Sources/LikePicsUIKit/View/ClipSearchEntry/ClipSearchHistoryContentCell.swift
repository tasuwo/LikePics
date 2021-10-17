//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipSearchHistoryContentCell: UICollectionViewListCell {
    public var searchHistory: ClipSearchHistory?

    override public func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = ClipSearchHistoryContentConfiguration().updated(for: state)
        newConfiguration.clipSearchHistory = searchHistory
        contentConfiguration = newConfiguration
    }
}
