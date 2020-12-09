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

public class ClipTargetFinderPresenter {
    enum PresenterError: Error {
        case failedToFindImages(WebImageUrlFinderError)
        case failedToDownloadImages
        case failedToSave(ClipStorageError)
        case internalError
    }

    private static let maxDelayMs = 5000
    private static let incrementalDelayMs = 1000

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
    private var urlFinderDelayMs: Int = 0
    private var cancellableBag = Set<AnyCancellable>()

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    weak var view: ClipTargetFinderViewProtocol?

    private let url: URL
    private let clipStore: ClipStorable
    private let clipBuilder: ClipBuildable
    private let finder: WebImageUrlFinderProtocol
    private let urlSession: URLSession

    // MARK: - Lifecycle

    init(url: URL,
         clipStore: ClipStorable,
         clipBuilder: ClipBuildable,
         finder: WebImageUrlFinderProtocol,
         isEnabledOverwrite: Bool = false,
         urlSession: URLSession = URLSession.shared)
    {
        self.url = url
        self.clipStore = clipStore
        self.clipBuilder = clipBuilder
        self.finder = finder
        self.isEnabledOverwrite = isEnabledOverwrite
        self.urlSession = urlSession
    }

    public convenience init(url: URL,
                            clipStore: ClipStorable,
                            isEnabledOverwrite: Bool = false,
                            urlSession: URLSession = URLSession.shared)
    {
        self.init(url: url,
                  clipStore: clipStore,
                  clipBuilder: ClipBuilder(url: url,
                                           currentDateResolver: { Date() },
                                           uuidIssuer: { UUID() }),
                  finder: WebImageUrlFinder(),
                  isEnabledOverwrite: isEnabledOverwrite,
                  urlSession: urlSession)
    }

    // MARK: - Methods

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
        if !self.selectableImages.isEmpty {
            self.selectableImages = []
            self.view?.reloadList()
        }

        self.view?.startLoading()

        self.resolveImageUrls(at: self.url)
            .map { sources in
                sources
                    .compactMap { SelectableImage(urlSet: $0) }
                    .filter { $0.isValid }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.view?.endLoading()
                    self?.view?.show(errorMessage: error.displayableMessage)

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

        let selections: [(index: Int, SelectableImage)] = self.selectedIndices.enumerated()
            .map { ($0.offset, self.selectableImages[$0.element]) }

        self.fetchImages(for: selections)
            .flatMap { [weak self] sources -> AnyPublisher<Void, PresenterError> in
                guard let self = self else {
                    return Fail(error: PresenterError.internalError)
                        .eraseToAnyPublisher()
                }
                return self.save(target: sources)
                    .publisher
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.view?.endLoading()
                    self?.view?.show(errorMessage: error.displayableMessage)

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

    private func resolveImageUrls(at url: URL) -> Future<[WebImageUrlSet], PresenterError> {
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

    private func fetchImages(for selections: [(index: Int, image: SelectableImage)]) -> AnyPublisher<[(index: Int, ClipItemSource)], PresenterError> {
        let publishers: [AnyPublisher<(index: Int, ClipItemSource), Never>] = selections
            .compactMap { [weak self] selection in
                guard let self = self else { return nil }
                return ClipItemSource.make(by: selection.image, using: self.urlSession)
                    .map { (selection.index, $0) }
                    .eraseToAnyPublisher()
            }
        return Publishers.MergeMany(publishers)
            .collect()
            .mapError { _ in PresenterError.internalError }
            .eraseToAnyPublisher()
    }

    // MARK: Save Images

    private func save(target: [(index: Int, source: ClipItemSource)]) -> Result<Void, PresenterError> {
        let result = self.clipBuilder.build(sources: target)
        switch self.clipStore.create(clip: result.0, withContainers: result.1, forced: false) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ClipTargetFinderPresenter.PresenterError {
    var displayableMessage: String {
        switch self {
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
}
