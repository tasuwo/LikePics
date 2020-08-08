//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import PromiseKit
import UIKit

protocol ClipTargetCollectionViewProtocol: AnyObject {
    func show(errorMessage: String)

    func reload()
}

class ClipTargetCollecitonViewPresenter {
    enum PresenterError: Error {
        case failedToResolveUrl
        case failedToFindImages
        case internalError
    }

    private(set) var imageUrls: [URL] = []

    weak var view: ClipTargetCollectionViewProtocol?
    private let resolver: WebImageResolverProtocol

    init() {
        self.resolver = WebImageResolver()
    }

    func attachWebView(to view: UIView) {
        view.addSubview(self.resolver.webView)
        self.resolver.webView.isHidden = true
    }

    func findImages(fromItem item: NSExtensionItem) {
        guard let attachment = item.attachments?.first(where: { $0.isUrl }) else {
            self.view?.show(errorMessage: "No url found")
            return
        }

        firstly {
            return Promise<URL> { seal in
                attachment.resolveUrl { result in
                    switch result {
                    case let .success(url):
                        seal.resolve(.fulfilled(url))
                    case .failure:
                        seal.resolve(.rejected(PresenterError.failedToResolveUrl))
                    }
                }
            }
        }.then { url in
            return Promise<[URL]> { seal in
                self.resolver.resolveWebImages(inUrl: url) { result in
                    switch result {
                    case let .success(urls):
                        seal.resolve(.fulfilled(urls))
                    case .failure:
                        seal.resolve(.rejected(PresenterError.failedToFindImages))
                    }
                }
            }
        }.done { [weak self] urls in
            self?.imageUrls = urls
            self?.view?.reload()
        }.catch { [weak self] error in
            let error: PresenterError = {
                guard let error = error as? PresenterError else { return .internalError }
                return error
            }()
            self?.view?.show(errorMessage: Self.resolveErrorMessage(error))
        }
    }

    private static func resolveErrorMessage(_ error: PresenterError) -> String {
        switch error {
        case .failedToFindImages:
            return "Failed to fine images."
        case .failedToResolveUrl:
            return "Failed to resolve url."
        case .internalError:
            return "Failed"
        }
    }
}
