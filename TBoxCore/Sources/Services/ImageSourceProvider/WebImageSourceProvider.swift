//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class WebImageSourceProvider {
    private static let maxDelayMs = 5000
    private static let incrementalDelayMs = 1000

    private let url: URL
    private let finder = WebImageUrlFinder()

    private var urlFinderDelayMs: Int = 0
    private var subscriptions = Set<AnyCancellable>()

    public var viewDidLoad: PassthroughSubject<UIView, Never> = .init()

    // MARK: - Lifecycle

    public init(url: URL) {
        self.url = url

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.viewDidLoad
            .sink { [weak self] view in
                guard let self = self else { return }
                // HACK: Add WebView to view hierarchy for loading page.
                view.addSubview(self.finder.webView)
                self.finder.webView.isHidden = true
            }
            .store(in: &self.subscriptions)
    }
}

extension WebImageSourceProvider: ImageSourceProvider {
    // MARK: - ImageSourceProvider

    public func resolveSources() -> Future<[ImageSource], ImageSourceProviderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            self.finder.findImageUrls(inWebSiteAt: self.url, delay: self.urlFinderDelayMs) { result in
                switch result {
                case let .success(urls):
                    promise(.success(urls.map({ ImageSource(urlSet: $0) })))

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
