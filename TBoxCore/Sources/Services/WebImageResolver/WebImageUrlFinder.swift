//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Erik
import WebKit

/// @mockable
protocol WebImageUrlFinderProtocol {
    var webView: WKWebView { get }
    func findImageUrls(inWebSiteAt url: URL, delay milliseconds: Int, completion: @escaping (Swift.Result<[WebImageUrlSet], WebImageUrlFinderError>) -> Void)
}

class WebImageUrlFinder {
    let webView: WKWebView
    private let browser: Erik

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(browserSize: CGSize) {
        self.webView = WKWebView(frame: .init(origin: .zero, size: browserSize))
        self.browser = Erik(webView: self.webView)
    }

    convenience init() {
        self.init(browserSize: .init(width: 500, height: 1000))
    }

    // MARK: - Methods

    private func openPage(url: URL) -> Future<Document, WebImageUrlFinderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            let handler: DocumentCompletionHandler = { document, error in
                if let error = error {
                    promise(.failure(.networkError(error)))
                    return
                }

                guard let document = document else {
                    promise(.failure(.internalError))
                    return
                }

                promise(.success(document))
            }

            onMainThread(execute: {
                self.browser.visit(url: url, completionHandler: handler)
            })
        }
    }

    func checkCurrentContent(fulfilled: @escaping (Document) -> Bool) -> Future<Document, WebImageUrlFinderError> {
        return Future { promise in
            self.browser.currentContent { document, error in
                if let error = error {
                    promise(.failure(.networkError(error)))
                    return
                }

                guard let document = document else {
                    promise(.failure(.internalError))
                    return
                }

                guard fulfilled(document) else {
                    promise(.failure(.timeout))
                    return
                }

                promise(.success(document))
            }
        }
    }
}

extension WebImageUrlFinder: WebImageUrlFinderProtocol {
    // MARK: - WebImageUrlFinderProtocol

    func findImageUrls(inWebSiteAt url: URL, delay milliseconds: Int, completion: @escaping (Result<[WebImageUrlSet], WebImageUrlFinderError>) -> Void) {
        var preprocessedStep: AnyPublisher<Void, WebImageUrlFinderError>
        if let provider = WebImageProviderPreset.resolveProvider(by: url), provider.shouldPreprocess(for: url) {
            preprocessedStep = self.openPage(url: url)
                .flatMap { [weak self] document -> AnyPublisher<Void, WebImageUrlFinderError> in
                    guard let self = self else {
                        return Fail(error: WebImageUrlFinderError.internalError)
                            .eraseToAnyPublisher()
                    }
                    return provider.preprocess(self.browser, document: document)
                }
                .eraseToAnyPublisher()
        } else {
            preprocessedStep = self.openPage(url: url)
                .map({ _ in () })
                .eraseToAnyPublisher()
        }

        preprocessedStep
            .delay(for: .milliseconds(milliseconds), scheduler: RunLoop.main)
            .flatMap { _ in
                return self.checkCurrentContent(fulfilled: { !$0.querySelectorAll("img").isEmpty })
            }
            .sink(receiveCompletion: { finish in
                switch finish {
                case let .failure(error):
                    completion(.failure(error))

                case .finished:
                    break
                }
            }, receiveValue: { document in
                let imageUrls: [WebImageUrlSet] = document
                    .querySelectorAll("img")
                    .compactMap { $0["src"] }
                    .compactMap { URL(string: $0) }
                    .map {
                        guard let provider = WebImageProviderPreset.resolveProvider(by: $0) else {
                            return WebImageUrlSet(url: $0, alternativeUrl: nil)
                        }
                        return WebImageUrlSet(url: $0, alternativeUrl: provider.resolveHighQualityImageUrl(of: $0))
                    }
                completion(.success(imageUrls))
            })
            .store(in: &self.cancellableBag)
    }
}
