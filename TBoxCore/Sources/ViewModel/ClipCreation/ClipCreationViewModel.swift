//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

public protocol ClipCreationViewModelType {
    var inputs: ClipCreationViewModelInputs { get }
    var outputs: ClipCreationViewModelOutputs { get }
}

public protocol ClipCreationViewModelInputs {
    var viewLoaded: PassthroughSubject<UIView, Never> { get }
    var viewDidAppear: PassthroughSubject<Void, Never> { get }

    var hidingUpdated: PassthroughSubject<Bool, Never> { get }

    var loadImages: PassthroughSubject<Void, Never> { get }
    var saveImages: PassthroughSubject<Void, Never> { get }

    var deletedTag: PassthroughSubject<Tag, Never> { get }
    var replacedTags: PassthroughSubject<[Tag], Never> { get }

    var selectedImage: PassthroughSubject<Int, Never> { get }
    var deselectedImage: PassthroughSubject<Int, Never> { get }
}

public protocol ClipCreationViewModelOutputs: AnyObject {
    var applySnapshot: AnyPublisher<ClipCreationViewLayout.Snapshot, Never> { get }

    var isLoading: CurrentValueSubject<Bool, Never> { get }

    var tags: CurrentValueSubject<[Tag], Never> { get }
    var selectedIndices: CurrentValueSubject<[Int], Never> { get }

    var isReloadItemEnabled: CurrentValueSubject<Bool, Never> { get }
    var isDoneItemEnabled: CurrentValueSubject<Bool, Never> { get }

    var displayReloadButton: CurrentValueSubject<Bool, Never> { get }
    var displayCollectionView: CurrentValueSubject<Bool, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }

    var didFinish: PassthroughSubject<Void, Never> { get }

    var emptyErrorTitle: CurrentValueSubject<String?, Never> { get }
    var emptyErrorMessage: CurrentValueSubject<String?, Never> { get }

    var displayAlert: PassthroughSubject<(title: String, body: String), Never> { get }
}

public class ClipCreationViewModel: ClipCreationViewModelType,
    ClipCreationViewModelInputs,
    ClipCreationViewModelOutputs
{
    public struct Configuration {
        public static let webImage = Configuration(selectAllAfterLoading: false,
                                                   isReloadable: true)
        public static let rawImage = Configuration(selectAllAfterLoading: true,
                                                   isReloadable: false)

        public let selectAllAfterLoading: Bool
        public let isReloadable: Bool

        public init(selectAllAfterLoading: Bool,
                    isReloadable: Bool)
        {
            self.selectAllAfterLoading = selectAllAfterLoading
            self.isReloadable = isReloadable
        }
    }

    enum DownloadError: Error {
        case failedToSave(ClipStorageError)
        case failedToDownloadImage(ImageLoaderError)
        case failedToCreateClipItemSource(ClipItemSource.InitializeError)
        case internalError
    }

    public typealias Layout = ClipCreationViewLayout

    // MARK: - Properties

    // MARK: ClipCreationViewModelType

    public var inputs: ClipCreationViewModelInputs { self }
    public var outputs: ClipCreationViewModelOutputs { self }

    // MARK: ClipCreationViewModelInputs

    public var viewLoaded: PassthroughSubject<UIView, Never> = .init()
    public let viewDidAppear: PassthroughSubject<Void, Never> = .init()

    public let hidingUpdated: PassthroughSubject<Bool, Never> = .init()

    public var loadImages: PassthroughSubject<Void, Never> = .init()
    public var saveImages: PassthroughSubject<Void, Never> = .init()

    public var deletedTag: PassthroughSubject<Tag, Never> = .init()
    public var replacedTags: PassthroughSubject<[Tag], Never> = .init()

    public var selectedImage: PassthroughSubject<Int, Never> = .init()
    public var deselectedImage: PassthroughSubject<Int, Never> = .init()

    public var selectedTags: PassthroughSubject<[Tag], Never> = .init()

    // MARK: ClipCreationViewModelOutputs

    public var applySnapshot: AnyPublisher<Layout.Snapshot, Never> { _snapshot.eraseToAnyPublisher() }

    public var isLoading: CurrentValueSubject<Bool, Never> = .init(false)

    public var tags: CurrentValueSubject<[Tag], Never> = .init([])
    public var selectedIndices: CurrentValueSubject<[Int], Never> = .init([])

    public var isReloadItemEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    public var isDoneItemEnabled: CurrentValueSubject<Bool, Never> = .init(false)

    public let displayReloadButton: CurrentValueSubject<Bool, Never> = .init(false)
    public var displayCollectionView: CurrentValueSubject<Bool, Never> = .init(false)
    public var displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)

    public var didFinish: PassthroughSubject<Void, Never> = .init()

    public let emptyErrorTitle: CurrentValueSubject<String?, Never> = .init(nil)
    public let emptyErrorMessage: CurrentValueSubject<String?, Never> = .init(nil)

    public let displayAlert: PassthroughSubject<(title: String, body: String), Never> = .init()

    // MARK: Privates

    private let _shouldClipHide: CurrentValueSubject<Bool, Never> = .init(false)
    private let _url: CurrentValueSubject<URL?, Never>
    private let _images: CurrentValueSubject<[ImageSource], Never> = .init([])
    private let _snapshot: CurrentValueSubject<Layout.Snapshot, Never>

    private var subscriptions = Set<AnyCancellable>()

    private let imageLoadQueue = DispatchQueue(label: "net.tasuwo.ClipCollectionViewPresenter.imageLoadQueue")

    private let clipStore: ClipStorable
    private let clipBuilder: ClipBuildable
    private let provider: ImageSourceProvider
    private let imageLoader: ImageLoaderProtocol
    private let configuration: Configuration
    private let urlSession: URLSession

    // MARK: - Lifecycle

    init(url: URL?,
         clipStore: ClipStorable,
         clipBuilder: ClipBuildable,
         provider: ImageSourceProvider,
         imageLoader: ImageLoaderProtocol,
         configuration: Configuration,
         urlSession: URLSession = URLSession.shared)
    {
        self.clipStore = clipStore
        self.clipBuilder = clipBuilder
        self.provider = provider
        self.imageLoader = imageLoader
        self.configuration = configuration
        self.urlSession = urlSession

        self._url = .init(url)
        self._snapshot = .init(Self.createSnapshot(url: _url.value,
                                                   tags: tags.value,
                                                   images: _images.value,
                                                   hides: _shouldClipHide.value))

        self.bind()
    }

    public convenience init(url: URL?,
                            clipStore: ClipStorable,
                            provider: ImageSourceProvider,
                            configuration: Configuration,
                            urlSession: URLSession = URLSession.shared)
    {
        self.init(url: url,
                  clipStore: clipStore,
                  clipBuilder: ClipBuilder(currentDateResolver: { Date() },
                                           uuidIssuer: { UUID() }),
                  provider: provider,
                  imageLoader: ImageLoader(),
                  configuration: configuration,
                  urlSession: urlSession)
    }
}

extension ClipCreationViewModel {
    private static func createSnapshot(url: URL?, tags: [Tag], images: [ImageSource], hides: Bool) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Layout.Item.tagAddition] + tags.map({ Layout.Item.tag($0) }))

        snapshot.appendSections([.meta])
        snapshot.appendItems([
            .meta(.init(title: L10n.clipMetaShouldHides, accessory: .switch(isOn: hides)))
        ])

        snapshot.appendSections([.image])
        snapshot.appendItems(images.map({ Layout.Item.image($0) }))
        return snapshot
    }
}

extension ClipCreationViewModel {
    // MARK: Bind

    private func bind() {
        // MARK: Inputs

        _url
            .combineLatest(tags, _images, _shouldClipHide)
            .sink { [weak self] url, tags, images, shouldHides in
                self?._snapshot.send(Self.createSnapshot(url: url, tags: tags, images: images, hides: shouldHides))
            }
            .store(in: &self.subscriptions)

        self.viewLoaded
            .sink { [weak self] view in
                guard let self = self else { return }
                self.provider.viewDidLoad.send(view)
            }
            .store(in: &self.subscriptions)

        self.hidingUpdated
            .sink { [weak self] shouldHide in self?._shouldClipHide.send(shouldHide) }
            .store(in: &self.subscriptions)

        self.loadImages
            .sink { [weak self] _ in
                self?.loadImageSources()
            }
            .store(in: &self.subscriptions)

        self.saveImages
            .sink { [weak self] _ in
                self?.saveSelectedImages()
            }
            .store(in: &self.subscriptions)

        self.deletedTag
            .sink { [weak self] tag in
                guard var newTags = self?.tags.value,
                      let index = newTags.firstIndex(of: tag)
                else {
                    return
                }
                newTags.remove(at: index)
                self?.tags.send(newTags)
            }
            .store(in: &self.subscriptions)

        self.replacedTags
            .sink { [weak self] tags in
                self?.tags.send(tags)
            }
            .store(in: &self.subscriptions)

        self.selectedImage
            .sink { [weak self] index in self?.selectItem(at: index) }
            .store(in: &self.subscriptions)

        self.deselectedImage
            .sink { [weak self] index in self?.deselectItem(at: index) }
            .store(in: &self.subscriptions)

        // MARK: Outputs

        self.isLoading
            .map { !$0 }
            .sink { [weak self] value in self?.isReloadItemEnabled.send(value) }
            .store(in: &self.subscriptions)

        self.selectedIndices
            .combineLatest(isLoading)
            .map { selectedIndices, isLoading -> Bool in !selectedIndices.isEmpty && !isLoading }
            .sink { [weak self] value in self?.isDoneItemEnabled.send(value) }
            .store(in: &self.subscriptions)

        self._images
            .sink { [weak self] _ in self?.selectedIndices.send([]) }
            .store(in: &self.subscriptions)

        self._images
            .map { !$0.isEmpty }
            // 描画直後はCollectionViewのboundsが不正なので、調整されるまで待つ
            .combineLatest(self.viewDidAppear)
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [weak self] isEmpty, _ in self?.displayCollectionView.send(isEmpty) }
            .store(in: &self.subscriptions)

        self._images
            .combineLatest(isLoading)
            .map { images, isLoading in images.isEmpty && !isLoading }
            .sink { [weak self] display in self?.displayEmptyMessage.send(display) }
            .store(in: &self.subscriptions)

        self.displayReloadButton.send(configuration.isReloadable)
    }

    private func loadImageSources() {
        self.isLoading.send(true)

        self._images.send([])

        self.provider.resolveSources()
            .map { sources in sources.filter { $0.isValid } }
            .tryMap { sources -> [ImageSource] in
                guard !sources.isEmpty else { throw ImageSourceProviderError.notFound }
                return sources
            }
            .mapError { $0 as? ImageSourceProviderError ?? ImageSourceProviderError.internalError }
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
                guard let self = self else { return }
                self._images.send(foundImages)
                if self.configuration.selectAllAfterLoading {
                    self.selectedIndices.send(([Int])(0 ..< foundImages.count))
                }
            }
            .store(in: &self.subscriptions)
    }

    private func saveSelectedImages() {
        self.isLoading.send(true)

        let selections: [(index: Int, ImageSource)] = self.selectedIndices.value.enumerated()
            .map { ($0.offset, self._images.value[$0.element]) }

        self.fetchImages(for: selections)
            .flatMap { [weak self] sources -> AnyPublisher<Void, DownloadError> in
                guard let self = self else {
                    return Fail(error: DownloadError.internalError)
                        .eraseToAnyPublisher()
                }
                return self.save(sources: sources)
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
                    self?.didFinish.send(())
                }
            } receiveValue: { _ in
                // NOP
            }
            .store(in: &self.subscriptions)
    }

    private func selectItem(at index: Int) {
        guard self._images.value.indices.contains(index) else { return }
        self.selectedIndices.send(self.selectedIndices.value + [index])
    }

    private func deselectItem(at index: Int) {
        guard let removeAt = self.selectedIndices.value.firstIndex(of: index) else { return }
        var array = self.selectedIndices.value
        array.remove(at: removeAt)
        self.selectedIndices.send(array)
    }

    // MARK: Load Images

    private func fetchImages(for selections: [(index: Int, source: ImageSource)]) -> AnyPublisher<[ClipItemSource], DownloadError> {
        let publishers: [AnyPublisher<ClipItemSource, DownloadError>] = selections
            .map { [weak self] selection in
                guard let self = self else {
                    return Fail(error: DownloadError.internalError)
                        .eraseToAnyPublisher()
                }
                return self.imageLoader.load(from: selection.source)
                    .mapError { DownloadError.failedToDownloadImage($0) }
                    .tryMap { try ClipItemSource(index: selection.index, result: $0) }
                    .mapError { err in
                        if let error = err as? DownloadError {
                            return error
                        } else if let error = err as? ClipItemSource.InitializeError {
                            return DownloadError.failedToCreateClipItemSource(error)
                        } else {
                            return DownloadError.internalError
                        }
                    }
                    .eraseToAnyPublisher()
            }
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }

    // MARK: Save Images

    private func save(sources: [ClipItemSource]) -> Result<Void, DownloadError> {
        let result = self.clipBuilder.build(url: self._url.value,
                                            hidesClip: _shouldClipHide.value,
                                            sources: sources,
                                            tagIds: self.tags.value.map { $0.id })
        switch self.clipStore.create(clip: result.0, withContainers: result.1, forced: false) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ImageSourceProviderError {
    var displayTitle: String {
        switch self {
        case .notFound:
            return L10n.clipCreationViewLoadingErrorNotFoundTitle

        case .networkError:
            return L10n.clipCreationViewLoadingErrorConnectionTitle

        case .internalError:
            return L10n.clipCreationViewLoadingErrorInternalTitle

        case .timeout:
            return L10n.clipCreationViewLoadingErrorTimeoutTitle
        }
    }

    var displayMessage: String {
        switch self {
        case .notFound:
            return L10n.clipCreationViewLoadingErrorNotFoundMessage

        case .networkError:
            return L10n.clipCreationViewLoadingErrorConnectionMessage

        case .internalError:
            return L10n.clipCreationViewLoadingErrorInternalMessage

        case .timeout:
            return L10n.clipCreationViewLoadingErrorTimeoutMessage
        }
    }
}

extension ClipCreationViewModel.DownloadError {
    var displayTitle: String {
        switch self {
        case .failedToDownloadImage:
            return L10n.clipCreationViewDownloadErrorFailedToDownloadTitle

        default:
            return L10n.clipCreationViewDownloadErrorFailedToSaveTitle
        }
    }

    var displayMessage: String {
        switch self {
        case .failedToDownloadImage:
            return L10n.clipCreationViewDownloadErrorFailedToDownloadBody

        default:
            return L10n.clipCreationViewDownloadErrorFailedToSaveBody
        }
    }
}
