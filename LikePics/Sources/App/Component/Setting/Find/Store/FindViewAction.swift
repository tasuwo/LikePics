//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Foundation

enum FindViewAction: Action {
    case updatedTitle(String?)
    case updatedUrl(URL?)
    case updatedCanGoBack(Bool)
    case updatedCanGoForward(Bool)
    case updatedLoading(Bool)
    case updatedEstimatedProgress(Double)
}
