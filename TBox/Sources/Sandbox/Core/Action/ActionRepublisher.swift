//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol ActionRepublisher: AnyObject {
    @discardableResult
    func republishIfNeeded(_ action: Action, for store: AnyObject) -> Bool
}
