//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Combine
import Domain
import ShareExtensionFeatureCore
import UIKit

protocol ShareNavigationViewProtocol: AnyObject {
    func show(errorMessage: String)
    func presentClipTargetSelectionView(forWebPageURL url: URL)
    func presentClipTargetSelectionView(data: [LazyImageData], fileURLs: [URL])
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

        Task { @MainActor [view] in
            do {
                let sources = try await withThrowingTaskGroup(of: SharedImageSource?.self) { group in
                    for attachment in items.compactMap({ $0.attachments }).flatMap({ $0 }) {
                        group.addTask {
                            try await attachment.imageSource()
                        }
                    }

                    var results: [SharedImageSource?] = []
                    for try await imageSource in group {
                        results.append(imageSource)
                    }

                    return results
                }.compactMap({ $0 })

                if case let .webPageURL(url) = sources.first(where: { $0.isWebPageURL == true }) {
                    view?.presentClipTargetSelectionView(forWebPageURL: url)
                } else {
                    let data = sources.compactMap { $0.data }
                    let fileUrls = sources.compactMap { $0.fileURL }

                    if data.isEmpty, fileUrls.isEmpty {
                        view?.show(errorMessage: L10n.errorUnknown)
                        return
                    }

                    view?.presentClipTargetSelectionView(data: data, fileURLs: fileUrls)
                }
            } catch {
                view?.show(errorMessage: L10n.errorUnknown)
            }
        }
    }
}
