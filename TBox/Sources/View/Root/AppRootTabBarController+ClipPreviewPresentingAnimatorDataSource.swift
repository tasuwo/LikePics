//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

extension AppRootTabBarController: ClipPreviewPresentingAnimatorDataSource {
    private func resolvePresentingViewController() -> ClipPreviewPresentingViewController? {
        guard let selectedViewController = self.selectedViewController else {
            self.logger.write(ConsoleLog(level: .error, message: "No selected ViewController found for PreviewView transition."))
            return nil
        }

        if let viewController = selectedViewController as? ClipPreviewPresentingViewController {
            return viewController
        }

        if let navigationController = selectedViewController as? UINavigationController,
            let viewController = navigationController.viewControllers.compactMap({ $0 as? ClipPreviewPresentingViewController }).first
        {
            return viewController
        }

        return nil
    }

    // MARK: - ClipPreviewAnimatorDataSource

    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipCollectionViewCell? {
        guard let viewController = self.resolvePresentingViewController() else { return nil }
        viewController.displayOnScreenPreviewingCellIfNeeded()
        return viewController.previewingCell
    }

    func baseView(_ animator: ClipPreviewAnimator) -> UIView? {
        if let navigationController = self.selectedViewController as? UINavigationController {
            return navigationController.viewControllers.last?.view
        } else {
            return self.selectedViewController?.view
        }
    }

    func componentsOverBaseView(_ animator: ClipPreviewAnimator) -> [UIView] {
        let navigationBar = (self.selectedViewController as? UINavigationController)?.navigationBar
        return ([self.tabBar, navigationBar] as [UIView?]).compactMap { $0 }
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView, forItemId itemId: ClipItem.Identity?) -> CGRect {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        guard let selectedCell = viewController.previewingCell else { return .zero }
        guard let clip = viewController.previewingClip else { return .zero }

        guard let targetItem: ClipItem = {
            guard let itemId = itemId else { return clip.items.first }
            return clip.items.first(where: { $0.id == itemId })
        }() else { return .zero }

        switch targetItem.id {
        case clip.primaryItem?.id where clip.primaryItem != nil:
            return selectedCell.convert(selectedCell.primaryImageView.frame, to: containerView)

        case clip.secondaryItem?.id where clip.secondaryItem != nil:
            return selectedCell.convert(selectedCell.secondaryImageView.frame, to: containerView)

        case clip.tertiaryItem?.id where clip.tertiaryItem != nil:
            return selectedCell.convert(selectedCell.tertiaryImageView.frame, to: containerView)

        default:
            let imageSize = targetItem.imageSize
            let frame = self.calcCenteredFrame(for: .init(width: imageSize.width, height: imageSize.height),
                                               on: selectedCell.bounds)
            return selectedCell.convert(frame, to: containerView)
        }
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
