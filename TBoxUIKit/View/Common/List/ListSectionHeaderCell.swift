//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ListSectionHeaderCell: UICollectionViewListCell {
    private var _contentConfiguration: ListSectionHeaderConfiguration {
        return (contentConfiguration as? ListSectionHeaderConfiguration) ?? ListSectionHeaderConfiguration()
    }

    override public func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = _contentConfiguration.updated(for: state)
    }
}
