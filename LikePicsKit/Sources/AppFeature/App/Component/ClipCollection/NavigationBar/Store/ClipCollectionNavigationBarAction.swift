//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

enum ClipCollectionNavigationBarAction: Action, Equatable {
    // MARK: - View Life-Cycle

    case viewDidLoad

    // MARK: - State Observation

    case stateChanged

    // MARK: - NavigationBar

    case didTapCancel
    case didTapSelectAll
    case didTapDeselectAll
    case didTapSelect
    case didTapLayout
}
