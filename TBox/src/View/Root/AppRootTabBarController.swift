//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class AppRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory

    init(factory: Factory) {
        self.factory = factory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let clipViewController = factory.makeClipsViewController()

        clipViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)

        self.viewControllers = [
            clipViewController
        ]
    }
}

extension AppRootTabBarController: ClipPreviewPresentingAnimatorDataSource {
    // MARK: - ClipPreviewAnimatorDataSource

    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipsCollectionViewCell? {
        return self.selectedCell()
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView, forIndex index: Int) -> CGRect {
        guard let selectedCell = self.selectedCell() else { return .zero }
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

        guard
            let viewController = self.viewControllers?.compactMap({ $0 as? ClipsViewController }).first,
            let selectedIndexPath = viewController.selectedIndexPath,
            viewController.clips.indices.contains(selectedIndexPath.row),
            viewController.clips[selectedIndexPath.row].items.indices.contains(index)
        else {
            return selectedCell.convert(selectedCell.bounds, to: containerView)
        }
        let item = viewController.clips[selectedIndexPath.row].items[index]
        let imageSize = item.thumbnail.size

        let frame = self.calcCenteredFrame(for: .init(width: imageSize.width, height: imageSize.height),
                                           on: selectedCell.bounds)

        return selectedCell.convert(frame, to: containerView)
    }

    private func selectedCell() -> ClipsCollectionViewCell? {
        guard let viewController = self.viewControllers?.compactMap({ $0 as? ClipsViewController }).first else {
            return nil
        }

        self.view.layoutIfNeeded()
        viewController.view.layoutIfNeeded()
        viewController.collectionView.layoutIfNeeded()

        guard let selectedIndexPath = viewController.selectedIndexPath else {
            return nil
        }

        if !viewController.collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
            viewController.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
            viewController.collectionView.reloadItems(at: viewController.collectionView.indexPathsForVisibleItems)

            viewController.view.layoutIfNeeded()
            viewController.collectionView.layoutIfNeeded()
        }

        guard let selectedCell = viewController.collectionView.cellForItem(at: selectedIndexPath) as? ClipsCollectionViewCell else {
            return nil
        }

        return selectedCell
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
