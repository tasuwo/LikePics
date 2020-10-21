//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
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
    private var cancellableBag = Set<AnyCancellable>()

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    weak var view: ClipTargetFinderViewProtocol?

    private let url: URL
    private let clipStorage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let finder: WebImageUrlFinderProtocol
    private let currentDateResolver: () -> Date
    private let urlSession: URLSession

    // MARK: - Lifecycle

    public init(url: URL,
                clipStorage: ClipStorageProtocol,
                queryService: ClipQueryServiceProtocol,
                finder: WebImageUrlFinderProtocol,
                currentDateResolver: @escaping () -> Date,
                isEnabledOverwrite: Bool = false,
                urlSession: URLSession = URLSession.shared)
    {
        self.url = url
        self.clipStorage = clipStorage
        self.queryService = queryService
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
        let alreadyClipped: Bool
        switch self.queryService.existsClip(havingUrl: self.url) {
        case let .success(exists):
            alreadyClipped = exists

        case let .failure(error):
            self.view?.endLoading()
            self.view?.show(errorMessage: L10n.clipTargetFinderViewErrorAlertBodyInternalError + "\n(\(error.makeErrorCode())")
            return
        }

        if !self.isEnabledOverwrite, alreadyClipped {
            self.view?.showConfirmationForOverwrite()
            return
        }

        if !self.imageMetas.isEmpty {
            self.imageMetas = []
            self.view?.reloadList()
        }

        self.view?.startLoading()

        self.resolveWebImages(ofUrl: self.url)
            .flatMap { webImages -> AnyPublisher<[DisplayableImageMeta], PresenterError> in
                return self.resolveSize(ofWebImages: webImages)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.view?.endLoading()
                    self?.view?.show(errorMessage: Self.resolveErrorMessage(error))

                case .finished:
                    break
                }
            }, receiveValue: { [weak self] fetchedWebImages in
                self?.imageMetas = fetchedWebImages
                self?.view?.endLoading()
                self?.view?.reloadList()
            })
            .store(in: &self.cancellableBag)
    }

    func saveSelectedImages() {
        self.view?.startLoading()

        let selections: [OrderedImageMeta] = self.selectedIndices.enumerated()
            .map { ($0.offset, self.imageMetas[$0.element]) }

        Publishers.MergeMany(self.fetchImageData(for: selections, using: self.urlSession))
            .collect()
            .mapError { _ in
                return PresenterError.failedToDownloadImages
            }
            .flatMap { [weak self] results -> AnyPublisher<[ImageDataSet], PresenterError> in
                guard let self = self else {
                    return Fail(error: .internalError).eraseToAnyPublisher()
                }
                return self.buildSaveData(forClip: self.url, from: results)
                    .publisher
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] imageDataSets -> AnyPublisher<Void, PresenterError> in
                guard let self = self else {
                    return Fail(error: .internalError).eraseToAnyPublisher()
                }
                return self.save(target: imageDataSets)
                    .publisher
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.view?.endLoading()
                    self?.view?.show(errorMessage: Self.resolveErrorMessage(error))

                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.view?.endLoading()
                self?.view?.notifySavedImagesSuccessfully()
            })
            .store(in: &self.cancellableBag)
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

    private func resolveWebImages(ofUrl url: URL) -> Future<[WebImageUrlSet], PresenterError> {
        return Future { promise in
            self.finder.findImageUrls(inWebSiteAt: url) { result in
                switch result {
                case let .success(urls):
                    promise(.success(urls))

                case let .failure(error):
                    promise(.failure(.failedToFindImages(error)))
                }
            }
        }
    }

    private func resolveSize(ofWebImages webImages: [WebImageUrlSet]) -> AnyPublisher<[DisplayableImageMeta], PresenterError> {
        do {
            let publishers: [AnyPublisher<DisplayableImageMeta, Never>] = try webImages
                .map { [weak self] webImage in
                    guard let self = self else { throw PresenterError.internalError }
                    return DisplayableImageMeta.make(by: webImage, using: self.urlSession)
                }
            return Publishers.MergeMany(publishers)
                .filter({ $0.isValid })
                .collect()
                .mapError { _ in PresenterError.internalError }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: PresenterError.internalError)
                .eraseToAnyPublisher()
        }
    }

    // MARK: Save Images

    private func fetchImageData(for metas: [OrderedImageMeta], using session: URLSession) -> [AnyPublisher<OrderedImageData, Error>] {
        return metas
            .flatMap { meta -> [(OrderedImageMeta, ImageQuality)] in
                [(meta, .original), (meta, .thumbnail)]
            }
            .compactMap { orderedMeta, quality in
                switch quality {
                case .original:
                    let imageUrl = orderedMeta.meta.imageUrl
                    return session
                        .dataTaskPublisher(for: imageUrl)
                        .tryMap { data, response -> FetchedImageData in
                            FetchedImageData(url: imageUrl,
                                             data: data,
                                             mimeType: response.mimeType,
                                             quality: quality,
                                             imageHeight: Double(orderedMeta.meta.imageSize.height),
                                             imageWidth: Double(orderedMeta.meta.imageSize.width))
                        }
                        .map { (orderedMeta.index, $0) }
                        .eraseToAnyPublisher()

                case .thumbnail:
                    guard let imageUrl = orderedMeta.meta.thumbImageUrl else { return nil }
                    return session
                        .dataTaskPublisher(for: imageUrl)
                        .tryMap { data, response -> FetchedImageData in
                            FetchedImageData(url: imageUrl,
                                             data: data,
                                             mimeType: response.mimeType,
                                             quality: quality,
                                             imageHeight: Double(orderedMeta.meta.imageSize.height),
                                             imageWidth: Double(orderedMeta.meta.imageSize.width))
                        }
                        .map { (orderedMeta.index, $0) }
                        .eraseToAnyPublisher()
                }
            }
    }

    private func buildSaveData(forClip clipUrl: URL, from images: [OrderedImageData]) -> Result<[ImageDataSet], PresenterError> {
        do {
            let result = try images
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
            return .success(result)
        } catch {
            return .failure(.failedToDownloadImages)
        }
    }

    private func save(target: [ImageDataSet]) -> Result<Void, PresenterError> {
        let currentDate = self.currentDateResolver()
        let clipId = UUID().uuidString
        let items = target.map { ClipItem(clipId: clipId, dataSet: $0, currentDate: currentDate) }
        let clip = Clip(clipId: clipId, url: self.url, clipItems: items, currentDate: currentDate)

        let data = target.flatMap {
            [
                ($0.originalImageFileName, $0.originalImageData),
                ($0.thumbnailFileName, $0.thumbnailData)
            ]
        }

        switch self.clipStorage.create(clip: clip, withData: data, forced: self.isEnabledOverwrite) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ClipItem {
    init(clipId: Clip.Identity, dataSet: ImageDataSet, currentDate: Date) {
        self.init(id: UUID().uuidString,
                  clipId: clipId,
                  clipIndex: dataSet.index,
                  imageFileName: dataSet.originalImageFileName,
                  imageUrl: dataSet.originalImageUrl,
                  imageSize: ImageSize(height: dataSet.imageHeight, width: dataSet.imageWidth),
                  registeredDate: currentDate,
                  updatedDate: currentDate)
    }
}

extension Clip {
    init(clipId: Clip.Identity, url: URL, clipItems: [ClipItem], currentDate: Date) {
        self.init(id: clipId,
                  url: url,
                  description: nil,
                  items: clipItems,
                  tags: [],
                  isHidden: false,
                  registeredDate: currentDate,
                  updatedDate: currentDate)
    }
}
