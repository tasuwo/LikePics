//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewTransitioningControllable {
    var isInteractive: Bool { get }
    func isLocked(by id: UUID) -> Bool
    @MainActor
    @discardableResult
    func beginTransition(id: UUID, mode: ClipPreviewTransitionType) -> Bool
    @MainActor
    @discardableResult
    func didPanForDismissal(id: UUID, sender: UIPanGestureRecognizer) -> Bool
}
