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
    var operation: CurrentValueSubject<AlbumList.Operation, Never> { get }

    var addedAlbum: PassthroughSubject<String, Never> { get }
    var deletedAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var hidedAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var revealedAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var reorderedAlbums: PassthroughSubject<[Album.Identity], Never> { get }
    var editedAlbumTitle: PassthroughSubject<(Album.Identity, String), Never> { get }
}

protocol AlbumListViewModelOutputs {
    var albums: CurrentValueSubject<[Album], Never> { get }
    var operation: CurrentValueSubject<AlbumList.Operation, Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }
    var dragInteractionEnabled: CurrentValueSubject<Bool, Never> { get }
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

    let addedAlbum: PassthroughSubject<String, Never> = .init()
    let deletedAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let hidedAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let revealedAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    var reorderedAlbums: PassthroughSubject<[Album.Identity], Never> = .init()
    let editedAlbumTitle: PassthroughSubject<(Album.Identity, String), Never> = .init()

    // MARK: AlbumListViewModelOutputs

    let albums: CurrentValueSubject<[Album], Never>
    let operation: CurrentValueSubject<AlbumList.Operation, Never> = .init(.none)
    let errorMessage: PassthroughSubject<String, Never> = .init()
    let displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)
    let dragInteractionEnabled: CurrentValueSubject<Bool, Never> = .init(false)

    // MARK: Privates

    private let query: AlbumListQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

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
        self.albums = .init(query.albums.value)

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
            .combineLatest(self.settingStorage.showHiddenItems, self.operation)
            .sink { [weak self] albums, showHiddenItems, operation in
                guard let self = self else { return }

                let newAlbums: [Album]
                if showHiddenItems {
                    newAlbums = albums
                } else {
                    newAlbums = albums
                        .filter { !$0.isHidden }
                        .map { $0.removingHiddenClips() }
                }

                self.albums.send(newAlbums)
                self.displayEmptyMessage.send(albums.isEmpty)

                if operation.isEditing, newAlbums.isEmpty {
                    self.operation.send(.none)
                }
            }
            .store(in: &self.cancellableBag)

        self.operation
            .map { $0.isEditing }
            .sink { [weak self] isEditing in self?.dragInteractionEnabled.send(isEditing) }
            .store(in: &self.cancellableBag)

        self.addedAlbum
            .sink { [weak self] title in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.create(albumWithTitle: title) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add album. (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtAddAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.deletedAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteAlbum(having: albumId) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete album. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtDeleteAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.hidedAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to hide album. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtHideAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.revealedAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to reveal album. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtRevealAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.reorderedAlbums
            .sink { [weak self] albumIds in
                guard let self = self else { return }

                let originals = self.query.albums.value.map({ $0.id })
                guard Set(originals).count == originals.count, Set(albumIds).count == albumIds.count else {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムの並び替えに失敗しました。IDに重複が存在します
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtReorderAlbum)
                    return
                }

                let ids = self.performReorder(originals: self.query.albums.value.map({ $0.id }), request: albumIds)
                if case let .failure(error) = self.clipCommandService.updateAlbums(byReordering: ids) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to reorder album. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtReorderAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.editedAlbumTitle
            .sink { [weak self] albumId, newTitle in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, titleTo: newTitle) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete album. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtEditAlbum)
                }
            }
            .store(in: &self.cancellableBag)
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
