//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol ActionPublisher: AnyObject {
    func publish(_ action: Action, for store: AnyObject)
}
