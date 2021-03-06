//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

protocol ShareNavigationViewProtocol: AnyObject {
    func show(errorMessage: String)
    func presentClipTargetSelectionView(by url: URL)
    func presentClipTargetSelectionView(by providers: [ImageProvider], fileUrls: [URL])
}

class ShareNavigationRootPresenter {
    weak var view: ShareNavigationViewProtocol?
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Methods

    func resolveUrl(from context: NSExtensionContext) {
        let items = context.inputItems.compactMap { $0 as? NSExtensionItem }
        guard !items.isEmpty else {
            view?.show(errorMessage: L10n.errorUnknown)
            return
        }

        let futures = items
            .compactMap { $0.attachments }
            .flatMap { $0 }
            .map { $0.resolveImageSource() }

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
            } receiveValue: { [weak self] sources in
                if case let .webUrl(url) = sources.first(where: { $0?.isWebUrl == true }) {
                    self?.view?.presentClipTargetSelectionView(by: url)
                } else {
                    let providers = sources.compactMap { $0?.imageProvider }
                    let fileUrls = sources.compactMap { $0?.fileUrl }

                    if providers.isEmpty, fileUrls.isEmpty {
                        self?.view?.show(errorMessage: L10n.errorUnknown)
                        return
                    }

                    self?.view?.presentClipTargetSelectionView(by: providers, fileUrls: fileUrls)
                }
            }
            .store(in: &subscriptions)
    }
}
