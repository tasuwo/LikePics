//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipPreviewAlertPresentable: AnyObject {
    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void)
    func presentDeleteAlert(at item: UIBarButtonItem, deleteClipItemAction: (() -> Void)?, deleteClipAction: @escaping () -> Void)
    func presentHideAlert(at item: UIBarButtonItem, action: @escaping () -> Void)
    func presentShareAlert(at item: UIBarButtonItem, targetCount: Int, shareItemAction: @escaping () -> Void, shareItemsAction: @escaping () -> Void)
}

extension ClipPreviewAlertPresentable where Self: UIViewController {
    // MARK: - ClipPreviewAlertPresentable

    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipPreviewViewAlertForAddToAlbum, style: .default, handler: { _ in
            addToAlbumAction()
        }))

        alert.addAction(.init(title: L10n.clipPreviewViewAlertForAddTag, style: .default, handler: { _ in
            addTagsAction()
        }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentDeleteAlert(at item: UIBarButtonItem, deleteClipItemAction: (() -> Void)?, deleteClipAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipPreviewViewAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        if let action = deleteClipItemAction {
            alert.addAction(.init(title: L10n.clipPreviewViewAlertForDeleteClipItemAction,
                                  style: .destructive,
                                  handler: { _ in action() }))
        }

        alert.addAction(.init(title: L10n.clipPreviewViewAlertForDeleteClipAction,
                              style: .destructive,
                              handler: { _ in deleteClipAction() }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentHideAlert(at item: UIBarButtonItem, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipPreviewViewAlertForHideMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipPreviewViewAlertForHideAction, style: .destructive, handler: { _ in
            action()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentShareAlert(at item: UIBarButtonItem, targetCount: Int, shareItemAction: @escaping () -> Void, shareItemsAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForShareItemsAction(targetCount)
        alert.addAction(.init(title: title, style: .destructive, handler: { _ in
            shareItemsAction()
        }))
        alert.addAction(.init(title: L10n.clipsListAlertForShareItemAction, style: .destructive, handler: { _ in
            shareItemAction()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }
}
