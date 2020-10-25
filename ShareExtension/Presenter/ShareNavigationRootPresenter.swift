//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ShareNavigationViewProtocol: AnyObject {
    func show(errorMessage: String)

    func presentClipTargetSelectionView(by url: URL)
}

class ShareNavigationRootPresenter {
    enum PresenterError: Error {
        case noContext
        case noUrlInAttachments
        case failedToResolveUrl(NSItemProviderResolutionError)
    }

    weak var view: ShareNavigationViewProtocol?
    private let storage: ClipStorageProtocol

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    private static func resolveErrorMessage(_ error: PresenterError) -> String {
        switch error {
        case .noContext:
            return "Internal Error."
        case .noUrlInAttachments:
            return "No valid url found."
        case .failedToResolveUrl:
            return "No valid url found."
        }
    }

    func resolveUrl(from context: NSExtensionContext?) {
        guard let item = context?.inputItems.first as? NSExtensionItem else {
            self.view?.show(errorMessage: Self.resolveErrorMessage(.noContext))
            return
        }

        // TODO: 画像が渡ってきた場合にも対応する

        guard let attachment = item.attachments?.first(where: { $0.isUrl }) else {
            self.view?.show(errorMessage: Self.resolveErrorMessage(.noUrlInAttachments))
            return
        }

        attachment.resolveUrl { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(url):
                    self?.view?.presentClipTargetSelectionView(by: url)

                case let .failure(error):
                    self?.view?.show(errorMessage: Self.resolveErrorMessage(.failedToResolveUrl(error)))
                }
            }
        }
    }
}
