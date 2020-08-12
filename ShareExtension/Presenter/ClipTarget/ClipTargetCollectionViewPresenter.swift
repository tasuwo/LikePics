//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import PromiseKit
import UIKit

protocol ClipTargetCollectionViewProtocol: AnyObject {
    func startLoading()

    func endLoading()

    func show(errorMessage: String)

    func reload()
}

class ClipTargetCollecitonViewPresenter {
    typealias SelectedWebImage = (index: Int, displayModel: DisplayedWebImage)
    typealias LoadedWebImage = (image: SelectedWebImage, data: ImageData)
    typealias ImageData = (quality: ImageQuality, url: URL, uiImage: UIImage)
    typealias LoadedClipItem = (item: ClipItem, high: ImageData, low: ImageData)
    typealias SaveData = (clip: Clip, images: [ImageData])

    enum PresenterError: Error {
        case failedToResolveUrl
        case failedToFindImages
        case failedToDownlaodImages
        case internalError
    }

    enum ImageQuality {
        case low
        case high
    }

    struct DisplayedWebImage {
        let lowQualityImageUrl: URL
        let highQualityImageUrl: URL
        let highQualityImageSize: CGSize
        let lowQualityImageSize: CGSize

        var isValid: Bool {
            return self.highQualityImageSize.height != 0
                && self.highQualityImageSize.width != 0
                && self.lowQualityImageSize.height != 0
                && self.lowQualityImageSize.width != 0
        }

        init(webImage: WebImage, highQualityImageSize: CGSize, lowQualityImageSize: CGSize) {
            self.lowQualityImageUrl = webImage.lowQuality
            self.highQualityImageUrl = webImage.highQuality
            self.lowQualityImageSize = lowQualityImageSize
            self.highQualityImageSize = highQualityImageSize
        }

        func imageUrl(for quality: ImageQuality) -> URL {
            switch quality {
            case .low:
                return self.lowQualityImageUrl
            case .high:
                return self.highQualityImageUrl
            }
        }

        func imageSize(for quality: ImageQuality) -> CGSize {
            switch quality {
            case .low:
                return self.lowQualityImageSize
            case .high:
                return self.highQualityImageSize
            }
        }
    }

    struct ComposingClipItem {
        let thumbnailImageUrl: URL?
        let thumbnailSize: ImageSize?
        let thumbnailImage: UIImage?
        let largeImageUrl: URL?
        let largeImageSize: ImageSize?
        let largeImage: UIImage?

        init(imageUrl: URL, imageSize: CGSize, imageData: UIImage, quality: ImageQuality) {
            switch quality {
            case .low:
                self.thumbnailImageUrl = imageUrl
                self.thumbnailSize = ImageSize(height: Double(imageSize.height),
                                               width: Double(imageSize.width))
                self.thumbnailImage = imageData
                self.largeImageUrl = nil
                self.largeImageSize = nil
                self.largeImage = nil
            case .high:
                self.largeImageUrl = imageUrl
                self.largeImageSize = ImageSize(height: Double(imageSize.height),
                                                width: Double(imageSize.width))
                self.largeImage = imageData
                self.thumbnailImageUrl = nil
                self.thumbnailSize = nil
                self.thumbnailImage = nil
            }
        }

        init(item: ComposingClipItem, imageUrl: URL, imageSize: CGSize, imageData: UIImage, quality: ImageQuality) {
            switch quality {
            case .low:
                self.thumbnailImageUrl = imageUrl
                self.thumbnailSize = ImageSize(height: Double(imageSize.height),
                                               width: Double(imageSize.width))
                self.thumbnailImage = imageData
                self.largeImageUrl = item.largeImageUrl
                self.largeImageSize = item.largeImageSize
                self.largeImage = item.largeImage
            case .high:
                self.largeImageUrl = imageUrl
                self.largeImageSize = ImageSize(height: Double(imageSize.height),
                                                width: Double(imageSize.width))
                self.largeImage = imageData
                self.thumbnailImageUrl = item.thumbnailImageUrl
                self.thumbnailSize = item.thumbnailSize
                self.thumbnailImage = item.thumbnailImage
            }
        }

        func toLoadedClipItem(at index: Int, inClip url: URL) -> LoadedClipItem? {
            guard let thumbnailImageUrl = self.thumbnailImageUrl,
                let thumbnailSize = self.thumbnailSize,
                let largeImageUrl = self.largeImageUrl,
                let largeImageSize = self.largeImageSize,
                let thumbnailImage = self.thumbnailImage,
                let largeImage = self.largeImage
            else {
                return nil
            }

            let item = ClipItem(clipUrl: url,
                                clipIndex: index,
                                thumbnailImageUrl: thumbnailImageUrl,
                                thumbnailSize: thumbnailSize,
                                largeImageUrl: largeImageUrl,
                                largeImageSize: largeImageSize)
            return (item, (.low, thumbnailImageUrl, thumbnailImage), (.high, largeImageUrl, largeImage))
        }
    }

    private(set) var webImages: [DisplayedWebImage] = []

    private var url: URL?

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    weak var view: ClipTargetCollectionViewProtocol?
    private let storage: ClipStorageProtocol
    private let resolver: WebImageResolverProtocol

    // MARK: - Lifecycle

    init() {
        self.storage = ClipStorage()
        self.resolver = WebImageResolver()
    }

    // MARK: - Methods

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
            self.resolveUrl(from: attachment)
        }.then(on: self.imageLoadQueue) { (url: URL) in
            self.resolveWebImages(ofUrl: url)
        }.then(on: self.imageLoadQueue) { (webImages: [WebImage]) in
            self.resolveSize(ofWebImages: webImages)
        }.done(on: .main) { [weak self] (displayedWebImages: [DisplayedWebImage]) in
            self?.webImages = displayedWebImages
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

    func saveImages(at indices: [Int], completion: @escaping (Bool) -> Void) {
        guard indices.allSatisfy({ i in self.webImages.indices.contains(i) }) else {
            self.view?.show(errorMessage: "Invalid indices selected.")
            completion(false)
            return
        }

        guard let clipUrl = self.url else {
            self.view?.show(errorMessage: "No url.")
            completion(false)
            return
        }

        self.view?.startLoading()

        // TODO: 選択順をindexに反映させる
        let numberedWebImages = self.webImages
            .enumerated()
            .filter { indices.contains($0.offset) }
            .map { $0.element }
            .reduce(into: [(Int, DisplayedWebImage)]()) { result, webImage in
                guard let previous = result.last else {
                    result.append((0, webImage))
                    return
                }
                result.append((previous.0 + 1, webImage))
            }

        firstly {
            when(fulfilled: self.loadImages(for: numberedWebImages))
        }.then(on: self.imageLoadQueue) { (results: [LoadedWebImage]) in
            self.composeSaveData(forClip: clipUrl, from: results)
        }.then(on: self.imageLoadQueue) { (saveData: SaveData) in
            self.save(target: saveData)
        }.done { [weak self] _ in
            self?.view?.endLoading()
            completion(true)
        }.catch(on: .main) { [weak self] error in
            let error: PresenterError = {
                guard let error = error as? PresenterError else { return .internalError }
                return error
            }()
            self?.view?.endLoading()
            self?.view?.show(errorMessage: Self.resolveErrorMessage(error))
            completion(false)
        }
    }

    // MARK: Load Images

    private func resolveUrl(from attachment: NSItemProvider) -> Promise<URL> {
        return Promise<URL> { [weak self] seal in
            attachment.resolveUrl { result in
                switch result {
                case let .success(url):
                    self?.url = url
                    seal.resolve(.fulfilled(url))
                case .failure:
                    seal.resolve(.rejected(PresenterError.failedToResolveUrl))
                }
            }
        }
    }

    private func resolveWebImages(ofUrl url: URL) -> Promise<[WebImage]> {
        return Promise<[WebImage]> { seal in
            self.resolver.resolveWebImages(inUrl: url) { result in
                switch result {
                case let .success(urls):
                    seal.resolve(.fulfilled(urls))
                case .failure:
                    seal.resolve(.rejected(PresenterError.failedToFindImages))
                }
            }
        }
    }

    private func resolveSize(ofWebImages webImages: [WebImage]) -> Promise<[DisplayedWebImage]> {
        return Promise<[DisplayedWebImage]> { seal in
            let validWebImages = webImages
                .map { DisplayedWebImage(webImage: $0,
                                         highQualityImageSize: self.calcImageSize(ofUrl: $0.highQuality),
                                         lowQualityImageSize: self.calcImageSize(ofUrl: $0.lowQuality)) }
                .filter { $0.isValid }
            seal.resolve(.fulfilled(validWebImages))
        }
    }

    // MARK: Save Images

    private func loadImages(for numberedWebImages: [SelectedWebImage]) -> [Promise<LoadedWebImage>] {
        return numberedWebImages
            .flatMap { [($0, ImageQuality.low), ($0, ImageQuality.high)] }
            .map { numberedWebImage, quality in
                let imageUrl = numberedWebImage.1.imageUrl(for: quality)

                return URLSession.shared.dataTask(.promise, with: imageUrl)
                    // WARN: ここで失敗したという情報は失われてしまう
                    .compactMap { UIImage(data: $0.data) }
                    .map { (numberedWebImage, (quality, imageUrl, $0)) }
            }
    }

    private func composeSaveData(forClip clipUrl: URL, from images: [LoadedWebImage]) -> Promise<SaveData> {
        return Promise<SaveData> { seal in
            let clipItems = images.reduce(into: [Int: ComposingClipItem]()) { composings, loadedWebImage in
                let index = loadedWebImage.image.index
                let displayingWebImage = loadedWebImage.image.displayModel
                let quality = loadedWebImage.data.quality
                let uiImage = loadedWebImage.data.uiImage

                if let composingItem = composings[index] {
                    composings[index] = .init(item: composingItem,
                                              imageUrl: displayingWebImage.imageUrl(for: quality),
                                              imageSize: displayingWebImage.imageSize(for: quality),
                                              imageData: uiImage,
                                              quality: quality)
                } else {
                    composings[index] = .init(imageUrl: displayingWebImage.imageUrl(for: quality),
                                              imageSize: displayingWebImage.imageSize(for: quality),
                                              imageData: uiImage,
                                              quality: quality)
                }
            }.map {
                $0.value.toLoadedClipItem(at: $0.key, inClip: clipUrl)
            }

            guard !clipItems.contains(where: { $0 == nil }) else {
                seal.resolve(.rejected(PresenterError.failedToDownlaodImages))
                return
            }

            let clip = Clip(url: clipUrl,
                            description: nil,
                            items: clipItems.compactMap { $0?.item })
            let images = clipItems
                .compactMap { $0 }
                .flatMap { [$0.high, $0.low] }

            seal.resolve(.fulfilled((clip, images)))
        }
    }

    private func save(target: SaveData) -> Promise<Void> {
        return Promise<Void> { seal in
            switch self.storage.create(clip: target.clip) {
            case .success:
                seal.resolve(.fulfilled(()))
            case let .failure(error):
                seal.resolve(.rejected(error))
            }
        }
    }

    // MARK: Util

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
            return "Failed to find images."
        case .failedToResolveUrl:
            return "Failed to resolve url."
        case .failedToDownlaodImages:
            return "Failed to donwlaod images."
        case .internalError:
            return "Failed"
        }
    }
}
