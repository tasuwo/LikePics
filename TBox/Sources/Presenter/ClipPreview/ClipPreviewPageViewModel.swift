//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipPreviewPageViewModelType {
    var inputs: ClipPreviewPageViewModelInputs { get }
    var outputs: ClipPreviewPageViewModelOutputs { get }
}

protocol ClipPreviewPageViewModelInputs {
    var currentClipItemId: CurrentValueSubject<ClipItem.Identity?, Never> { get }
    var deleteClip: PassthroughSubject<Void, Never> { get }
    var removeClipItem: PassthroughSubject<ClipItem.Identity, Never> { get }
    var replaceTags: PassthroughSubject<Set<Tag.Identity>, Never> { get }
    var addToAlbum: PassthroughSubject<Album.Identity, Never> { get }
}

protocol ClipPreviewPageViewModelOutputs {
    var clipId: Clip.Identity { get }
    var currentItem: CurrentValueSubject<ClipItem?, Never> { get }
    var items: CurrentValueSubject<[ClipItem], Never> { get }
    var tags: CurrentValueSubject<[Tag], Never> { get }

    var errorMessage: PassthroughSubject<String, Never> { get }

    var close: PassthroughSubject<Void, Never> { get }
}

class ClipPreviewPageViewModel: ClipPreviewPageViewModelType,
    ClipPreviewPageViewModelInputs,
    ClipPreviewPageViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipPreviewPageViewModelType

    var inputs: ClipPreviewPageViewModelInputs { self }
    var outputs: ClipPreviewPageViewModelOutputs { self }

    // MARK: ClipPreviewPageViewModelInputs

    let currentClipItemId: CurrentValueSubject<ClipItem.Identity?, Never> = .init(nil)
    let deleteClip: PassthroughSubject<Void, Never> = .init()
    let removeClipItem: PassthroughSubject<ClipItem.Identity, Never> = .init()
    let replaceTags: PassthroughSubject<Set<Tag.Identity>, Never> = .init()
    let addToAlbum: PassthroughSubject<Album.Identity, Never> = .init()

    // MARK: ClipPreviewPageViewModelOutputs

    let clipId: Clip.Identity
    let currentItem: CurrentValueSubject<ClipItem?, Never> = .init(nil)
    let items: CurrentValueSubject<[ClipItem], Never> = .init([])
    let tags: CurrentValueSubject<[Tag], Never> = .init([])

    let errorMessage: PassthroughSubject<String, Never> = .init()

    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private let query: ClipQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(clipId: Clip.Identity, query: ClipQuery, clipCommandService: ClipCommandServiceProtocol, logger: TBoxLoggable) {
        self.clipId = clipId
        self.query = query
        self.clipCommandService = clipCommandService
        self.logger = logger

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.bindInputs()
        self.bindOutputs()
    }

    private func bindInputs() {
        self.query.clip
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] clip in
                self?.items.send(clip.items)
                self?.tags.send(clip.tags)
            }
            .store(in: &self.cancellableBag)

        self.currentClipItemId
            .map { [weak self] itemId in
                self?.items.value.first(where: { $0.id == itemId })
            }
            .sink { [weak self] item in
                self?.currentItem.send(item)
            }
            .store(in: &self.cancellableBag)
    }

    private func bindOutputs() {
        self.deleteClip
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteClips(having: [self.clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clip having id \(self.clipId). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtDeleteClip)\n\(error.makeErrorCode())")
                }
            }
            .store(in: &self.cancellableBag)

        self.removeClipItem
            .sink { [weak self] itemId in
                guard let self = self else { return }
                guard let item = self.items.value.first(where: { $0.identity == itemId }) else { return }
                if case let .failure(error) = self.clipCommandService.deleteClipItem(item) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clip item having id \(itemId). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtRemoveItemFromClip)\n\(error.makeErrorCode())")
                }
            }
            .store(in: &self.cancellableBag)

        self.replaceTags
            .sink { [weak self] tagIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clipId], byReplacingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tags (\(tagIds.map({ $0.uuidString }).joined(separator: ", "))) to clip. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtAddTagsToClip)\n(\(error.makeErrorCode())")
                }
            }
            .store(in: &self.cancellableBag)

        self.addToAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [self.clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add clips to album having id \(albumId). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtAddClipsToAlbum)\n(\(error.makeErrorCode())")
                }
            }
            .store(in: &self.cancellableBag)
    }
}
