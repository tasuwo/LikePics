//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

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
    var clip: CurrentValueSubject<Clip, Never> { get }
    var clipItem: CurrentValueSubject<ClipItem, Never> { get }
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

    let clip: CurrentValueSubject<Clip, Never>
    let clipItem: CurrentValueSubject<ClipItem, Never>
    let close: PassthroughSubject<Void, Never> = .init()
    let errorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    let itemId: ClipItem.Identity

    private let clipQuery: ClipQuery
    private let itemQuery: ClipItemQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(itemId: ClipItem.Identity,
         clipQuery: ClipQuery,
         itemQuery: ClipItemQuery,
         clipCommandService: ClipCommandServiceProtocol,
         logger: TBoxLoggable)
    {
        self.itemId = itemId
        self.clipQuery = clipQuery
        self.itemQuery = itemQuery
        self.clipCommandService = clipCommandService
        self.logger = logger

        self.clip = .init(clipQuery.clip.value)
        self.clipItem = .init(itemQuery.clipItem.value)

        self.bind()
    }

    // MARK: - Methods

    func bind() {
        self.clipQuery.clip
            .combineLatest(itemQuery.clipItem)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.close.send(())

                case let .failure(error):
                    self?.logger.write(ConsoleLog(level: .error, message: "Error occurred. (error: \(error.localizedDescription))"))
                    self?.errorMessage.send(L10n.clipInformationErrorAtReadClip)
                }
            }, receiveValue: { [weak self] clip, item in
                self?.clip.send(clip)
                self?.clipItem.send(item)
            })
            .store(in: &self.cancellableBag)
    }

    func replaceTagsOfClip(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clip.value.identity], byReplacingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to replace tags. (code: \(error.rawValue))"))
            self.errorMessage.send(L10n.clipInformationErrorAtReplaceTags)
        }
    }

    func removeTagFromClip(_ tag: Tag) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clip.value.identity], byDeletingTagsHaving: [tag.identity]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.errorMessage.send(L10n.clipInformationErrorAtRemoveTags)
        }
    }

    func update(isHidden: Bool) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clip.value.identity], byHiding: isHidden) {
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
