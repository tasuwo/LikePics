//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipsListAlertPresentable: AnyObject {
    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void)
    func presentRemoveAlert(at item: UIBarButtonItem, targetCount: Int, action: @escaping () -> Void)
    func presentRemoveFromAlbumAlert(at item: UIBarButtonItem, targetCount: Int, deleteAction: @escaping () -> Void, removeFromAlbumAction: @escaping () -> Void)
    func presentHideAlert(at item: UIBarButtonItem, targetCount: Int, action: @escaping () -> Void)
}

extension ClipsListAlertPresentable where Self: UIViewController {
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

    func presentRemoveAlert(at item: UIBarButtonItem, targetCount: Int, action: @escaping () -> Void) {
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

    func presentHideAlert(at item: UIBarButtonItem, targetCount: Int, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForHideMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForHideAction(targetCount)
        alert.addAction(.init(title: title, style: .destructive, handler: { _ in
            action()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }
}
