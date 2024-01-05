//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public class WebImageLoadSourceResolver {
    private static let maxDelayMs = 5000
    private static let incrementalDelayMs = 1000

    private let url: URL
    private let finder = WebImageUrlSetFinder()

    private var urlFinderDelayMs: Int = 1000
    private var subscriptions = Set<AnyCancellable>()

    #if canImport(UIKit)
    public var loadedView: PassthroughSubject<UIView, Never> = .init()
    #endif
    #if canImport(AppKit)
    public var loadedView: PassthroughSubject<NSView, Never> = .init()
    #endif

    // MARK: - Lifecycle

    public init(url: URL) {
        self.url = url

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.loadedView
            .sink { [weak self] view in
                guard let self = self else { return }
                // HACK: Add WebView to view hierarchy for loading page.
                view.addSubview(self.finder.webView)
                self.finder.webView.frame = view.frame
                self.finder.webView.isHidden = true
            }
            .store(in: &self.subscriptions)
    }
}

extension WebImageLoadSourceResolver: ImageLoadSourceResolver {
    // MARK: - ImageLoadSourceResolver

    public func resolveSources() -> Future<[ImageLoadSource], ImageLoadSourceResolverError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            self.finder.findImageUrls(inWebSiteAt: self.url, delay: self.urlFinderDelayMs) { result in
                switch result {
                case let .success(urls):
                    promise(.success(urls.map({ ImageLoadSource(urlSet: $0) })))

                case let .failure(error):
                    promise(.failure(.init(finderError: error)))
                }
            }

            if self.urlFinderDelayMs < Self.maxDelayMs {
                self.urlFinderDelayMs += Self.incrementalDelayMs
            }
        }
    }
}
