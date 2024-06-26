//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import LikePicsUIKit
import UIKit

protocol ClipPreviewPresentingViewController: UIViewController {
    var previewingCellCornerRadius: CGFloat { get }
    var previewingCollectionView: UICollectionView { get }
    func previewingCell(id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipPreviewPresentableCell?
    func displayPreviewingCell(id: ClipPreviewPresentableCellIdentifier)
    var isDisplayablePrimaryThumbnailOnly: Bool { get }
}

private extension SceneRootViewController {
    func resolvePresentingViewController() -> ClipPreviewPresentingViewController? {
        guard let topViewController = currentViewController else { return nil }

        if let viewController = topViewController as? ClipPreviewPresentingViewController {
            return viewController
        }

        if let navigationController = topViewController as? UINavigationController,
           let viewController = navigationController.viewControllers.compactMap({ $0 as? ClipPreviewPresentingViewController }).last
        {
            return viewController
        }

        if let navigationController = topViewController as? UINavigationController,
           let entryViewController = navigationController.viewControllers.compactMap({ $0 as? SearchEntryViewController }).last
        {
            return entryViewController.resultsController
        }

        return nil
    }
}

// MARK: - ClipPreviewPresentable

public extension SceneRootViewController {
    func animatingCell(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipPreviewPresentableCell? {
        guard let viewController = self.resolvePresentingViewController() else { return nil }
        return viewController.previewingCell(id: id, needsScroll: needsScroll)
    }

    func animatingCellFrame(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        guard let selectedCell = viewController.previewingCell(id: id, needsScroll: needsScroll) else { return .zero }
        return viewController.previewingCollectionView.convert(selectedCell.frame, to: containerView)
    }

    func animatingCellCornerRadius(_ animator: ClipPreviewAnimator) -> CGFloat {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        return viewController.previewingCellCornerRadius
    }

    func displayAnimatingCell(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier) {
        guard let viewController = self.resolvePresentingViewController() else { return }
        viewController.displayPreviewingCell(id: id)
    }

    func thumbnailFrame(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        guard let selectedCell = viewController.previewingCell(id: id, needsScroll: needsScroll) else { return .zero }
        let imageView = selectedCell.thumbnail()
        return selectedCell.convert(imageView.frame, to: containerView)
    }

    func baseView(_ animator: ClipPreviewAnimator) -> UIView? {
        return view
    }

    func componentsOverBaseView(_ animator: ClipPreviewAnimator) -> [UIView] {
        let navigationBar = (self.currentViewController as? UINavigationController)?.navigationBar
        return ([navigationBar] as [UIView?]).compactMap { $0 }
    }

    func isDisplayablePrimaryThumbnailOnly(_ animator: ClipPreviewAnimator) -> Bool {
        guard let viewController = self.resolvePresentingViewController() else { return false }
        return viewController.isDisplayablePrimaryThumbnailOnly
    }
}
