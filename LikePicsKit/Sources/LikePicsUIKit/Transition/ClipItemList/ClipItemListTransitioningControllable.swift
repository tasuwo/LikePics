//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemListTransitioningControllable: UIViewControllerTransitioningDelegate {
    func isLocked(by id: UUID) -> Bool
    @discardableResult
    func beginTransition(id: UUID, mode: ClipPreviewTransitionType) -> Bool
}
