//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Kanna
import WebKit

public class ImageSourceOnWebViewResolver {
    // MARK: - Properties

    weak var webView: WKWebView?

    // MARK: - Initializers

    public init(webView: WKWebView) {
        self.webView = webView
    }
}

extension ImageSourceOnWebViewResolver: ImageSourceResolver {
    // MARK: - ImageSourceResolver

    #if canImport(UIKit)
    public var loadedView: PassthroughSubject<UIView, Never> {
        fatalError("Not implemented.")
    }
    #endif
    #if canImport(AppKit)
    public var loadedView: PassthroughSubject<NSView, Never> {
        fatalError("Not implemented.")
    }
    #endif

    public func resolveSources() -> Future<[ImageSource], ImageSourceResolverError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            self.webView?.currentContent { result in
                guard let document = result.successValue else {
                    promise(.failure(.internalError))
                    return
                }

                let result = document.webImageUrls()
                    .map { ImageSource(urlSet: $0) }

                promise(.success(result))
            }
        }
    }
}

extension HTMLDocument {
    fileprivate func webImageUrls() -> [WebImageUrlSet] {
        return css("img", namespaces: nil)
            .compactMap { $0["src"] }
            .compactMap { URL(string: $0) }
            .map {
                guard let provider = WebImageProviderPreset.resolveProvider(by: $0) else {
                    return WebImageUrlSet(url: $0, alternativeUrl: nil)
                }
                return WebImageUrlSet(url: $0, alternativeUrl: provider.resolveHighQualityImageUrl(of: $0))
            }
    }
}

extension WKWebView {
    fileprivate enum ParseError: Error {
        case noContent
        case webViewError(Error)
        case failedToParse(Error)
    }

    fileprivate func currentContent(_ completion: @escaping (Result<HTMLDocument, ParseError>) -> Void) {
        DispatchQueue.main.async {
            self.evaluateJavaScript("document.documentElement.outerHTML.toString()") { obj, error in
                guard let html = obj as? String else {
                    completion(.failure(.noContent))
                    return
                }

                if let error = error {
                    completion(.failure(.webViewError(error)))
                    return
                }

                do {
                    try completion(.success(Kanna.HTML(html: html, encoding: .utf8)))
                } catch {
                    completion(.failure(.failedToParse(error)))
                }
            }
        }
    }
}
