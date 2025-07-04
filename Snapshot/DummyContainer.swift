//
//  DummyContainer.swift
//  Snapshot
//
//  Created by Tasuku Tozawa on 2022/03/21.
//

import AppFeature
import ClipCreationFeature
import Combine
import Common
import Domain
import LikePicsUIKit
import Smoothie
import TestHelper

class DummyContainer: AppDependencyContaining {
    var modalNotificationCenter: ModalNotificationCenter
    var clipCommandService: ClipCommandService
    var clipQueryService: ClipQueryServiceProtocol
    var clipSearchHistoryService: ClipSearchHistoryService
    var clipSearchSettingService: ClipSearchSettingService
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol
    var cloudStackLoader: CloudStackLoadable
    var clipDiskCache: DiskCaching
    var albumDiskCache: DiskCaching
    var clipItemDiskCache: DiskCaching
    var clipThumbnailPipeline: ImageProcessingQueue
    var albumThumbnailPipeline: ImageProcessingQueue
    var clipItemThumbnailPipeline: ImageProcessingQueue
    var temporaryThumbnailPipeline: ImageProcessingQueue
    var previewPipeline: ImageProcessingQueue
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
    var appBundle = Bundle.main

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
            query.tags = .init([
                .makeDefault(name: NSLocalizedString("tag_06", comment: "")),
                .makeDefault(name: NSLocalizedString("tag_02", comment: "")),
            ])
            return .success(query)
        }
        _clipQueryService.queryAllAlbumsHandler = {
            let query = AlbumListQueryMock()
            query.albums = .init(SampleDataSetProvider.albums)
            return .success(query)
        }
        _clipQueryService.queryAlbumsHandler = { _ in
            let query = ListingAlbumListQueryMock()
            query.albums = .init([
                .makeDefault(title: NSLocalizedString("album_02", comment: ""))
            ])
            return .success(query)
        }
        clipQueryService = _clipQueryService

        clipSearchHistoryService = ClipSearchHistoryServiceMock()
        clipSearchSettingService = ClipSearchSettingServiceMock()

        let _cloudAvailabilityService = CloudAvailabilityServiceProtocolMock()
        _cloudAvailabilityService.currentAvailabilityHandler = { $0(.success(.available(.none))) }
        cloudAvailabilityService = _cloudAvailabilityService

        cloudStackLoader = CloudStackLoadableMock()

        let diskCache = DiskCachingMock()
        diskCache.removeAllHandler = {}
        clipDiskCache = diskCache
        albumDiskCache = diskCache
        clipItemDiskCache = diskCache

        let pipeline = ImageProcessingQueue()
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
        _userSettingStorage.userInterfaceStyle = CurrentValueSubject(.unspecified).eraseToAnyPublisher()
        _userSettingStorage.readUserInterfaceStyleHandler = { .unspecified }
        _userSettingStorage.readEnabledICloudSyncHandler = { true }
        userSettingStorage = _userSettingStorage

        clipStore = ClipStorableMock()
    }
}
