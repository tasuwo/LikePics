//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipMergeViewModelType {
    var inputs: ClipMergeViewModelInputs { get }
    var outputs: ClipMergeViewModelOutputs { get }
}

protocol ClipMergeViewModelInputs {
    var saved: PassthroughSubject<Void, Never> { get }
    var deleted: PassthroughSubject<Tag.Identity, Never> { get }
    var tagsSelected: PassthroughSubject<[Tag], Never> { get }
    var reordered: PassthroughSubject<[ClipItem], Never> { get }
}

protocol ClipMergeViewModelOutputs {
    var items: CurrentValueSubject<[ClipItem], Never> { get }
    var tags: CurrentValueSubject<[Tag], Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
    var close: PassthroughSubject<Void, Never> { get }
}

class ClipMergeViewModel: ClipMergeViewModelType,
    ClipMergeViewModelInputs,
    ClipMergeViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipMergeViewModelType

    var inputs: ClipMergeViewModelInputs { self }
    var outputs: ClipMergeViewModelOutputs { self }

    // MARK: ClipMergeViewModelInputs

    let saved: PassthroughSubject<Void, Never> = .init()
    let deleted: PassthroughSubject<Tag.Identity, Never> = .init()
    let tagsSelected: PassthroughSubject<[Tag], Never> = .init()
    let reordered: PassthroughSubject<[ClipItem], Never> = .init()

    // MARK: ClipMergeViewModelOutputs

    let items: CurrentValueSubject<[ClipItem], Never>
    let tags: CurrentValueSubject<[Tag], Never>
    let errorMessage: PassthroughSubject<String, Never> = .init()
    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private let clips: [Clip]
    private let commandService: ClipCommandServiceProtocol
    private let logger: TBoxLoggable
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(clips: [Clip], commandService: ClipCommandServiceProtocol, logger: TBoxLoggable) {
        self.clips = clips
        self.commandService = commandService
        self.logger = logger
        self.items = .init(Array(Set(clips.flatMap({ $0.items }))))
        self.tags = .init(Array(Set(clips.flatMap({ $0.tags }))))

        self.bind()
    }
}

extension ClipMergeViewModel {
    // MARK: - Bind

    func bind() {
        self.saved
            .sink { [weak self] in
                guard let self = self else { return }
                if case let .failure(error) = self.commandService.mergeClipItems(itemIds: self.items.value.map { $0.id },
                                                                                 tagIds: self.tags.value.map { $0.id },
                                                                                 inClipsHaving: self.clips.map { $0.id })
                {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to merge clips. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipMergeViewErrorAtMerge)
                    self.close.send(())
                    return
                }
                return self.close.send(())
            }
            .store(in: &self.cancellableBag)

        self.deleted
            .sink { [weak self] tagId in
                guard let self = self else { return }
                self.tags.send(self.tags.value.filter({ $0.id != tagId }))
            }
            .store(in: &self.cancellableBag)

        self.tagsSelected
            .sink { [weak self] selections in
                self?.tags.send(selections)
            }
            .store(in: &self.cancellableBag)

        self.reordered
            .sink { [weak self] items in
                self?.items.send(items)
            }
            .store(in: &self.cancellableBag)
    }
}
