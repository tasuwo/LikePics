//
//  DummyContainer.swift
//  Snapshot
//
//  Created by Tasuku Tozawa on 2022/03/21.
//

import AppFeature
import Combine
import Common
import Domain
import LikePicsCore
import LikePicsUIKit
import Smoothie
import TestHelper

class DummyContainer: AppDependencyContaining {
    var modalNotificationCenter: ModalNotificationCenter
    var clipCommandService: ClipCommandServiceProtocol
    var clipQueryService: ClipQueryServiceProtocol
    var clipSearchHistoryService: ClipSearchHistoryService
    var clipSearchSettingService: ClipSearchSettingService
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol
    var cloudStackLoader: CloudStackLoadable
    var clipDiskCache: DiskCaching
    var albumDiskCache: DiskCaching
    var clipItemDiskCache: DiskCaching
    var clipThumbnailPipeline: Pipeline
    var albumThumbnailPipeline: Pipeline
    var clipItemThumbnailPipeline: Pipeline
    var temporaryThumbnailPipeline: Pipeline
    var previewPipeline: Pipeline
    var previewPrefetcher: PreviewPrefetchable
    var imageQueryService: ImageQueryServiceProtocol
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol
    var logger: Loggable
    var pasteboard: Pasteboard
    var tagCommandService: TagCommandServiceProtocol
    var temporariesPersistService: TemporariesPersistServiceProtocol
    var transitionLock: TransitionLock
    var userSettingStorage: UserSettingsStorageProtocol
    var clipStore: ClipStorable

    init() {
        modalNotificationCenter = .default
        clipCommandService = ClipCommandServiceProtocolMock()

        let _clipQueryService = ClipQueryServiceProtocolMock()
        _clipQueryService.queryAllClipsHandler = {
            let query = ClipListQueryMock()
            query.clips = .init(SampleDataSetProvider.clips)
            return .success(query)
        }
        _clipQueryService.queryClipHandler = { id in
            let query = ClipQueryMock()
            query.clip = .init(SampleDataSetProvider.clip(for: id)!)
            return .success(query)
        }
        _clipQueryService.queryClipItemHandler = { id in
            let query = ClipItemQueryMock()
            query.clipItem = .init(SampleDataSetProvider.clipItem(for: id)!)
            return .success(query)
        }
        _clipQueryService.queryAllTagsHandler = {
            let query = TagListQueryMock()
            query.tags = .init(SampleDataSetProvider.tags)
            return .success(query)
        }
        _clipQueryService.queryTagsHandler = { _ in
            let query = TagListQueryMock()
            query.tags = .init([.makeDefault(name: "食べ物"), .makeDefault(name: "寿司")])
            return .success(query)
        }
        _clipQueryService.queryAllAlbumsHandler = {
            let query = AlbumListQueryMock()
            query.albums = .init(SampleDataSetProvider.albums)
            return .success(query)
        }
        _clipQueryService.queryAlbumsHandler = { _ in
            let query = ListingAlbumListQueryMock()
            query.albums = .init([.makeDefault(title: "旅行")])
            return .success(query)
        }
        clipQueryService = _clipQueryService

        clipSearchHistoryService = ClipSearchHistoryServiceMock()
        clipSearchSettingService = ClipSearchSettingServiceMock()
        cloudAvailabilityService = CloudAvailabilityServiceProtocolMock()
        cloudStackLoader = CloudStackLoadableMock()

        let diskCache = DiskCachingMock()
        diskCache.removeAllHandler = {}
        clipDiskCache = diskCache
        albumDiskCache = diskCache
        clipItemDiskCache = diskCache

        let pipeline = Pipeline()
        clipThumbnailPipeline = pipeline
        albumThumbnailPipeline = pipeline
        clipItemThumbnailPipeline = pipeline
        temporaryThumbnailPipeline = pipeline
        previewPipeline = pipeline

        let _previewPrefetcher = PreviewPrefetchableMock()
        _previewPrefetcher.clip = .init(nil)
        previewPrefetcher = _previewPrefetcher

        let _imageQueryService = ImageQueryServiceProtocolMock()
        _imageQueryService.readHandler = { id in
            SampleDataSetProvider.image(for: id)
        }
        imageQueryService = _imageQueryService

        integrityValidationService = ClipReferencesIntegrityValidationServiceProtocolMock()
        logger = LoggableMock()
        pasteboard = PasteboardMock()
        tagCommandService = TagCommandServiceProtocolMock()
        temporariesPersistService = TemporariesPersistServiceProtocolMock()
        transitionLock = TransitionLock()

        let _userSettingStorage = UserSettingsStorageProtocolMock()
        _userSettingStorage.showHiddenItems = CurrentValueSubject(true).eraseToAnyPublisher()
        _userSettingStorage.readShowHiddenItemsHandler = { true }
        userSettingStorage = _userSettingStorage

        clipStore = ClipStorableMock()
    }
}
