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
    func presentClipTargetSelectionView(sources: [ImageSource])
}

class ShareNavigationRootPresenter {
    weak var view: ShareNavigationViewProtocol?
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Methods

    func resolveUrl(from context: NSExtensionContext) {
        Task { @MainActor [view] in
            do {
                switch try await ClipCreationInputResolver.inputs(for: context) {
                case let .webPageURL(url):
                    view?.presentClipTargetSelectionView(forWebPageURL: url)

                case let .imageSources(sources):
                    view?.presentClipTargetSelectionView(sources: sources)

                case .none:
                    view?.show(errorMessage: L10n.errorUnknown)
                }
            } catch {
                view?.show(errorMessage: L10n.errorUnknown)
            }
        }
    }
}
