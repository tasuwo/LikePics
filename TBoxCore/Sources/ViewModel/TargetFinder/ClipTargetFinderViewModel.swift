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
}

public protocol ClipTargetFinderViewModelOutputs {
    var isLoading: CurrentValueSubject<Bool, Never> { get }

    var images: CurrentValueSubject<[SelectableImage], Never> { get }
    var selectedIndices: CurrentValueSubject<[Int], Never> { get }

    var isReloadItemEnabled: CurrentValueSubject<Bool, Never> { get }
    var isDoneItemEnabled: CurrentValueSubject<Bool, Never> { get }

    var isCollectionViewHidden: CurrentValueSubject<Bool, Never> { get }
    var emptyMessageViewAlpha: CurrentValueSubject<CGFloat, Never> { get }

    var previewViewHeight: CurrentValueSubject<CGFloat, Never> { get }

    var didFinish: PassthroughSubject<Void, Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
}

public class ClipTargetFinderViewModel: ClipTargetFinderViewModelType,
    ClipTargetFinderViewModelInputs,
    ClipTargetFinderViewModelOutputs
{
    enum PresenterError: Error {
        case failedToFindImages(WebImageUrlFinderError)
        case failedToDownloadImages
        case failedToSave(ClipStorageError)
        case internalError
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

    // MARK: ClipTargetFinderViewModelOutputs

    public var isLoading: CurrentValueSubject<Bool, Never> = .init(false)

    public var images: CurrentValueSubject<[SelectableImage], Never> = .init([])
    public var selectedIndices: CurrentValueSubject<[Int], Never> = .init([])

    public var isReloadItemEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    public var isDoneItemEnabled: CurrentValueSubject<Bool, Never> = .init(false)

    public var isCollectionViewHidden: CurrentValueSubject<Bool, Never> = .init(false)
    public var emptyMessageViewAlpha: CurrentValueSubject<CGFloat, Never> = .init(0)

    public var previewViewHeight: CurrentValueSubject<CGFloat, Never> = .init(0)

    public var didFinish: PassthroughSubject<Void, Never> = .init()
    public var errorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private static let maxDelayMs = 5000
    private static let incrementalDelayMs = 1000

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
            .map { $0.isEmpty }
            .sink { [weak self] isEmpty in self?.isCollectionViewHidden.send(isEmpty) }
            .store(in: &self.cancellableBag)

        self.images
            .map { $0.isEmpty ? 1 : 0 }
            .sink { [weak self] alpha in self?.emptyMessageViewAlpha.send(alpha) }
            .store(in: &self.cancellableBag)

        self.selectedIndices
            .map { $0.isEmpty ? 0 : 150 }
            .sink { [weak self] height in self?.previewViewHeight.send(height) }
            .store(in: &self.cancellableBag)
    }

    private func findImages() {
        self.images.send([])
        self.selectedIndices.send([])

        self.isLoading.send(true)

        self.resolveImageUrls(at: self.url)
            .map { sources in
                sources
                    .compactMap { SelectableImage(urlSet: $0) }
                    .filter { $0.isValid }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.isLoading.send(false)
                    self?.errorMessage.send(error.displayableMessage)

                case .finished:
                    break
                }
            } receiveValue: { [weak self] foundImages in
                self?.images.send(foundImages)
                self?.isLoading.send(false)
            }
            .store(in: &self.cancellableBag)
    }

    private func saveSelectedImages() {
        self.isLoading.send(true)

        let selections: [(index: Int, SelectableImage)] = self.selectedIndices.value.enumerated()
            .map { ($0.offset, self.images.value[$0.element]) }

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
                    self?.isLoading.send(false)
                    self?.errorMessage.send(error.displayableMessage)

                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.isLoading.send(false)
                self?.didFinish.send(())
            })
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

extension ClipTargetFinderViewModel.PresenterError {
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
