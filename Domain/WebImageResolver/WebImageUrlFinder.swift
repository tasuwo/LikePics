//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit
import WebKit

public struct WebImageUrlSet {
    public let url: URL
    public let lowQualityUrl: URL?
}

public protocol WebImageUrlFinderProtocol {
    var webView: WKWebView { get }
    func findImageUrls(inWebSiteAt url: URL, completion: @escaping (Swift.Result<[WebImageUrlSet], WebImageUrlFinderError>) -> Void)
}

public class WebImageUrlFinder {
    private static let maxRetryCount = 5
    private static let delayAtRetry: DispatchTimeInterval = .milliseconds(200)

    public let webView: WKWebView
    private let browser: Erik

    // MARK: - Lifecycle

    public init(browserSize: CGSize) {
        self.webView = WKWebView(frame: .init(origin: .zero, size: browserSize))
        self.browser = Erik(webView: self.webView)
    }

    public convenience init() {
        self.init(browserSize: .init(width: 500, height: 1000))
    }

    // MARK: - Methods

    private func openPage(url: URL) -> Promise<Document> {
        return Promise { [weak self] seal in
            guard let self = self else {
                seal.resolve(.rejected(WebImageUrlFinderError.internalError))
                return
            }

            let handler: DocumentCompletionHandler = { document, error in
                if let error = error {
                    seal.resolve(.rejected(WebImageUrlFinderError.networkError(error)))
                    return
                }

                guard let document = document else {
                    seal.resolve(.rejected(WebImageUrlFinderError.internalError))
                    return
                }

                seal.resolve(.fulfilled(document))
            }

            onMainThread(execute: {
                self.browser.visit(url: url, completionHandler: handler)
            })
        }
    }

    func checkCurrentContent(fulfilled: @escaping (Document) -> Bool) -> Promise<Document> {
        return Promise { seal in
            self.browser.currentContent { document, error in
                if let error = error {
                    seal.resolve(.rejected(WebImageUrlFinderError.networkError(error)))
                    return
                }

                guard let document = document else {
                    seal.resolve(.rejected(WebImageUrlFinderError.internalError))
                    return
                }

                guard fulfilled(document) else {
                    seal.resolve(.rejected(WebImageUrlFinderError.timeout))
                    return
                }

                seal.resolve(.fulfilled(document))
            }
        }
    }
}

extension WebImageUrlFinder: WebImageUrlFinderProtocol {
    // MARK: - WebImageUrlFinderProtocol

    public func findImageUrls(inWebSiteAt url: URL, completion: @escaping (Swift.Result<[WebImageUrlSet], WebImageUrlFinderError>) -> Void) {
        var preprocessedStep: Promise<Document>
        if let provider = WebImageProviderPreset.resolveProvider(by: url), provider.shouldPreprocess(for: url) {
            preprocessedStep = firstly {
                self.openPage(url: provider.modifyUrlForProcessing(url))
            }.then { document in
                provider.preprocess(self.browser, document: document)
            }
        } else {
            preprocessedStep = firstly {
                self.openPage(url: url)
            }
        }

        preprocessedStep.then { document in
            attempt(maximumRetryCount: Self.maxRetryCount, delayBeforeRetry: Self.delayAtRetry) {
                self.checkCurrentContent(fulfilled: { $0.querySelectorAll("img").count > 0 })
            }
        }.done { document in
            let imageUrls: [WebImageUrlSet] = document
                .querySelectorAll("img")
                .compactMap { $0["src"] }
                .compactMap { URL(string: $0) }
                .map {
                    guard let provider = WebImageProviderPreset.resolveProvider(by: $0) else {
                        return WebImageUrlSet(url: $0, lowQualityUrl: nil)
                    }
                    return WebImageUrlSet(url: provider.resolveHighQualityImageUrl(of: $0) ?? $0,
                                          lowQualityUrl: provider.resolveLowQualityImageUrl(of: $0))
                }
            completion(.success(imageUrls))
        }.catch { error in
            guard let error = error as? WebImageUrlFinderError else {
                completion(.failure(.internalError))
                return
            }
            completion(.failure(error))
        }
    }
}
