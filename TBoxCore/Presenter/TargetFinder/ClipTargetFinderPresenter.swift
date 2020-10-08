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

typealias OrderedImageMeta = (index: Int, meta: DisplayableImageMeta)
typealias OrderedImageData = (index: Int, data: FetchedImageData)

public class ClipTargetFinderPresenter {
    enum PresenterError: Error {
        case failedToFindImages(WebImageUrlFinderError)
        case failedToDownloadImages
        case failedToSave(ClipStorageError)
        case internalError
    }

    private(set) var imageMetas: [DisplayableImageMeta] = [] {
        didSet {
            self.selectedIndices = []
            self.view?.resetSelection()
        }
    }

    private(set) var selectedIndices: [Int] = [] {
        didSet {
            DispatchQueue.main.async {
                self.view?.updateDoneButton(isEnabled: !self.selectedIndices.isEmpty)
            }
        }
    }

    private var isEnabledOverwrite: Bool

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    weak var view: ClipTargetFinderViewProtocol?

    private let url: URL
    private let storage: ClipStorageProtocol
    private let finder: WebImageUrlFinderProtocol
    private let currentDateResolver: () -> Date
    private let urlSession: URLSession

    // MARK: - Lifecycle

    public init(url: URL,
                storage: ClipStorageProtocol,
                finder: WebImageUrlFinderProtocol,
                currentDateResolver: @escaping () -> Date,
                isEnabledOverwrite: Bool = false,
                urlSession: URLSession = URLSession.shared)
    {
        self.url = url
        self.storage = storage
        self.finder = finder
        self.currentDateResolver = currentDateResolver
        self.isEnabledOverwrite = isEnabledOverwrite
        self.urlSession = urlSession
    }

    // MARK: - Methods

    // MARK: Util

    private static func resolveErrorMessage(_ error: PresenterError) -> String {
        switch error {
        case .failedToFindImages(.internalError):
            return L10n.clipTargetFinderViewErrorAlertBodyInternalError

        case .failedToFindImages(.networkError):
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToFindImagesTimeout

        case .failedToFindImages(.timeout):
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToFindImagesTimeout

        case .failedToDownloadImages:
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToDownloadImages

        case .failedToSave:
            return L10n.clipTargetFinderViewErrorAlertBodyFailedToSaveImages

        case .internalError:
            return L10n.clipTargetFinderViewErrorAlertBodyInternalError
        }
    }

    // MARK: Internal

    func attachWebView(to view: UIView) {
        // HACK: Add WebView to view hierarchy for loading page.
        view.addSubview(self.finder.webView)
        self.finder.webView.isHidden = true
    }

    func enableOverwrite() {
        self.isEnabledOverwrite = true
    }

    func findImages() {
        if !self.isEnabledOverwrite, case .success = self.storage.readClip(having: self.url) {
            self.view?.showConfirmationForOverwrite()
            return
        }

        if !self.imageMetas.isEmpty {
            self.imageMetas = []
            self.view?.reloadList()
        }

        self.view?.startLoading()

        firstly {
            self.resolveWebImages(ofUrl: self.url)
        }
        .then(on: self.imageLoadQueue) { (webImages: [WebImageUrlSet]) in
            self.resolveSize(ofWebImages: webImages)
        }
        .done(on: .main) { [weak self] (fetchedWebImages: [DisplayableImageMeta]) in
            self?.imageMetas = fetchedWebImages
            self?.view?.endLoading()
            self?.view?.reloadList()
        }
        .catch(on: .main) { [weak self] error in
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

        let selections: [OrderedImageMeta] = self.selectedIndices.enumerated()
            .map { ($0.offset, self.imageMetas[$0.element]) }

        firstly {
            when(fulfilled: self.fetchImageData(for: selections, using: self.urlSession))
        }
        .then(on: self.imageLoadQueue) { (results: [OrderedImageData]) in
            self.buildSaveData(forClip: self.url, from: results)
        }
        .then(on: self.imageLoadQueue) { (saveData: [ImageDataSet]) in
            self.save(target: saveData)
        }
        .done { [weak self] _ in
            self?.view?.endLoading()
            self?.view?.notifySavedImagesSuccessfully()
        }
        .catch(on: .main) { [weak self] error in
            let error: PresenterError = {
                guard let error = error as? PresenterError else { return .internalError }
                return error
            }()
            self?.view?.endLoading()
            self?.view?.show(errorMessage: Self.resolveErrorMessage(error))
        }
    }

    func selectItem(at index: Int) {
        guard self.imageMetas.indices.contains(index) else { return }

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
            self.finder.findImageUrls(inWebSiteAt: url) { result in
                switch result {
                case let .success(urls):
                    seal.resolve(.fulfilled(urls))

                case let .failure(error):
                    seal.resolve(.rejected(PresenterError.failedToFindImages(error)))
                }
            }
        }
    }

    private func resolveSize(ofWebImages webImages: [WebImageUrlSet]) -> Promise<[DisplayableImageMeta]> {
        return Promise<[DisplayableImageMeta]> { seal in
            let validWebImages = webImages
                .map { DisplayableImageMeta(urlSet: $0) }
                .filter { $0.isValid }
            seal.resolve(.fulfilled(validWebImages))
        }
    }

    // MARK: Save Images

    private func fetchImageData(for metas: [OrderedImageMeta], using session: URLSession) -> [Promise<OrderedImageData>] {
        return metas
            .flatMap { meta -> [(OrderedImageMeta, ImageQuality)] in
                [(meta, .original), (meta, .thumbnail)]
            }
            .compactMap { orderedMeta, quality in
                switch quality {
                case .original:
                    let imageUrl = orderedMeta.meta.imageUrl
                    return session.dataTask(.promise, with: imageUrl)
                        .map {
                            FetchedImageData(url: imageUrl,
                                             data: $0,
                                             mimeType: $1.mimeType,
                                             quality: quality,
                                             imageHeight: Double(orderedMeta.meta.imageSize.height),
                                             imageWidth: Double(orderedMeta.meta.imageSize.width))
                        }
                        .map { (orderedMeta.index, $0) }

                case .thumbnail:
                    guard let imageUrl = orderedMeta.meta.thumbImageUrl else { return nil }
                    return session.dataTask(.promise, with: imageUrl)
                        .map {
                            FetchedImageData(url: imageUrl,
                                             data: $0,
                                             mimeType: $1.mimeType,
                                             quality: quality,
                                             imageHeight: Double(orderedMeta.meta.imageSize.height),
                                             imageWidth: Double(orderedMeta.meta.imageSize.width))
                        }
                        .map { (orderedMeta.index, $0) }
                }
            }
    }

    private func buildSaveData(forClip clipUrl: URL, from images: [OrderedImageData]) -> Promise<[ImageDataSet]> {
        return Promise<[ImageDataSet]> { seal in
            do {
                let imageDataSets = try images
                    .reduce(into: [Int: ComposingFetchedImageDataSet]()) { result, orderedImage in
                        if let dataSet = result[orderedImage.index] {
                            result[orderedImage.index] = dataSet.setting(data: orderedImage.data)
                        } else {
                            result[orderedImage.index] = ComposingFetchedImageDataSet(data: orderedImage.data)
                        }
                    }
                    .map {
                        guard let original = $0.value.original else {
                            throw PresenterError.failedToDownloadImages
                        }
                        return FetchedImageDataSet(index: $0.key,
                                                   imageHeight: original.imageHeight,
                                                   imageWidth: original.imageWidth,
                                                   original: original,
                                                   thumbnail: $0.value.thumbnail)
                    }
                    .map { ImageDataSet(dataSet: $0) }
                seal.resolve(.fulfilled(imageDataSets))
            } catch {
                seal.resolve(.rejected(error))
            }
        }
    }

    private func save(target: [ImageDataSet]) -> Promise<Void> {
        return Promise<Void> { [weak self] seal in
            guard let self = self else {
                seal.reject(PresenterError.internalError)
                return
            }

            let currentDate = self.currentDateResolver()
            let items = target.map { ClipItem(clipUrl: self.url, dataSet: $0, currentDate: currentDate) }
            let clip = Clip(url: self.url, clipItems: items, currentDate: currentDate)

            let data = target.flatMap {
                [
                    ($0.originalImageFileName, $0.originalImageData),
                    ($0.thumbnailFileName, $0.thumbnailData)
                ]
            }

            switch self.storage.create(clip: clip, withData: data, forced: self.isEnabledOverwrite) {
            case .success:
                seal.resolve(.fulfilled(()))

            case let .failure(error):
                seal.resolve(.rejected(PresenterError.failedToSave(error)))
            }
        }
    }
}

extension ClipItem {
    init(clipUrl: URL, dataSet: ImageDataSet, currentDate: Date) {
        self.init(clipUrl: clipUrl,
                  clipIndex: dataSet.index,
                  thumbnailFileName: dataSet.thumbnailFileName,
                  thumbnailUrl: dataSet.thumbnailUrl,
                  thumbnailSize: ImageSize(height: dataSet.imageHeight, width: dataSet.imageWidth),
                  imageFileName: dataSet.originalImageFileName,
                  imageUrl: dataSet.originalImageUrl,
                  registeredDate: currentDate,
                  updatedDate: currentDate)
    }
}

extension Clip {
    init(url: URL, clipItems: [ClipItem], currentDate: Date) {
        self.init(url: url,
                  description: nil,
                  items: clipItems,
                  tags: [],
                  isHidden: false,
                  registeredDate: currentDate,
                  updatedDate: currentDate)
    }
}
