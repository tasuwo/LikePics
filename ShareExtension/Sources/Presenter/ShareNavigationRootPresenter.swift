//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

protocol ShareNavigationViewProtocol: AnyObject {
    func show(errorMessage: String)
    func presentClipTargetSelectionView(by url: URL)
    func presentClipTargetSelectionView(by imageData: [Data])
}

class ShareNavigationRootPresenter {
    enum PresenterError: Error {
        case noContext
        case noUrlInAttachments
        case failedToResolveUrl(NSItemProviderResolutionError)
    }

    weak var view: ShareNavigationViewProtocol?
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Methods

    func resolveUrl(from context: NSExtensionContext?) {
        guard let item = context?.inputItems.first as? NSExtensionItem else {
            self.view?.show(errorMessage: L10n.errorUnknown)
            return
        }

        if let attachment = item.attachments?.first(where: { $0.isUrl }) {
            attachment.resolveUrl { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(url):
                        self?.view?.presentClipTargetSelectionView(by: url)

                    case .failure:
                        self?.view?.show(errorMessage: L10n.errorUnknown)
                    }
                }
            }
            return
        }

        if let attachments = item.attachments?.filter({ $0.isImage }) {
            let futures = attachments.map { $0.resolveImage() }
            Publishers.MergeMany(futures)
                .collect()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .failure:
                        self?.view?.show(errorMessage: L10n.errorUnknown)

                    default:
                        break
                    }
                } receiveValue: { [weak self] images in
                    self?.view?.presentClipTargetSelectionView(by: images)
                }
                .store(in: &self.subscriptions)
            return
        }

        self.view?.show(errorMessage: L10n.errorUnknown)
    }
}
