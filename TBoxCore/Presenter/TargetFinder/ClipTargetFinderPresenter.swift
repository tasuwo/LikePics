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

typealias OrderingSelectableImage = (index: Int, meta: SelectableImage)

public class ClipTargetFinderPresenter {
    enum PresenterError: Error {
        case failedToFindImages(WebImageUrlFinderError)
        case failedToDownloadImages
        case failedToSave(ClipStorageError)
        case internalError
    }

    private(set) var selectableImages: [SelectableImage] = [] {
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

        if !self.selectableImages.isEmpty {
            self.selectableImages = []
            self.view?.reloadList()
        }

        self.view?.startLoading()

        self.resolveImageUrls(at: self.url)
            .flatMap { urls -> AnyPublisher<[SelectableImage], PresenterError> in
                return self.resolveSizes(ofImageUrls: urls)
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
            }, receiveValue: { [weak self] foundImages in
                self?.selectableImages = foundImages
                self?.view?.endLoading()
                self?.view?.reloadList()
            })
            .store(in: &self.cancellableBag)
    }

    func saveSelectedImages() {
        self.view?.startLoading()

        let selections: [OrderingSelectableImage] = self.selectedIndices.enumerated()
            .map { ($0.offset, self.selectableImages[$0.element]) }

        // TODO: fetchImageDataは削除し、SelectedImage内にあるデータをそのままDLする
        Publishers.MergeMany(self.fetchImageData(for: selections, using: self.urlSession))
            .collect()
            .mapError { _ in
                return PresenterError.failedToDownloadImages
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
        guard self.selectableImages.indices.contains(index) else { return }

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

    private func resolveImageUrls(at url: URL) -> Future<[URL], PresenterError> {
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

    private func resolveSizes(ofImageUrls urls: [URL]) -> AnyPublisher<[SelectableImage], PresenterError> {
        do {
            let publishers: [AnyPublisher<SelectableImage, Never>] = try urls
                .map { [weak self] url in
                    guard let self = self else { throw PresenterError.internalError }
                    return SelectableImage.make(by: url, using: self.urlSession)
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

    private func fetchImageData(for images: [OrderingSelectableImage], using session: URLSession) -> [AnyPublisher<ClipItemDataSource, Error>] {
        return images
            .compactMap { image in
                let imageUrl = image.meta.imageUrl
                return session
                    .dataTaskPublisher(for: imageUrl)
                    .tryMap { data, response -> ClipItemDataSource in
                        ClipItemDataSource(index: image.index,
                                           url: imageUrl,
                                           data: data,
                                           mimeType: response.mimeType,
                                           height: Double(image.meta.imageSize.height),
                                           width: Double(image.meta.imageSize.width))
                    }
                    .eraseToAnyPublisher()
            }
    }

    private func save(target: [ClipItemDataSource]) -> Result<Void, PresenterError> {
        let currentDate = self.currentDateResolver()
        let clipId = UUID().uuidString
        let items = target.map {
            ClipItem(id: UUID().uuidString, clipId: clipId, dataSet: $0, currentDate: currentDate)
        }
        let clip = Clip(clipId: clipId, url: self.url, clipItems: items, currentDate: currentDate)
        let data = target.map { ($0.fileName, $0.data) }

        switch self.clipStorage.create(clip: clip, withData: data, forced: self.isEnabledOverwrite) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ClipItem {
    init(id: ClipItem.Identity, clipId: Clip.Identity, dataSet: ClipItemDataSource, currentDate: Date) {
        self.init(id: id,
                  clipId: clipId,
                  clipIndex: dataSet.index,
                  imageFileName: dataSet.fileName,
                  imageUrl: dataSet.url,
                  imageSize: ImageSize(height: dataSet.height, width: dataSet.width),
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
