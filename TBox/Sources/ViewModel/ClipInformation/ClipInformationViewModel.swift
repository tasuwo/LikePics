//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit

protocol ClipInformationViewModelType {
    var inputs: ClipInformationViewModelInputs { get }
    var outputs: ClipInformationViewModelOutputs { get }
}

protocol ClipInformationViewModelInputs {
    func replaceTagsOfClip(_ tagIds: Set<Tag.Identity>)
    func removeTagFromClip(_ tag: Tag)
    func update(isHidden: Bool)
    func update(siteUrl: URL?)
}

protocol ClipInformationViewModelOutputs {
    var info: AnyPublisher<ClipInformationLayout.Information, Never> { get }
    var tagIdsValue: [Tag.Identity] { get }

    var close: PassthroughSubject<Void, Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
}

class ClipInformationViewModel: ClipInformationViewModelType,
    ClipInformationViewModelInputs,
    ClipInformationViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipInformationViewModelType

    var inputs: ClipInformationViewModelInputs { self }
    var outputs: ClipInformationViewModelOutputs { self }

    // MARK: ClipInformationViewModelInputs

    // MARK: ClipInformationViewModelOutputs

    var info: AnyPublisher<ClipInformationLayout.Information, Never> { _info.eraseToAnyPublisher() }
    var tagIdsValue: [Tag.Identity] { tagListQuery.tags.value.map { $0.id } }

    let close: PassthroughSubject<Void, Never> = .init()
    let errorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    let itemId: ClipItem.Identity

    private let _info: CurrentValueSubject<ClipInformationLayout.Information, Never>

    private let clipQuery: ClipQuery
    private let itemQuery: ClipItemQuery
    private let tagListQuery: TagListQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(itemId: ClipItem.Identity,
         clipQuery: ClipQuery,
         itemQuery: ClipItemQuery,
         tagListQuery: TagListQuery,
         clipCommandService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.itemId = itemId
        self.clipQuery = clipQuery
        self.itemQuery = itemQuery
        self.tagListQuery = tagListQuery
        self.clipCommandService = clipCommandService
        self.settingStorage = settingStorage
        self.logger = logger

        self._info = .init(.init(clip: clipQuery.clip.value,
                                 tags: tagListQuery.tags.value,
                                 item: itemQuery.clipItem.value))

        self.bind()
    }

    // MARK: - Methods

    func bind() {
        self.itemQuery.clipItem
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { _ in
                // NOP
            }
            .store(in: &self.subscriptions)

        self.clipQuery.clip
            .combineLatest(itemQuery.clipItem, tagListQuery.tags, settingStorage.showHiddenItems.mapError({ _ -> Error in NSError() }))
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.close.send(())

                case let .failure(error):
                    self?.logger.write(ConsoleLog(level: .error, message: "Error occurred. (error: \(error.localizedDescription))"))
                    self?.errorMessage.send(L10n.clipInformationErrorAtReadClip)
                }
            }, receiveValue: { [weak self] clip, item, tags, showHiddenItems in
                self?._info.send(.init(clip: clip,
                                       tags: showHiddenItems ? tags : tags.filter({ !$0.isHidden }),
                                       item: item))
            })
            .store(in: &self.subscriptions)
    }

    func replaceTagsOfClip(_ tagIds: Set<Tag.Identity>) {
        let clipId = _info.value.clip.id
        if case let .failure(error) = self.clipCommandService.updateClips(having: [clipId], byReplacingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to replace tags. (code: \(error.rawValue))"))
            self.errorMessage.send(L10n.clipInformationErrorAtReplaceTags)
        }
    }

    func removeTagFromClip(_ tag: Tag) {
        let clipId = _info.value.clip.id
        if case let .failure(error) = self.clipCommandService.updateClips(having: [clipId], byDeletingTagsHaving: [tag.identity]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.errorMessage.send(L10n.clipInformationErrorAtRemoveTags)
        }
    }

    func update(isHidden: Bool) {
        let clipId = _info.value.clip.id
        if case let .failure(error) = self.clipCommandService.updateClips(having: [clipId], byHiding: isHidden) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to update. (code: \(error.rawValue))"))
            self.errorMessage.send(L10n.clipInformationErrorAtUpdateHidden)
        }
    }

    func update(siteUrl: URL?) {
        if case let .failure(error) = self.clipCommandService.updateClipItems(having: [self.itemId], byUpdatingSiteUrl: siteUrl) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to update. (code: \(error.rawValue))"))
            self.errorMessage.send(L10n.clipInformationErrorAtUpdateSiteUrl)
        }
    }
}
