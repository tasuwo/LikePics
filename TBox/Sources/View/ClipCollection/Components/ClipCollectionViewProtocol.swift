//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipCollectionViewProtocol: AnyObject {
    var navigationItem: UINavigationItem { get }
    var navigationController: UINavigationController? { get }
    func setToolbarItems(_ toolbarItems: [UIBarButtonItem]?, animated: Bool)
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}
