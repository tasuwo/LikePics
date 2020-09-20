//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import PromiseKit
import UIKit

protocol ClipTargetFinderViewProtocol: AnyObject {
    func startLoading()

    func endLoading()

    func reloadList()

    func showConfirmationForOverwrite()

    func show(errorMessage: String)

    func updateSelectionOrder(at index: Int, to order: Int)

    func updateDoneButton(isEnabled: Bool)

    func resetSelection()

    func notifySavedImagesSuccessfully()
}

typealias SelectedWebImage = (index: Int, displayModel: FetchedWebImage)
typealias LoadedWebImage = (image: SelectedWebImage, data: ImageData)
typealias ImageData = (quality: ImageQuality, url: URL, uiImage: UIImage)
typealias LoadedClipItem = (item: ClipItem, high: ImageData, low: ImageData)
typealias SaveData = (clip: Clip, images: [ImageData])

public class ClipTargetFinderPresenter {
    enum PresenterError: Error {
        case failedToFindImages(WebImageResolverError)
        case failedToDownlaodImages
        case failedToSave(ClipStorageError)
        case internalError
    }

    private(set) var webImages: [FetchedWebImage] = [] {
        didSet {
            self.selectedIndices = []
            self.view?.resetSelection()
        }
    }

    private(set) var selectedIndices: [Int] = [] {
        didSet {
            DispatchQueue.main.async {
                self.view?.updateDoneButton(isEnabled: self.selectedIndices.count > 0)
            }
        }
    }

    private var isEnabledOverwrite: Bool

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    weak var view: ClipTargetFinderViewProtocol?

    private let url: URL
    private let storage: ClipStorageProtocol
    private let resolver: WebImageResolverProtocol
    private let currentDateResolver: () -> Date

    // MARK: - Lifecycle

    public init(url: URL, storage: ClipStorageProtocol, resolver: WebImageResolverProtocol, currentDateResovler: @escaping () -> Date, isEnabledOverwrite: Bool = false) {
        self.url = url
        self.storage = storage
        self.resolver = resolver
        self.currentDateResolver = currentDateResovler
        self.isEnabledOverwrite = isEnabledOverwrite
    }

    // MARK: - Methods

    func attachWebView(to view: UIView) {
        // HACK: Add WebView to view hierarchy for loading page.
        view.addSubview(self.resolver.webView)
        self.resolver.webView.isHidden = true
    }

    func enableOverwrite() {
        self.isEnabledOverwrite = true
    }

    func findImages() {
        if !self.isEnabledOverwrite, case .success(_) = self.storage.readClip(having: self.url) {
            self.view?.showConfirmationForOverwrite()
            return
        }

        self.view?.startLoading()

        firstly {
            self.resolveWebImages(ofUrl: self.url)
        }.then(on: self.imageLoadQueue) { (webImages: [WebImageUrlSet]) in
            self.resolveSize(ofWebImages: webImages)
        }.done(on: .main) { [weak self] (fetchedWebImages: [FetchedWebImage]) in
            self?.webImages = fetchedWebImages
            self?.view?.endLoading()
            self?.view?.reloadList()
        }.catch(on: .main) { [weak self] error in
            let error: PresenterError = {
                guard let error = error as? PresenterError else { return .internalError }
                return error
            }()
            self?.view?.endLoading()
            self?.view?.show(errorMessage: Self.resolveErrorMessage(error))
        }
    }

    func saveSelectedImages() {
        self.view?.startLoading()

        let selections: [SelectedWebImage] = self.selectedIndices.enumerated()
            .map { ($0.offset, self.webImages[$0.element]) }

        firstly {
            when(fulfilled: self.loadImages(for: selections))
        }.then(on: self.imageLoadQueue) { (results: [LoadedWebImage]) in
            self.composeSaveData(forClip: self.url, from: results)
        }.then(on: self.imageLoadQueue) { (saveData: SaveData) in
            self.save(target: saveData)
        }.done { [weak self] _ in
            self?.view?.endLoading()
            self?.view?.notifySavedImagesSuccessfully()
        }.catch(on: .main) { [weak self] error in
            let error: PresenterError = {
                guard let error = error as? PresenterError else { return .internalError }
                return error
            }()
            self?.view?.endLoading()
            self?.view?.show(errorMessage: Self.resolveErrorMessage(error))
        }
    }

    func selectItem(at index: Int) {
        guard self.webImages.indices.contains(index) else { return }

        let indexInSelection = self.selectedIndices.count + 1
        self.selectedIndices.append(index)

        self.view?.updateSelectionOrder(at: index, to: indexInSelection)
    }

    func deselectItem(at index: Int) {
        guard let removeAt = self.selectedIndices.firstIndex(of: index) else { return }

        self.selectedIndices.remove(at: removeAt)

        zip(self.selectedIndices.indices, self.selectedIndices)
            .filter { indexInSelection, _ in indexInSelection >= removeAt }
            .forEach { indexInSelection, indexInCollection in
                self.view?.updateSelectionOrder(at: indexInCollection, to: indexInSelection + 1)
            }
    }

    // MARK: Load Images

    private func resolveWebImages(ofUrl url: URL) -> Promise<[WebImageUrlSet]> {
        return Promise<[WebImageUrlSet]> { seal in
            self.resolver.resolveWebImages(inUrl: url) { result in
                switch result {
                case let .success(urls):
                    seal.resolve(.fulfilled(urls))
                case let .failure(error):
                    seal.resolve(.rejected(PresenterError.failedToFindImages(error)))
                }
            }
        }
    }

    private func resolveSize(ofWebImages webImages: [WebImageUrlSet]) -> Promise<[FetchedWebImage]> {
        return Promise<[FetchedWebImage]> { seal in
            let validWebImages = webImages
                .map { FetchedWebImage(webImage: $0,
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
        return Promise<SaveData> { [weak self] seal in
            guard let self = self else {
                seal.resolve(.rejected(PresenterError.internalError))
                return
            }

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
                $0.value.toLoadedClipItem(at: $0.key, inClip: clipUrl, currentDate: self.currentDateResolver())
            }

            guard !clipItems.contains(where: { $0 == nil }) else {
                seal.resolve(.rejected(PresenterError.failedToDownlaodImages))
                return
            }

            let clip = Clip(url: clipUrl,
                            description: nil,
                            items: clipItems.compactMap { $0?.item },
                            tags: [],
                            isHidden: false,
                            registeredDate: self.currentDateResolver(),
                            updatedDate: self.currentDateResolver())
            let images = clipItems
                .compactMap { $0 }
                .flatMap { $0.high.url != $0.low.url ? [$0.high, $0.low] : [$0.high] }

            seal.resolve(.fulfilled((clip, images)))
        }
    }

    private func save(target: SaveData) -> Promise<Void> {
        return Promise<Void> { seal in
            let data = target.images.map { ($0.url, $0.uiImage.pngData()!) }
            switch self.storage.create(clip: target.clip, withData: data, forced: self.isEnabledOverwrite) {
            case .success:
                seal.resolve(.fulfilled(()))
            case let .failure(error):
                seal.resolve(.rejected(PresenterError.failedToSave(error)))
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
        case .failedToFindImages(.internalError):
            return L10n.clipTargetFinderViewErrorAlertBodyInternalError
        case .failedToFindImages(.networkError(_)):
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToFindImagesTimeout
        case .failedToFindImages(.timeout):
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToFindImagesTimeout
        case .failedToDownlaodImages:
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToDownloadImages
        case .failedToSave:
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToSaveImages
        case .internalError:
            return L10n.clipTargetFinderViewErrorAlertBodyInternalError
        }
    }
}
