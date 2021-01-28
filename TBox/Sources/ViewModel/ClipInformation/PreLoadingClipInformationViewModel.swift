//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit

protocol PreLoadingClipInformationViewModelType {
    var inputs: PreLoadingClipInformationViewModelInputs { get }
    var outputs: PreLoadingClipInformationViewModelOutputs { get }
}

protocol PreLoadingClipInformationViewModelInputs {
    func startPreloading(clipId: Clip.Identity, itemId: ClipItem.Identity)
    func stopPreloading()
}

protocol PreLoadingClipInformationViewModelOutputs {
    var isPreloading: Bool { get }
    var info: AnyPublisher<ClipInformationLayout.Information, Never> { get }
}

class PreLoadingClipInformationViewModel: PreLoadingClipInformationViewModelType,
    PreLoadingClipInformationViewModelInputs,
    PreLoadingClipInformationViewModelOutputs
{
    // MARK: - Properties

    // MARK: PreLoadingClipInformationViewModelType

    var inputs: PreLoadingClipInformationViewModelInputs { self }
    var outputs: PreLoadingClipInformationViewModelOutputs { self }

    // MARK: PreLoadingClipInformationViewModelInputs

    // MARK: PreLoadingClipInformationViewModelOutputs

    var isPreloading: Bool { !subscriptions.isEmpty }
    var info: AnyPublisher<ClipInformationLayout.Information, Never> { _info.eraseToAnyPublisher() }

    // MARK: Internal

    private let _info: CurrentValueSubject<ClipInformationLayout.Information, Never>

    private var clipQuery: ClipQuery?
    private var itemQuery: ClipItemQuery?
    private var tagListQuery: TagListQuery?

    private let clipQueryService: ClipQueryServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(clipQueryService: ClipQueryServiceProtocol,
         settingStorage: UserSettingsStorageProtocol)
    {
        self._info = .init(.initialValue)
        self.clipQueryService = clipQueryService
        self.settingStorage = settingStorage
    }

    // MARK: - Methods

    func startPreloading(clipId: Clip.Identity, itemId: ClipItem.Identity) {
        let clipQuery: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            clipQuery = result

        case .failure:
            return
        }

        let itemQuery: ClipItemQuery
        switch self.clipQueryService.queryClipItem(having: itemId) {
        case let .success(result):
            itemQuery = result

        case .failure:
            return
        }

        let tagListQuery: TagListQuery
        switch self.clipQueryService.queryTags(forClipHaving: clipId) {
        case let .success(result):
            tagListQuery = result

        case .failure:
            return
        }

        self.clipQuery = clipQuery
        self.itemQuery = itemQuery
        self.tagListQuery = tagListQuery

        self._info.send(.init(clip: clipQuery.clip.value,
                              tags: tagListQuery.tags.value,
                              item: itemQuery.clipItem.value))

        self.subscriptions.forEach { $0.cancel() }

        clipQuery.clip
            .combineLatest(itemQuery.clipItem,
                           tagListQuery.tags,
                           settingStorage.showHiddenItems.mapError({ _ -> Error in NSError() }))
            .sink(receiveCompletion: { [weak self] _ in
                self?._info.send(.initialValue)
            }, receiveValue: { [weak self] clip, item, tags, showHiddenItems in
                let information = ClipInformationLayout.Information(clip: clip,
                                                                    tags: showHiddenItems ? tags : tags.filter({ !$0.isHidden }),
                                                                    item: item)
                guard information != self?._info.value else { return }
                self?._info.send(information)
            })
            .store(in: &self.subscriptions)
    }

    func stopPreloading() {
        self.subscriptions.forEach { $0.cancel() }
        self.subscriptions.removeAll()
    }
}

private extension ClipInformationLayout.Information {
    static var initialValue: Self {
        return .init(clip: .init(id: UUID(),
                                 description: nil,
                                 items: [],
                                 isHidden: false,
                                 dataSize: 0,
                                 registeredDate: Date(timeIntervalSince1970: 0),
                                 updatedDate: Date(timeIntervalSince1970: 0)),
                     tags: [],
                     item: .init(id: UUID(),
                                 url: nil,
                                 clipId: UUID(),
                                 clipIndex: 0,
                                 imageId: UUID(),
                                 imageFileName: "",
                                 imageUrl: nil,
                                 imageSize: .init(height: 0, width: 0),
                                 imageDataSize: 0,
                                 registeredDate: Date(timeIntervalSince1970: 0),
                                 updatedDate: Date(timeIntervalSince1970: 0)))
    }
}
