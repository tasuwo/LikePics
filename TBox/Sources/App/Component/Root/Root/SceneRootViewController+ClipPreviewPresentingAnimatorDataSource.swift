//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

protocol ClipPreviewPresentingViewController: UIViewController {
    var previewingCellCornerRadius: CGFloat { get }
    var previewingCollectionView: UICollectionView { get }
    func previewingCell(for clipId: Clip.Identity) -> ClipPreviewPresentingCell?
    func displayPreviewingCell(for clipId: Clip.Identity)
}

private extension SceneRootViewController {
    func resolvePresentingViewController() -> ClipPreviewPresentingViewController? {
        guard let topViewController = currentViewController else { return nil }

        if let viewController = topViewController as? ClipPreviewPresentingViewController {
            return viewController
        }

        if let navigationController = topViewController as? UINavigationController,
           let viewController = navigationController.viewControllers.compactMap({ $0 as? ClipPreviewPresentingViewController }).first
        {
            return viewController
        }

        if let navigationController = topViewController as? UINavigationController,
           let entryViewController = navigationController.viewControllers.compactMap({ $0 as? SearchEntryViewController }).first
        {
            return entryViewController.resultsController
        }

        return nil
    }
}

// MARK: - ClipPreviewPresentingAnimatorDataSource

extension SceneRootViewController where Self: UIViewController {
    func animatingCell(_ animator: ClipPreviewAnimator, clipId: Clip.Identity) -> ClipPreviewPresentingCell? {
        guard let viewController = self.resolvePresentingViewController() else { return nil }
        return viewController.previewingCell(for: clipId)
    }

    func animatingCellFrame(_ animator: ClipPreviewAnimator, clipId: Clip.Identity, on containerView: UIView) -> CGRect {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        guard let selectedCell = viewController.previewingCell(for: clipId) else { return .zero }
        return viewController.previewingCollectionView.convert(selectedCell.frame, to: containerView)
    }

    func animatingCellCornerRadius(_ animator: ClipPreviewAnimator) -> CGFloat {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        return viewController.previewingCellCornerRadius
    }

    func displayAnimatingCell(_ animator: ClipPreviewAnimator, clipId: Clip.Identity) {
        guard let viewController = self.resolvePresentingViewController() else { return }
        viewController.displayPreviewingCell(for: clipId)
    }

    func primaryThumbnailFrame(_ animator: ClipPreviewAnimator, clipId: Clip.Identity, on containerView: UIView) -> CGRect {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        guard let selectedCell = viewController.previewingCell(for: clipId) else { return .zero }
        let imageView = selectedCell.primaryThumbnailImageView()
        return selectedCell.convert(imageView.frame, to: containerView)
    }

    func baseView(_ animator: ClipPreviewAnimator) -> UIView? {
        return view
    }

    func componentsOverBaseView(_ animator: ClipPreviewAnimator) -> [UIView] {
        let navigationBar = (self.currentViewController as? UINavigationController)?.navigationBar
        return ([navigationBar] as [UIView?]).compactMap { $0 }
    }

    private func calcCenteredFrame(for size: CGSize, on frame: CGRect) -> CGRect {
        let widthScale = frame.width / size.width
        let heightScale = frame.height / size.height
        let scale = min(widthScale, heightScale)

        let originX = (frame.width - (size.width * scale)) / 2
        let originY = (frame.height - (size.height * scale)) / 2

        return .init(x: originX + frame.origin.x,
                     y: originY + frame.origin.y,
                     width: size.width * scale,
                     height: size.height * scale)
    }
}
