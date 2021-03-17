//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol HasClipMergeModalSubscription {
    var clipMergeCompleted: (Bool) -> Void { get }
}