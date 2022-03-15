//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol HasTextValidator {
    var textValidator: (String?) -> Bool { get }
}
