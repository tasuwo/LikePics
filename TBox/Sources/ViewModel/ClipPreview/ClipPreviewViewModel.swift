//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

protocol ClipPreviewViewModelType {
    var inputs: ClipPreviewViewModelInputs { get }
    var outputs: ClipPreviewViewModelOutputs { get }
}

protocol ClipPreviewViewModelInputs {}

protocol ClipPreviewViewModelOutputs {
    var itemIdValue: ClipItem.Identity { get }
    var itemUrlValue: URL? { get }

    var isLoading: AnyPublisher<Bool, Never> { get }

    var dismiss: PassthroughSubject<Void, Never> { get }
    var displayImage: PassthroughSubject<UIImage, Never> { get }
    var displayErrorMessage: PassthroughSubject<String, Never> { get }

    func readPreview() -> ClipPreviewView.Source?
}

class ClipPreviewViewModel: ClipPreviewViewModelType,
    ClipPreviewViewModelInputs,
    ClipPreviewViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipPreviewViewModelType

    var inputs: ClipPreviewViewModelInputs { self }
    var outputs: ClipPreviewViewModelOutputs { self }

    // MARK: ClipPreviewViewModelInputs

    let viewWillAppear: PassthroughSubject<Void, Never> = .init()
    let viewDidAppear: PassthroughSubject<Void, Never> = .init()

    // MARK: ClipPreviewViewModelOutputs

    var itemIdValue: ClipItem.Identity { _item.value.id }
    var itemUrlValue: URL? { _item.value.url }

    var isLoading: AnyPublisher<Bool, Never> { _isLoading.eraseToAnyPublisher() }

    let dismiss: PassthroughSubject<Void, Never> = .init()
    let displayImage: PassthroughSubject<UIImage, Never> = .init()
    let displayErrorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private let _item: CurrentValueSubject<ClipItem, Never>
    private let _isLoading: CurrentValueSubject<Bool, Never> = .init(false)

    private let query: ClipItemQuery
    private let previewLoader: PreviewLoaderProtocol
    private let usesImageForPresentingAnimation: Bool
    private let logger: TBoxLoggable

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: ClipItemQuery,
         previewLoader: PreviewLoaderProtocol,
         usesImageForPresentingAnimation: Bool,
         logger: TBoxLoggable)
    {
        self.query = query
        self.previewLoader = previewLoader
        self.usesImageForPresentingAnimation = usesImageForPresentingAnimation
        self.logger = logger

        self._item = .init(query.clipItem.value)

        self.bind()
    }
}

extension ClipPreviewViewModel {
    // MARK: - Load Preview

    func readPreview() -> ClipPreviewView.Source? {
        let item = _item.value

        if let preview = previewLoader.readCache(forImageId: item.imageId) {
            return .image(.init(uiImage: preview))
        }

        if let preview = previewLoader.readThumbnail(forItemId: item.id) {
            self.loadPreview()
            return .thumbnail(.init(uiImage: preview, originalSize: item.imageSize.cgSize))
        }

        if usesImageForPresentingAnimation {
            // クリップ一覧からプレビュー画面への遷移時に、サムネイルのキャッシュが既に揮発している
            // 可能性もある。そのような場合には遷移アニメーションが若干崩れてしまう
            // これを防ぐため、若干の操作のスムーズさを犠牲にして同期的に downsampling する
            var source: ClipPreviewView.Source?
            let semaphore = DispatchSemaphore(value: 0)

            self.previewLoader.loadPreview(forImageId: _item.value.imageId) { [weak self] image in
                defer { semaphore.signal() }
                guard let image = image else {
                    self?.displayErrorMessage.send(L10n.clipPreviewErrorAtLoadImage)
                    return
                }
                source = .image(.init(uiImage: image))
            }

            semaphore.wait()

            return source
        } else {
            self.loadPreview()
            return nil
        }
    }

    private func loadPreview() {
        self._isLoading.send(true)
        self.previewLoader.loadPreview(forImageId: _item.value.imageId) { [weak self] image in
            guard let image = image else {
                self?.displayErrorMessage.send(L10n.clipPreviewErrorAtLoadImage)
                return
            }
            self?._isLoading.send(false)
            self?.displayImage.send(image)
        }
    }
}

extension ClipPreviewViewModel {
    // MARK: - Bind

    private func bind() {
        self.query.clipItem
            .sink { [weak self] _ in
                self?.dismiss.send(())
            } receiveValue: { [weak self] item in
                self?._item.send(item)
            }
            .store(in: &self.subscriptions)
    }
}
