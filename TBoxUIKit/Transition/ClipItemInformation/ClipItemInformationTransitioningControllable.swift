//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemInformationTransitioningControllable: UIViewControllerTransitioningDelegate {
    var isInteractive: Bool { get }
    func isLocked(by id: UUID) -> Bool
    @discardableResult
    func beginTransition(id: UUID, mode: ClipItemInformationTransitionType) -> Bool
    @discardableResult
    func didPanForPresentation(id: UUID, sender: UIPanGestureRecognizer) -> Bool
    @discardableResult
    func didPanForDismissal(id: UUID, sender: UIPanGestureRecognizer) -> Bool
}
