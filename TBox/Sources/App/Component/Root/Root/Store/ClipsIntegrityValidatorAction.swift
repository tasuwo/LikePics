//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum ClipsIntegrityValidatorAction: Action {
    case didLaunchApp
    case shareExtensionDidCompleteRequest
    case didStartLoading(at: Int, count: Int)
    case didFinishLoading
}
