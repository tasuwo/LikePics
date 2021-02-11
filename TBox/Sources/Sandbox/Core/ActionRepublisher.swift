//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol ActionRepublisher: AnyObject {
    func republishIfNeeded(_ action: Action) -> Bool
}
