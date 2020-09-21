//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

extension WebImageProvidingService {
    public enum Twitter: WebImageProvider {
        struct Context {
            let isInitialLoaded: Bool
            let delayBeforeRetry: DispatchTimeInterval
            let retryCounter: Int

            init() {
                self.isInitialLoaded = false
                self.delayBeforeRetry = .milliseconds(200)
                self.retryCounter = 5
            }

            init(isInitialLoaded: Bool, delayBeforeRetry: DispatchTimeInterval, retryCounter: Int) {
                self.isInitialLoaded = isInitialLoaded
                self.delayBeforeRetry = delayBeforeRetry
                self.retryCounter = retryCounter
            }

            func foundSensitiveContentsAlert() -> Self {
                return Context(isInitialLoaded: true,
                               delayBeforeRetry: .milliseconds(100),
                               retryCounter: 3)
            }

            func retryCounterDecremented() -> Self {
                return Context(isInitialLoaded: self.isInitialLoaded,
                               delayBeforeRetry: self.delayBeforeRetry,
                               retryCounter: self.retryCounter - 1)
            }
        }

        enum RecoverableError: Error {
            case timeout(Context, Document)
            case networkError(Context, Document?, Error)
            case internalError(Context, Document?)

            var context: Context {
                switch self {
                case let .timeout(context, _):
                    return context
                case let .networkError(context, _, _):
                    return context
                case let .internalError(context, _):
                    return context
                }
            }

            var document: Document? {
                switch self {
                case let .timeout(_, document):
                    return document
                case let .networkError(_, document, _):
                    return document
                case let .internalError(_, document):
                    return document
                }
            }

            var webImageProvderError: WebImageUrlFinderError {
                switch self {
                case .timeout:
                    return .timeout
                case let .networkError(_, _, error):
                    return .networkError(error)
                case .internalError:
                    return .internalError
                }
            }
        }

        private static func preprocess(_ browser: Erik, document: Document, context: Context) -> Promise<Document> {
            return Promise { seal in
                browser.currentContent { document, error in
                    var currentContext = context

                    if let error = error {
                        seal.resolve(.rejected(RecoverableError.networkError(currentContext, document, error)))
                        return
                    }

                    guard let document = document else {
                        seal.resolve(.rejected(RecoverableError.internalError(currentContext, nil)))
                        return
                    }

                    let numberOfAlerts = document.querySelectorAll("a[href=\"/settings/safety\"]").count
                    if numberOfAlerts == 0, currentContext.isInitialLoaded {
                        seal.resolve(.fulfilled(document))
                        return
                    }
                    guard numberOfAlerts > 0 else {
                        seal.resolve(.rejected(RecoverableError.timeout(currentContext, document)))
                        return
                    }

                    currentContext = currentContext.foundSensitiveContentsAlert()

                    let sensitiveContentRevealButton = document.querySelectorAll("span")
                        .filter {
                            guard let innerHtml = $0.innerHTML else { return false }
                            return innerHtml == "表示" || innerHtml == "View"
                        }
                        .first
                    guard let button = sensitiveContentRevealButton else {
                        seal.resolve(.rejected(RecoverableError.timeout(currentContext, document)))
                        return
                    }
                    button.click { _, _ in
                        if numberOfAlerts > 0 {
                            seal.resolve(.rejected(RecoverableError.timeout(currentContext, document)))
                        } else {
                            seal.resolve(.fulfilled(document))
                        }
                    }
                }
            }
        }
    }
}

extension WebImageProvidingService.Twitter {
    // MARK: - WebImageProvider

    public static func isProviding(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains("twitter") || host.contains("twimg")
    }

    public static func modifyUrlForProcessing(_ url: URL) -> URL {
        guard var components = URLComponents(string: url.absoluteString),
            let queryItems = components.queryItems
        else {
            return url
        }

        let newQueryItems: [URLQueryItem] = queryItems.filter { $0.name != "s" }
        components.queryItems = newQueryItems

        return components.url ?? url
    }

    public static func shouldPreprocess(for url: URL) -> Bool {
        return url.host?.contains("twitter") == true
    }

    public static func preprocess(_ browser: Erik, document: Document) -> Promise<Document> {
        func handle(_ document: Document, _ context: Context) -> Promise<Document> {
            return self.preprocess(browser, document: document, context: context).recover { error -> Promise<Document> in
                guard let recoverbleError = error as? RecoverableError else { throw error }

                let nextContext = recoverbleError.context.retryCounterDecremented()
                guard nextContext.retryCounter > 0 else {
                    return .value(document)
                }

                return after(nextContext.delayBeforeRetry).then {
                    handle(recoverbleError.document ?? document, nextContext)
                }
            }
        }
        return handle(document, Context())
    }

    public static func resolveLowQualityImageUrl(of url: URL) -> URL? {
        guard var components = URLComponents(string: url.absoluteString), let queryItems = components.queryItems else {
            return nil
        }

        let newQueryItems: [URLQueryItem] = queryItems
            .compactMap { queryItem in
                guard queryItem.name == "name" else { return queryItem }
                return URLQueryItem(name: "name", value: "small")
            }

        components.queryItems = newQueryItems

        return components.url
    }

    public static func resolveHighQualityImageUrl(of url: URL) -> URL? {
        guard var components = URLComponents(string: url.absoluteString), let queryItems = components.queryItems else {
            return nil
        }

        let newQueryItems: [URLQueryItem] = queryItems
            .compactMap { queryItem in
                guard queryItem.name == "name" else { return queryItem }
                return URLQueryItem(name: "name", value: "orig")
            }

        components.queryItems = newQueryItems

        return components.url
    }

    public static func shouldModifyRequest(for url: URL) -> Bool {
        return false
    }

    public static func modifyRequest(_ request: URLRequest) -> URLRequest {
        return request
    }
}
