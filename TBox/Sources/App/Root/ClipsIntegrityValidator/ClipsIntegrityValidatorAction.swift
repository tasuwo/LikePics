//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

enum ClipsIntegrityValidatorAction: Action {
    case didLaunchApp
    case shareExtensionDidCompleteRequest
    case didStartLoading(index: Int, count: Int)
    case didFinishLoading
}
