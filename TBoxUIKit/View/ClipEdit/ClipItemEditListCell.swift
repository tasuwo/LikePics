//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipItemEditListCell: UICollectionViewListCell {
    override public func updateConfiguration(using state: UICellConfigurationState) {
        let currentConfiguration = (contentConfiguration as? ClipItemEditContentConfiguration)
            ?? ClipItemEditContentConfiguration()
        contentConfiguration = currentConfiguration.updated(for: state)
    }
}
