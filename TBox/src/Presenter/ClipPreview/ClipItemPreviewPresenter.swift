//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipItemPreviewViewProtocol: AnyObject {
    func showConfirmationForDelete(options: [ClipItemPreviewPresenter.RemoveTarget], completion: @escaping (ClipItemPreviewPresenter.RemoveTarget?) -> Void)

    func showErrorMessage(_ message: String)

    func showSucceededMessage()

    func reloadPages()

    func closePages()
}

class ClipItemPreviewPresenter {
    enum FailureContext {
        case readImage
        case delete(RemoveTarget)
    }

    enum RemoveTarget {
        case clip
        case item
    }

    let clip: Clip
    let item: ClipItem

    weak var view: ClipItemPreviewViewProtocol?
    private let storage: ClipStorageProtocol

    // MARK: - Lifecyle

    init(clip: Clip, item: ClipItem, storage: ClipStorageProtocol) {
        self.clip = clip
        self.item = item
        self.storage = storage
    }

    // MARK: - Methods

    private static func resolveErrorMessage(error: ClipStorageError, context: FailureContext) -> String {
        switch (error, context) {
        case (_, .readImage):
            return L10n.clipItemPreviewViewErrorAtReadImage

        case (_, .delete(.clip)):
            return L10n.clipItemPreviewViewErrorAtDeleteClip

        case (_, .delete(.item)):
            return L10n.clipItemPreviewViewErrorAtDeleteClipItem
        }
    }

    func loadImageData() -> Data? {
        switch self.storage.readImageData(having: self.item.image.url, forClipHaving: self.item.clipUrl) {
        case let .success(data):
            return data

        case let .failure(error):
            self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .readImage))
            return nil
        }
    }

    func didTapRemove() {
        let options: [RemoveTarget] = {
            if self.clip.items.count > 1 {
                return [.item, .clip]
            } else {
                return [.clip]
            }
        }()

        self.view?.showConfirmationForDelete(options: options) { [weak self] target in
            guard let self = self, let target = target else { return }

            switch target {
            case .clip:
                switch self.storage.delete(self.clip) {
                case .success:
                    self.view?.showSucceededMessage()
                    self.view?.closePages()

                case let .failure(error):
                    self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .delete(.clip)))
                }

            case .item:
                switch self.storage.delete(self.item) {
                case .success:
                    self.view?.showSucceededMessage()
                    self.view?.reloadPages()

                case let .failure(error):
                    self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .delete(.item)))
                }
            }
        }
    }
}
