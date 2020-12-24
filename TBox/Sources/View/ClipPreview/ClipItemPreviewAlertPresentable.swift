//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipItemPreviewAlertPresentable: AnyObject {
    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void)
    func presentDeleteAlert(at item: UIBarButtonItem, deleteClipItemAction: (() -> Void)?, deleteClipAction: @escaping () -> Void)
    func presentHideAlert(at item: UIBarButtonItem, action: @escaping () -> Void)
    func presentShareAlert(at item: UIBarButtonItem, targetCount: Int, shareItemAction: @escaping () -> Void, shareItemsAction: @escaping () -> Void)
}

extension ClipItemPreviewAlertPresentable where Self: UIViewController {
    // MARK: - ClipItemPreviewAlertPresentable

    func presentAddAlert(at item: UIBarButtonItem, addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipItemPreviewViewAlertForAddToAlbum, style: .default, handler: { _ in
            addToAlbumAction()
        }))

        alert.addAction(.init(title: L10n.clipItemPreviewViewAlertForAddTag, style: .default, handler: { _ in
            addTagsAction()
        }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentDeleteAlert(at item: UIBarButtonItem, deleteClipItemAction: (() -> Void)?, deleteClipAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipItemPreviewViewAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        if let action = deleteClipItemAction {
            alert.addAction(.init(title: L10n.clipItemPreviewViewAlertForDeleteClipItemAction,
                                  style: .destructive,
                                  handler: { _ in action() }))
        }

        alert.addAction(.init(title: L10n.clipItemPreviewViewAlertForDeleteClipAction,
                              style: .destructive,
                              handler: { _ in deleteClipAction() }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = item

        self.present(alert, animated: true, completion: nil)
    }

    func presentHideAlert(at item: UIBarButtonItem, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipItemPreviewViewAlertForHideMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipItemPreviewViewAlertForHideAction, style: .destructive, handler: { _ in
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
