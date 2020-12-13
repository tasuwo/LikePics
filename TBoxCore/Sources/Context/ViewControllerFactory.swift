//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ViewControllerFactory {
    func makeTagSelectionViewController(selectedTags: Set<Tag.Identity>,
                                        delegate: TagSelectionViewControllerDelegate) -> UIViewController
}
