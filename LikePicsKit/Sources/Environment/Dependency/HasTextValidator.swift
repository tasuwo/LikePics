//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol HasTextValidator {
    var textValidator: (String?) -> Bool { get }
}
