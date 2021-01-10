//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipCollectionAlertPresentable: AnyObject {
    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void)
    func presentDeleteAlert(at item: UIBarButtonItem, targetCount: Int, action: @escaping () -> Void)
    func presentDeleteAlert(at cell: UICollectionViewCell, in collectionView: UICollectionView, action: @escaping () -> Void)
    func presentRemoveFromAlbumAlert(at item: UIBarButtonItem, targetCount: Int, deleteAction: @escaping () -> Void, removeFromAlbumAction: @escaping () -> Void)
    func presentUpdateVisibilityAlert(at item: UIBarButtonItem, targetCount: Int, hideAction: @escaping () -> Void, revealAction: @escaping () -> Void)
    func presentPurgeAlert(at cell: UICollectionViewCell, in collectionView: UICollectionView, action: @escaping () -> Void)
}

extension ClipCollectionAlertPresentable where Self: UIViewController {
    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForAddToAlbum, style: .default, handler: { _ in
            addToAlbumAction()
        }))

        alert.addAction(.init(title: L10n.clipsListAlertForAddTag, style: .default, handler: { _ in
            addTagsAction()
        }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentDeleteAlert(at item: UIBarButtonItem, targetCount: Int, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForDeleteAction(targetCount)
        alert.addAction(.init(title: title, style: .destructive, handler: { _ in
            action()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentDeleteAlert(at cell: UICollectionViewCell, in collectionView: UICollectionView, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForDeleteAction(1)
        alert.addAction(.init(title: title, style: .destructive, handler: { _ in
            action()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }

    func presentRemoveFromAlbumAlert(at item: UIBarButtonItem, targetCount: Int, deleteAction: @escaping () -> Void, removeFromAlbumAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteInAlbumMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForDeleteInAlbumActionRemoveFromAlbum, style: .destructive, handler: { _ in
            removeFromAlbumAction()
        }))
        alert.addAction(.init(title: L10n.clipsListAlertForDeleteInAlbumActionDelete, style: .destructive, handler: { _ in
            deleteAction()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentUpdateVisibilityAlert(at item: UIBarButtonItem, targetCount: Int, hideAction: @escaping () -> Void, revealAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForChangeVisibilityMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForChangeVisibilityHideAction(targetCount), style: .destructive, handler: { _ in
            hideAction()
        }))
        alert.addAction(.init(title: L10n.clipsListAlertForChangeVisibilityRevealAction(targetCount), style: .destructive, handler: { _ in
            revealAction()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentPurgeAlert(at cell: UICollectionViewCell, in collectionView: UICollectionView, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForPurgeMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForPurgeAction, style: .destructive, handler: { _ in
            action()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }
}
