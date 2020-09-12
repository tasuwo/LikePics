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

    private static func resolveErrorMessage(error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "Failed."
    }

    func loadImageData() -> Data? {
        switch self.storage.readImageData(having: self.item.image.url, forClipHaving: self.item.clipUrl) {
        case let .success(data):
            return data

        case let .failure(error):
            self.view?.showErrorMessage(Self.resolveErrorMessage(error: error))
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
                    self.view?.showErrorMessage(Self.resolveErrorMessage(error: error))
                }

            case .item:
                switch self.storage.delete(self.item) {
                case .success:
                    self.view?.showSucceededMessage()
                    self.view?.reloadPages()

                case let .failure(error):
                    self.view?.showErrorMessage(Self.resolveErrorMessage(error: error))
                }
            }
        }
    }
}
