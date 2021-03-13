//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

enum ClipPreviewViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: Load Completion

    case imageLoaded(UIImage?)
}
