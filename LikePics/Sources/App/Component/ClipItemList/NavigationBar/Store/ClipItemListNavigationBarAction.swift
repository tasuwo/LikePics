//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

enum ClipItemListNavigationBarAction: Action {
    // MARK: - View Life-Cycle

    case viewDidLoad

    // MARK: - State Observation

    case editted(Bool)
    case updatedSelectionCount(Int)

    // MARK: - NavigationBar

    case didTapResume
    case didTapCancel
    case didTapSelect
}
