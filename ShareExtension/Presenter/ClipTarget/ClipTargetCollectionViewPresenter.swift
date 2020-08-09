//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import PromiseKit
import UIKit

protocol ClipTargetCollectionViewProtocol: AnyObject {
    func startLoading()

    func endLoading()

    func show(errorMessage: String)

    func reload()
}

class ClipTargetCollecitonViewPresenter {
    enum PresenterError: Error {
        case failedToResolveUrl
        case failedToFindImages
        case internalError
    }

    private(set) var imageUrls: [URL] = [] {
        didSet {
            self.sizeCalculationQueue.sync {
                self.imageSizes = self.imageUrls.map { self.calcImageSize(ofUrl: $0) }
            }
        }
    }

    private var imageSizes: [CGSize] = []

    private let sizeCalculationQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.sizeCalculationQueue")
    private let findImageQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.findImageQueue")

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

        self.view?.startLoading()

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
        }.then(on: self.findImageQueue) { url in
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
        }.done(on: .main) { [weak self] urls in
            self?.imageUrls = urls
            self?.view?.endLoading()
            self?.view?.reload()
        }.catch(on: .main) { [weak self] error in
            let error: PresenterError = {
                guard let error = error as? PresenterError else { return .internalError }
                return error
            }()
            self?.view?.endLoading()
            self?.view?.show(errorMessage: Self.resolveErrorMessage(error))
        }
    }

    func resolveImageHeight(for width: CGFloat, at index: Int) -> CGFloat {
        guard self.imageUrls.indices.contains(index) else { return .zero }
        return self.sizeCalculationQueue.sync {
            let size = self.imageSizes[index]
            guard size != .zero else { return .zero }
            return width * (size.height / size.width)
        }
    }

    private func calcImageSize(ofUrl url: URL) -> CGSize {
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as! CGFloat
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as! CGFloat
                return .init(width: pixelWidth, height: pixelHeight)
            }
        }
        return .zero
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
