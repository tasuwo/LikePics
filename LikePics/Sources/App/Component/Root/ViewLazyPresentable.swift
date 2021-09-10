//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ViewLazyPresentable {
    func presentAfterLoad(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
}
