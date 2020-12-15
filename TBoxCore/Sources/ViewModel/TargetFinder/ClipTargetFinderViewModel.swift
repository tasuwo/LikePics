//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

public protocol ClipTargetFinderViewModelType {
    var inputs: ClipTargetFinderViewModelInputs { get }
    var outputs: ClipTargetFinderViewModelOutputs { get }
}

public protocol ClipTargetFinderViewModelInputs {
    var viewLoaded: PassthroughSubject<UIView, Never> { get }

    var startedFindingImage: PassthroughSubject<Void, Never> { get }
    var saveImages: PassthroughSubject<Void, Never> { get }

    var select: PassthroughSubject<Int, Never> { get }
    var deselect: PassthroughSubject<Int, Never> { get }

    var selectedTags: PassthroughSubject<[Tag], Never> { get }
}

public protocol ClipTargetFinderViewModelOutputs {
    var isLoading: CurrentValueSubject<Bool, Never> { get }

    var images: CurrentValueSubject<[SelectableImage], Never> { get }
    var selectedIndices: CurrentValueSubject<[Int], Never> { get }

    var isReloadItemEnabled: CurrentValueSubject<Bool, Never> { get }
    var isDoneItemEnabled: CurrentValueSubject<Bool, Never> { get }

    var displayCollectionView: CurrentValueSubject<Bool, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }

    var didFinish: PassthroughSubject<Void, Never> { get }

    var emptyErrorTitle: CurrentValueSubject<String?, Never> { get }
    var emptyErrorMessage: CurrentValueSubject<String?, Never> { get }

    var displayAlert: PassthroughSubject<(title: String, body: String), Never> { get }
}

public class ClipTargetFinderViewModel: ClipTargetFinderViewModelType,
    ClipTargetFinderViewModelInputs,
    ClipTargetFinderViewModelOutputs
{
    enum LoadingError: Error {
        case networkError(Error)
        case timeout
        case internalError
        case notFound

        init(finderError: WebImageUrlFinderError) {
            switch finderError {
            case .internalError:
                self = .internalError

            case .timeout:
                self = .timeout

            case let .networkError(error):
                self = .networkError(error)
            }
        }
    }

    enum DownloadError: Error {
        case failedToSave(ClipStorageError)
        case failedToDownloadImage
    }

    // MARK: - Properties

    // MARK: ClipTargetFinderViewModelType

    public var inputs: ClipTargetFinderViewModelInputs { self }
    public var outputs: ClipTargetFinderViewModelOutputs { self }

    // MARK: ClipTargetFinderViewModelInputs

    public var viewLoaded: PassthroughSubject<UIView, Never> = .init()

    public var startedFindingImage: PassthroughSubject<Void, Never> = .init()
    public var saveImages: PassthroughSubject<Void, Never> = .init()

    public var select: PassthroughSubject<Int, Never> = .init()
    public var deselect: PassthroughSubject<Int, Never> = .init()

    public var selectedTags: PassthroughSubject<[Tag], Never> = .init()

    // MARK: ClipTargetFinderViewModelOutputs

    public var isLoading: CurrentValueSubject<Bool, Never> = .init(false)

    public var images: CurrentValueSubject<[SelectableImage], Never> = .init([])
    public var selectedIndices: CurrentValueSubject<[Int], Never> = .init([])

    public var isReloadItemEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    public var isDoneItemEnabled: CurrentValueSubject<Bool, Never> = .init(false)

    public var displayCollectionView: CurrentValueSubject<Bool, Never> = .init(true)
    public var displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(true)

    public var didFinish: PassthroughSubject<Void, Never> = .init()

    public let emptyErrorTitle: CurrentValueSubject<String?, Never> = .init(nil)
    public let emptyErrorMessage: CurrentValueSubject<String?, Never> = .init(nil)

    public let displayAlert: PassthroughSubject<(title: String, body: String), Never> = .init()

    // MARK: Privates

    private static let maxDelayMs = 5000
    private static let incrementalDelayMs = 1000

    private var tags: [Tag] = []
    private var urlFinderDelayMs: Int = 0
    private var cancellableBag = Set<AnyCancellable>()

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

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
         urlSession: URLSession = URLSession.shared)
    {
        self.url = url
        self.clipStore = clipStore
        self.clipBuilder = clipBuilder
        self.finder = finder
        self.urlSession = urlSession

        self.bind()
    }

    public convenience init(url: URL,
                            clipStore: ClipStorable,
                            urlSession: URLSession = URLSession.shared)
    {
        self.init(url: url,
                  clipStore: clipStore,
                  clipBuilder: ClipBuilder(url: url,
                                           currentDateResolver: { Date() },
                                           uuidIssuer: { UUID() }),
                  finder: WebImageUrlFinder(),
                  urlSession: urlSession)
    }

    // MARK: - Methods

    // MARK: Bind

    private func bind() {
        // MARK: Inputs

        self.viewLoaded
            .sink { [weak self] view in
                guard let self = self else { return }
                // HACK: Add WebView to view hierarchy for loading page.
                view.addSubview(self.finder.webView)
                self.finder.webView.isHidden = true
            }
            .store(in: &self.cancellableBag)

        self.startedFindingImage
            .sink { [weak self] _ in
                self?.findImages()
            }
            .store(in: &self.cancellableBag)

        self.saveImages
            .sink { [weak self] _ in
                self?.saveSelectedImages()
            }
            .store(in: &self.cancellableBag)

        self.select
            .sink { [weak self] index in
                self?.selectItem(at: index)
            }
            .store(in: &self.cancellableBag)

        self.deselect
            .sink { [weak self] index in
                self?.deselectItem(at: index)
            }
            .store(in: &self.cancellableBag)

        self.selectedTags
            .sink { [weak self] tags in
                self?.tags = tags
            }
            .store(in: &self.cancellableBag)

        // MARK: Outputs

        self.isLoading
            .map { !$0 }
            .sink { [weak self] value in self?.isReloadItemEnabled.send(value) }
            .store(in: &self.cancellableBag)

        self.selectedIndices
            .map { !$0.isEmpty }
            .sink { [weak self] value in self?.isDoneItemEnabled.send(value) }
            .store(in: &self.cancellableBag)

        self.images
            .sink { [weak self] _ in self?.selectedIndices.send([]) }
            .store(in: &self.cancellableBag)

        self.images
            .map { !$0.isEmpty }
            .sink { [weak self] isEmpty in self?.displayCollectionView.send(isEmpty) }
            .store(in: &self.cancellableBag)

        self.images
            .combineLatest(isLoading)
            .map { images, isLoading in images.isEmpty && !isLoading }
            .sink { [weak self] display in self?.displayEmptyMessage.send(display) }
            .store(in: &self.cancellableBag)
    }

    private func findImages() {
        self.isLoading.send(true)

        self.images.send([])
        self.selectedIndices.send([])

        self.resolveImageUrls(at: self.url)
            .map { sources in
                sources
                    .compactMap { SelectableImage(urlSet: $0) }
                    .filter { $0.isValid }
            }
            .tryFilter {
                if $0.isEmpty { throw LoadingError.notFound }
                return true
            }
            .mapError { $0 as? LoadingError ?? LoadingError.internalError }
            .sink { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.emptyErrorTitle.send(error.displayTitle)
                    self?.emptyErrorMessage.send(error.displayMessage)
                    self?.isLoading.send(false)

                case .finished:
                    self?.emptyErrorTitle.send(nil)
                    self?.emptyErrorMessage.send(nil)
                    self?.isLoading.send(false)
                }
            } receiveValue: { [weak self] foundImages in
                self?.images.send(foundImages)
            }
            .store(in: &self.cancellableBag)
    }

    private func saveSelectedImages() {
        self.isLoading.send(true)

        let selections: [(index: Int, SelectableImage)] = self.selectedIndices.value.enumerated()
            .map { ($0.offset, self.images.value[$0.element]) }

        self.fetchImages(for: selections)
            .flatMap { [weak self] sources -> AnyPublisher<Void, DownloadError> in
                guard let self = self else {
                    return Fail(error: DownloadError.failedToDownloadImage)
                        .eraseToAnyPublisher()
                }
                return self.save(target: sources)
                    .publisher
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.displayAlert.send((error.displayTitle, error.displayMessage))
                    self?.isLoading.send(false)

                case .finished:
                    self?.isLoading.send(false)
                    self?.didFinish.send(())
                }
            } receiveValue: { _ in }
            .store(in: &self.cancellableBag)
    }

    private func selectItem(at index: Int) {
        guard self.images.value.indices.contains(index) else { return }
        self.selectedIndices.send(self.selectedIndices.value + [index])
    }

    private func deselectItem(at index: Int) {
        guard let removeAt = self.selectedIndices.value.firstIndex(of: index) else { return }
        var array = self.selectedIndices.value
        array.remove(at: removeAt)
        self.selectedIndices.send(array)
    }

    // MARK: Load Images

    private func resolveImageUrls(at url: URL) -> Future<[WebImageUrlSet], LoadingError> {
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
                    promise(.failure(.init(finderError: error)))
                }
            }

            if self.urlFinderDelayMs < Self.maxDelayMs {
                self.urlFinderDelayMs += Self.incrementalDelayMs
            }
        }
    }

    private func fetchImages(for selections: [(index: Int, image: SelectableImage)]) -> AnyPublisher<[(index: Int, ClipItemSource)], DownloadError> {
        let publishers: [AnyPublisher<(index: Int, ClipItemSource), Never>] = selections
            .compactMap { [weak self] selection in
                guard let self = self else { return nil }
                return ClipItemSource.make(by: selection.image, using: self.urlSession)
                    .map { (selection.index, $0) }
                    .eraseToAnyPublisher()
            }
        return Publishers.MergeMany(publishers)
            .collect()
            .mapError { _ in DownloadError.failedToDownloadImage }
            .eraseToAnyPublisher()
    }

    // MARK: Save Images

    private func save(target: [(index: Int, source: ClipItemSource)]) -> Result<Void, DownloadError> {
        let result = self.clipBuilder.build(sources: target, tags: self.tags)
        switch self.clipStore.create(clip: result.0, withContainers: result.1, forced: false) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ClipTargetFinderViewModel.LoadingError {
    var displayTitle: String {
        switch self {
        case .notFound:
            return L10n.clipTargetFinderViewLoadingErrorNotFoundTitle

        case .networkError:
            return L10n.clipTargetFinderViewLoadingErrorConnectionTitle

        case .internalError:
            return L10n.clipTargetFinderViewLoadingErrorInternalTitle

        case .timeout:
            return L10n.clipTargetFinderViewLoadingErrorTimeoutTitle
        }
    }

    var displayMessage: String {
        switch self {
        case .notFound:
            return L10n.clipTargetFinderViewLoadingErrorNotFoundMessage

        case .networkError:
            return L10n.clipTargetFinderViewLoadingErrorConnectionMessage

        case .internalError:
            return L10n.clipTargetFinderViewLoadingErrorInternalMessage

        case .timeout:
            return L10n.clipTargetFinderViewLoadingErrorTimeoutMessage
        }
    }
}

extension ClipTargetFinderViewModel.DownloadError {
    var displayTitle: String {
        switch self {
        case .failedToDownloadImage:
            return L10n.clipTargetFinderViewDownloadErrorFailedToDownloadTitle

        case .failedToSave:
            return L10n.clipTargetFinderViewDownloadErrorFailedToSaveTitle
        }
    }

    var displayMessage: String {
        switch self {
        case .failedToDownloadImage:
            return L10n.clipTargetFinderViewDownloadErrorFailedToDownloadBody

        case .failedToSave:
            return L10n.clipTargetFinderViewDownloadErrorFailedToSaveBody
        }
    }
}
