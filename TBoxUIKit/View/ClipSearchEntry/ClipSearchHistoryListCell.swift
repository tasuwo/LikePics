//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipSearchHistoryListCell: UICollectionViewListCell {
    private var _contentConfiguration: ClipSearchHistoryContentConfiguration {
        return (contentConfiguration as? ClipSearchHistoryContentConfiguration) ?? ClipSearchHistoryContentConfiguration()
    }
}
