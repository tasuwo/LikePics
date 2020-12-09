//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipCollectionViewProtocol {
    var navigationItem: UINavigationItem { get }
    var navigationController: UINavigationController? { get }
    func setToolbarItems(_ toolbarItems: [UIBarButtonItem]?, animated: Bool)
}
