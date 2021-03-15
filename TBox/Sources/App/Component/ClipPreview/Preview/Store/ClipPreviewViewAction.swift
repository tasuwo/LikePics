//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

enum ClipPreviewViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case itemUpdated(ClipItem)
    case failedToLoadItem

    // MARK: Load Completion

    case imageLoaded(UIImage?)
}
