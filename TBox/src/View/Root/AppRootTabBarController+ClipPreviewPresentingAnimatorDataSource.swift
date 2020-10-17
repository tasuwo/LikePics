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

    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipsCollectionViewCell? {
        guard let viewController = self.resolvePresentingViewController() else { return nil }
        viewController.displayOnScreenPreviewingCellIfNeeded()
        return viewController.previewingCell
    }

    func presentingView(_ animator: ClipPreviewAnimator) -> UIView? {
        return self.selectedViewController?.view
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView, forIndex index: Int) -> CGRect {
        guard let viewController = self.resolvePresentingViewController() else { return .zero }
        guard let selectedCell = viewController.previewingCell else { return .zero }
        switch index {
        case 0:
            return selectedCell.convert(selectedCell.primaryImageView.frame, to: containerView)

        case 1:
            return selectedCell.convert(selectedCell.secondaryImageView.frame, to: containerView)

        case 2:
            return selectedCell.convert(selectedCell.tertiaryImageView.frame, to: containerView)

        default:
            break
        }

        guard let clip = viewController.previewingClip, clip.items.indices.contains(index) else {
            return selectedCell.convert(selectedCell.bounds, to: containerView)
        }
        let imageSize = clip.items[index].thumbnailSize

        let frame = self.calcCenteredFrame(for: .init(width: imageSize.width, height: imageSize.height),
                                           on: selectedCell.bounds)

        return selectedCell.convert(frame, to: containerView)
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
