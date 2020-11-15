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
    private let finder: WebImageUrlFinderProtocol
    private let currentDateResolver: () -> Date
    private let urlSession: URLSession

    // MARK: - Lifecycle

    init(url: URL,
         clipStore: ClipStorable,
         finder: WebImageUrlFinderProtocol,
         currentDateResolver: @escaping () -> Date,
         isEnabledOverwrite: Bool = false,
         urlSession: URLSession = URLSession.shared)
    {
        self.url = url
        self.clipStore = clipStore
        self.finder = finder
        self.currentDateResolver = currentDateResolver
        self.isEnabledOverwrite = isEnabledOverwrite
        self.urlSession = urlSession
    }

    public convenience init(url: URL,
                            clipStore: ClipStorable,
                            currentDateResolver: @escaping () -> Date,
                            isEnabledOverwrite: Bool = false,
                            urlSession: URLSession = URLSession.shared)
    {
        self.init(url: url,
                  clipStore: clipStore,
                  finder: WebImageUrlFinder(),
                  currentDateResolver: currentDateResolver,
                  isEnabledOverwrite: isEnabledOverwrite,
                  urlSession: urlSession)
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
        if !self.selectableImages.isEmpty {
            self.selectableImages = []
            self.view?.reloadList()
        }

        self.view?.startLoading()

        self.resolveImageUrls(at: self.url)
            .map { [weak self] sources in
                self?.resolveImageSizes(atUrlSets: sources)
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
                self?.selectableImages = foundImages ?? []
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

    private func resolveImageSizes(atUrlSets urlSets: [WebImageUrlSet]) -> [SelectableImage] {
        return urlSets
            .compactMap { urlSet in
                guard let imageSource = CGImageSourceCreateWithURL(urlSet.url as CFURL, nil) else {
                    return nil
                }
                guard
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
                else {
                    return nil
                }
                return SelectableImage(url: urlSet.url,
                                       alternativeUrl: urlSet.alternativeUrl,
                                       height: pixelHeight,
                                       width: pixelWidth)
            }
            .filter { $0.isValid }
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
        let currentDate = self.currentDateResolver()
        let clipId = UUID()
        let items = target.map {
            ClipItem(id: UUID(),
                     url: self.url,
                     clipId: clipId,
                     index: $0.index,
                     source: $0.source,
                     currentDate: currentDate)
        }
        let clip = Clip(clipId: clipId,
                        clipItems: items,
                        tags: [],
                        registeredDate: currentDate,
                        currentDate: currentDate)
        let data = target.map { ($0.source.fileName, $0.source.data) }

        switch self.clipStore.create(clip: clip, withData: data, forced: false) {
        case .success:
            return .success(())

        case let .failure(error):
            return .failure(.failedToSave(error))
        }
    }
}

extension ClipItem {
    init(id: ClipItem.Identity, url: URL, clipId: Clip.Identity, index: Int, source: ClipItemSource, currentDate: Date) {
        self.init(id: id,
                  url: url,
                  clipId: clipId,
                  clipIndex: index,
                  imageId: UUID(),
                  imageFileName: source.fileName,
                  imageUrl: source.url,
                  imageSize: ImageSize(height: source.height, width: source.width),
                  registeredDate: currentDate,
                  updatedDate: currentDate)
    }
}

extension Clip {
    init(clipId: Clip.Identity, clipItems: [ClipItem], tags: [Tag], registeredDate: Date, currentDate: Date) {
        self.init(id: clipId,
                  description: nil,
                  items: clipItems,
                  tags: tags,
                  isHidden: false,
                  registeredDate: registeredDate,
                  updatedDate: currentDate)
    }
}
