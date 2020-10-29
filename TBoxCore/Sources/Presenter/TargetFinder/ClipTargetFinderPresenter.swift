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

typealias OrderingSelectableImage = (index: Int, meta: ClipItemSource)

public class ClipTargetFinderPresenter {
    enum PresenterError: Error {
        case failedToFindImages(WebImageUrlFinderError)
        case failedToDownloadImages
        case failedToSave(ClipStorageError)
        case internalError
    }

    private static let maxDelayMs = 5000
    private static let incrementalDelayMs = 1000

    private(set) var selectableImages: [ClipItemSource] = [] {
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
    private var urlFinderDelayMs: Int = 0
    private var cancellableBag = Set<AnyCancellable>()

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    weak var view: ClipTargetFinderViewProtocol?

    private let url: URL
    private let clipCommandService: ClipCommandServiceProtocol
    private let clipQueryService: ClipQueryServiceProtocol
    private let finder: WebImageUrlFinderProtocol
    private let currentDateResolver: () -> Date
    private let urlSession: URLSession

    // MARK: - Lifecycle

    public init(url: URL,
                clipCommandService: ClipCommandServiceProtocol,
                clipQueryService: ClipQueryServiceProtocol,
                finder: WebImageUrlFinderProtocol,
                currentDateResolver: @escaping () -> Date,
                isEnabledOverwrite: Bool = false,
                urlSession: URLSession = URLSession.shared)
    {
        self.url = url
        self.clipCommandService = clipCommandService
        self.clipQueryService = clipQueryService
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
        switch self.clipQueryService.existsClip(havingUrl: self.url) {
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
            .flatMap { [weak self] urls -> AnyPublisher<[ClipItemSource], PresenterError> in
                guard let self = self else {
                    return Fail(error: PresenterError.internalError)
                        .eraseToAnyPublisher()
                }
                return self.fetchImages(atUrls: urls)
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

        self.save(target: selections)
            .publisher
            .eraseToAnyPublisher()
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
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            self.finder.findImageUrls(inWebSiteAt: url, delay: self.urlFinderDelayMs) { result in
                switch result {
                case let .success(urls):
                    promise(.success(urls))

                case let .failure(error):
                    promise(.failure(.failedToFindImages(error)))
                }
            }

            if self.urlFinderDelayMs < Self.maxDelayMs {
                self.urlFinderDelayMs += Self.incrementalDelayMs
            }
        }
    }

    private func fetchImages(atUrls urls: [URL]) -> AnyPublisher<[ClipItemSource], PresenterError> {
        do {
            let publishers: [AnyPublisher<ClipItemSource, Never>] = try urls
                .map { [weak self] url in
                    guard let self = self else { throw PresenterError.internalError }
                    return ClipItemSource.make(by: url, using: self.urlSession)
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

    private func save(target: [OrderingSelectableImage]) -> Result<Void, PresenterError> {
        let currentDate = self.currentDateResolver()
        let clipId = UUID().uuidString
        let items = target.map {
            ClipItem(id: UUID().uuidString,
                     clipId: clipId,
                     index: $0.index,
                     source: $0.meta,
                     currentDate: currentDate)
        }
        let clip = Clip(clipId: clipId, url: self.url, clipItems: items, currentDate: currentDate)
        let data = target.map { ($0.meta.fileName, $0.meta.data) }

        switch self.clipCommandService.create(clip: clip, withData: data, forced: self.isEnabledOverwrite) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ClipItem {
    init(id: ClipItem.Identity, clipId: Clip.Identity, index: Int, source: ClipItemSource, currentDate: Date) {
        self.init(id: id,
                  clipId: clipId,
                  clipIndex: index,
                  imageFileName: source.fileName,
                  imageUrl: source.url,
                  imageSize: ImageSize(height: source.height, width: source.width),
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
