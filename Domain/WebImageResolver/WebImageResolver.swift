//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit
import WebKit

public protocol WebImageResolverProtocol {
    var webView: WKWebView { get }

    func resolveWebImages(inUrl url: URL, completion: @escaping (Swift.Result<[URL], WebImageResolverError>) -> Void)
}

public class WebImageResolver {
    private static let maxRetryCount = 3
    private static let delayAtRetry = 1

    private let preprocessors: [WebImageResolverPreprocessor] = [
        TwitterWebImageResolverPreprocessor()
    ]

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
                seal.resolve(.rejected(WebImageResolverError.internalError))
                return
            }

            let handler: DocumentCompletionHandler = { document, error in
                if let error = error {
                    seal.resolve(.rejected(WebImageResolverError.networkError(error)))
                    return
                }

                guard let document = document else {
                    seal.resolve(.rejected(WebImageResolverError.internalError))
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
                    seal.resolve(.rejected(WebImageResolverError.networkError(error)))
                    return
                }

                guard let document = document else {
                    seal.resolve(.rejected(WebImageResolverError.internalError))
                    return
                }

                guard fulfilled(document) else {
                    seal.resolve(.rejected(WebImageResolverError.timeout))
                    return
                }

                seal.resolve(.fulfilled(document))
            }
        }
    }
}

extension WebImageResolver: WebImageResolverProtocol {
    // MARK: - WebImageResolverProtocol

    public func resolveWebImages(inUrl url: URL, completion: @escaping (Swift.Result<[URL], WebImageResolverError>) -> Void) {
        let baseStep = firstly {
            self.openPage(url: url)
        }

        var preprocessedStep: Promise<Document>
        if let preprocessor = self.preprocessors.first(where: { $0.shouldPreprocess(url: url) }) {
            preprocessedStep = baseStep.then { document in
                attempt(maximumRetryCount: Self.maxRetryCount, delayBeforeRetry: .seconds(Self.delayAtRetry), ignoredBy: document) {
                    preprocessor.preprocess(self.browser, document: document)
                }
            }
        } else {
            preprocessedStep = baseStep
        }

        preprocessedStep.then { document in
            attempt(maximumRetryCount: Self.maxRetryCount, delayBeforeRetry: .seconds(Self.delayAtRetry)) {
                self.checkCurrentContent(fulfilled: { $0.querySelectorAll("img").count > 0 })
            }
        }.done { document in
            let images = document
                .querySelectorAll("img")
                .compactMap { $0["src"] }
                .compactMap { URL(string: $0) }
            completion(.success(images))
        }.catch { error in
            guard let error = error as? WebImageResolverError else {
                completion(.failure(.internalError))
                return
            }
            completion(.failure(error))
        }
    }
}
