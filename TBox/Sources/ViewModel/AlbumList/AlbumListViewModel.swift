//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol AlbumListViewModelType {
    var inputs: AlbumListViewModelInputs { get }
    var outputs: AlbumListViewModelOutputs { get }
}

protocol AlbumListViewModelInputs {
    var operationRequested: PassthroughSubject<AlbumList.Operation, Never> { get }

    var createAlbum: PassthroughSubject<String, Never> { get }
    var deleteAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var hideAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var revealAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var reorderAlbums: PassthroughSubject<[Album.Identity], Never> { get }
    var editAlbumTitle: PassthroughSubject<(Album.Identity, String), Never> { get }
}

protocol AlbumListViewModelOutputs {
    var albums: AnyPublisher<[AlbumListViewLayout.Item], Never> { get }
    var operation: AnyPublisher<AlbumList.Operation, Never> { get }
    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { get }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { get }
    var dragInteractionEnabled: AnyPublisher<Bool, Never> { get }

    var displayErrorMessage: PassthroughSubject<String, Never> { get }
}

class AlbumListViewModel: AlbumListViewModelType,
    AlbumListViewModelInputs,
    AlbumListViewModelOutputs
{
    // MARK: - Properties

    // MARK: AlbumListViewModelType

    var inputs: AlbumListViewModelInputs { self }
    var outputs: AlbumListViewModelOutputs { self }

    // MARK: AlbumListViewModelInputs

    let operationRequested: PassthroughSubject<AlbumList.Operation, Never> = .init()

    let createAlbum: PassthroughSubject<String, Never> = .init()
    let deleteAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let hideAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let revealAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let reorderAlbums: PassthroughSubject<[Album.Identity], Never> = .init()
    let editAlbumTitle: PassthroughSubject<(Album.Identity, String), Never> = .init()

    // MARK: AlbumListViewModelOutputs

    var albums: AnyPublisher<[AlbumListViewLayout.Item], Never> { _albums.eraseToAnyPublisher() }
    var operation: AnyPublisher<AlbumList.Operation, Never> { _operation.eraseToAnyPublisher() }
    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { _isCollectionViewDisplaying.eraseToAnyPublisher() }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { _isEmptyMessageDisplaying.eraseToAnyPublisher() }
    var dragInteractionEnabled: AnyPublisher<Bool, Never> { _dragInteractionEnabled.eraseToAnyPublisher() }

    let displayErrorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private let _albums: CurrentValueSubject<[AlbumListViewLayout.Item], Never>
    private let _operation: CurrentValueSubject<AlbumList.Operation, Never> = .init(.none)
    private let _isCollectionViewDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _isEmptyMessageDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _dragInteractionEnabled: CurrentValueSubject<Bool, Never> = .init(false)

    private let query: AlbumListQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: AlbumListQuery,
         clipCommandService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clipCommandService = clipCommandService
        self.settingStorage = settingStorage
        self.logger = logger

        let albums = query.albums.value
            .map { AlbumListViewLayout.Item(album: $0, isEditing: false) }
        self._albums = .init(albums)

        self.bind()
    }
}

extension AlbumListViewModel {
    // MARK: - Bind

    private func bind() {
        self.query.albums
            .catch { _ -> AnyPublisher<[Album], Never> in
                return Just([Album]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems, self._operation)
            .sink { [weak self] albums, showHiddenItems, operation in
                guard let self = self else { return }

                let newAlbums: [AlbumListViewLayout.Item]
                if showHiddenItems {
                    newAlbums = albums
                        .map({ AlbumListViewLayout.Item(album: $0, isEditing: operation.isEditing) })
                } else {
                    newAlbums = albums
                        .filter { !$0.isHidden }
                        .map { $0.removingHiddenClips() }
                        .map({ AlbumListViewLayout.Item(album: $0, isEditing: operation.isEditing) })
                }

                if newAlbums.isEmpty {
                    self._isCollectionViewDisplaying.send(false)
                    self._isEmptyMessageDisplaying.send(true)
                } else {
                    self._isEmptyMessageDisplaying.send(false)
                    self._isCollectionViewDisplaying.send(true)
                }

                self._albums.send(newAlbums)

                if operation.isEditing, newAlbums.isEmpty {
                    self._operation.send(.none)
                    return
                }
            }
            .store(in: &self.subscriptions)

        self.operationRequested
            .sink { [weak self] requested in self?._operation.send(requested) }
            .store(in: &self.subscriptions)

        self.operationRequested
            .map { $0.isEditing }
            .sink { [weak self] isEditing in self?._dragInteractionEnabled.send(isEditing) }
            .store(in: &self.subscriptions)

        self.createAlbum
            .sink { [weak self] title in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.create(albumWithTitle: title) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add album. (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    switch error {
                    case .duplicated:
                        self.displayErrorMessage.send(L10n.errorAlbumAddDuplicated)

                    default:
                        self.displayErrorMessage.send(L10n.albumListViewErrorAtAddAlbum)
                    }
                }
            }
            .store(in: &self.subscriptions)

        self.deleteAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteAlbum(having: albumId) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete album. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtDeleteAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.hideAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to hide album. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtHideAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.revealAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to reveal album. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtRevealAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.reorderAlbums
            .sink { [weak self] albumIds in
                guard let self = self else { return }

                let originals = self.query.albums.value.map({ $0.id })
                guard Set(originals).count == originals.count, Set(albumIds).count == albumIds.count else {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムの並び替えに失敗しました。IDに重複が存在します
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtReorderAlbum)
                    return
                }

                let ids = self.performReorder(originals: originals, request: albumIds)
                if case let .failure(error) = self.clipCommandService.updateAlbums(byReordering: ids) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to reorder album. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtReorderAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.editAlbumTitle
            .sink { [weak self] albumId, newTitle in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, titleTo: newTitle) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete album. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtEditAlbum)
                }
            }
            .store(in: &self.subscriptions)
    }

    private func performReorder(originals: [Album.Identity], request: [Album.Identity]) -> [Album.Identity] {
        var index = 0
        return originals
            .map { original in
                guard request.contains(original) else { return original }
                index += 1
                return request[index - 1]
            }
    }
}
