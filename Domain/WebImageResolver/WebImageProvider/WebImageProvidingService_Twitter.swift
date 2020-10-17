//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Erik

extension WebImageProvidingService {
    public enum Twitter: WebImageProvider {
        struct Context {
            struct DisplayElement {
                let existsImages: Bool
                let numberOfSensitiveContents: Int
                let sensitiveContentRevealButton: Element?
            }

            let existsSensitiveContents: Bool
            let displayElement: DisplayElement

            var readyToReveal: Bool {
                return self.displayElement.numberOfSensitiveContents > 0
                    && self.displayElement.sensitiveContentRevealButton != nil
            }
        }

        enum State {
            case `init`
            case initialLoading(limits: Int)
            case revealing(limits: Int)
            case loadingForReveal(limits: Int)
            case finish
            case timeout

            var isEnd: Bool {
                switch self {
                case .finish, .timeout:
                    return true

                default:
                    return false
                }
            }
        }

        enum StateMachine {
            static func start(on browser: Erik) -> AnyPublisher<Void, WebImageUrlFinderError> {
                return self.transition(browser, from: .`init`, withContext: nil)
            }

            static func transition(_ browser: Erik, from state: State, withContext context: Context?) -> AnyPublisher<Void, WebImageUrlFinderError> {
                return Self.currentContext(browser, withState: state, previousContext: context)
                    .flatMap { context -> AnyPublisher<(State, Context), WebImageUrlFinderError> in
                        guard let nextState = self.nextState(from: state, withContext: context) else {
                            return Fail(error: WebImageUrlFinderError.internalError)
                                .eraseToAnyPublisher()
                        }

                        RootLogger.shared.write(ConsoleLog(level: .debug, message: "Twitter WebImage loading. Transition: \(state.label) => \(nextState.label)"))

                        switch nextState {
                        case .`init`:
                            return Fail(error: WebImageUrlFinderError.internalError)
                                .eraseToAnyPublisher()

                        case .initialLoading:
                            return Just((nextState, context))
                                .setFailureType(to: WebImageUrlFinderError.self)
                                .delay(for: 0.2, scheduler: RunLoop.main)
                                .eraseToAnyPublisher()

                        case .revealing:
                            guard let button = context.displayElement.sensitiveContentRevealButton else {
                                return Fail(error: WebImageUrlFinderError.internalError)
                                    .eraseToAnyPublisher()
                            }
                            button.click()
                            return Just((nextState, context))
                                .setFailureType(to: WebImageUrlFinderError.self)
                                .delay(for: 0.2, scheduler: RunLoop.main)
                                .eraseToAnyPublisher()

                        case .loadingForReveal:
                            return Just((nextState, context))
                                .setFailureType(to: WebImageUrlFinderError.self)
                                .delay(for: 0.1, scheduler: RunLoop.main)
                                .eraseToAnyPublisher()

                        case .finish, .timeout:
                            return Just((nextState, context))
                                .setFailureType(to: WebImageUrlFinderError.self)
                                .eraseToAnyPublisher()
                        }
                    }
                    .flatMap { nextState, context -> AnyPublisher<Void, WebImageUrlFinderError> in
                        return nextState.isEnd
                            ? Just(()).setFailureType(to: WebImageUrlFinderError.self).eraseToAnyPublisher()
                            : self.transition(browser, from: nextState, withContext: context)
                    }
                    .eraseToAnyPublisher()
            }

            static func currentContext(_ browser: Erik, withState state: State, previousContext: Context?) -> Future<Context, WebImageUrlFinderError> {
                return Future { promise in
                    browser.currentContent { document, error in
                        if let error = error {
                            promise(.failure(.networkError(error)))
                            return
                        }

                        guard let document = document else {
                            promise(.failure(.internalError))
                            return
                        }

                        let existsImages = !document.querySelectorAll("img").isEmpty

                        let sensitiveContentAlerts = document.querySelectorAll("a[href=\"/settings/safety\"]")
                        let sensitiveContentRevealButton = document.querySelectorAll("span")
                            .first(where: {
                                guard let innerHtml = $0.innerHTML else { return false }
                                return innerHtml == "表示" || innerHtml == "View"
                            })

                        let existsSensitiveContents: Bool = {
                            if case .initialLoading = state, !sensitiveContentAlerts.isEmpty {
                                return true
                            }
                            return previousContext?.existsSensitiveContents ?? false
                        }()

                        let displayElement = Context.DisplayElement(existsImages: existsImages,
                                                                    numberOfSensitiveContents: sensitiveContentAlerts.count,
                                                                    sensitiveContentRevealButton: sensitiveContentRevealButton)
                        let context = Context(existsSensitiveContents: existsSensitiveContents, displayElement: displayElement)

                        promise(.success(context))
                    }
                }
            }

            static func nextState(from state: State, withContext context: Context) -> State? {
                switch state {
                case .`init`:
                    return .initialLoading(limits: 10)

                case let .initialLoading(limits: count):
                    guard count - 1 > 0 else {
                        return .timeout
                    }
                    guard context.displayElement.existsImages else {
                        return .initialLoading(limits: count - 1)
                    }
                    return context.existsSensitiveContents
                        ? .revealing(limits: 10)
                        : .finish

                case let .revealing(limits: count):
                    guard context.readyToReveal else {
                        return .loadingForReveal(limits: 3)
                    }
                    guard count - 1 > 0 else {
                        return .timeout
                    }
                    return .revealing(limits: count - 1)

                case let .loadingForReveal(limits: count):
                    guard count - 1 > 0 else {
                        return .timeout
                    }
                    guard context.readyToReveal else {
                        return .loadingForReveal(limits: count - 1)
                    }
                    return .revealing(limits: 3)

                case .finish:
                    return nil

                case .timeout:
                    return nil
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

    public static func preprocess(_ browser: Erik, document: Document) -> AnyPublisher<Void, WebImageUrlFinderError> {
        return StateMachine.start(on: browser)
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

extension WebImageProvidingService.Twitter.State {
    var label: String {
        switch self {
        case .`init`:
            return "Init"

        case let .initialLoading(limits: count):
            return "InitialLoading(\(count))"

        case let .revealing(limits: count):
            return "Revealing(\(count))"

        case let .loadingForReveal(limits: count):
            return "LoadingForReveal(\(count))"

        case .finish:
            return "Finish"

        case .timeout:
            return "Timeout"
        }
    }
}
