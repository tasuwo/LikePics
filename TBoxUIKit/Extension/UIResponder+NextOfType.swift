//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UIResponder {
    func next<T: UIResponder>(ofType: T.Type) -> T? {
        let responder = self.next
        if let responder = responder as? T ?? responder?.next(ofType: T.self) {
            return responder
        } else {
            return nil
        }
    }
}
