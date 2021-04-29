//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

struct SearchMenuDisplaySettingAction: Equatable {
    enum Kind: Equatable {
        case unspecified
        case hidden
        case revealed
    }

    let kind: Kind

    var title: String {
        switch kind {
        case .unspecified:
            return L10n.searchEntryMenuDisplaySettingUnspecified
        case .hidden:
            return L10n.searchEntryMenuDisplaySettingHidden
        case .revealed:
            return L10n.searchEntryMenuDisplaySettingRevealed
        }
    }

    let isSelected: Bool

    var image: UIImage? {
        switch kind {
        case .unspecified:
            return nil
        case .hidden:
            return UIImage(systemName: "eye.slash")
        case .revealed:
            return UIImage(systemName: "eye")
        }
    }
}

extension SearchMenuDisplaySettingAction: SearchMenuAction {}
