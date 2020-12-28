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
    var addedAlbum: PassthroughSubject<String, Never> { get }
    var deletedAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var editedAlbumTitle: PassthroughSubject<(Album.Identity, String), Never> { get }
}

protocol AlbumListViewModelOutputs {
    var albums: CurrentValueSubject<[Album], Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }
    var isEditButtonEnabled: CurrentValueSubject<Bool, Never> { get }
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
    let editedAlbumTitle: PassthroughSubject<(Album.Identity, String), Never> = .init()

    // MARK: AlbumListViewModelOutputs

    let albums: CurrentValueSubject<[Album], Never>
    let errorMessage: PassthroughSubject<String, Never> = .init()
    let displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)
    let isEditButtonEnabled: CurrentValueSubject<Bool, Never> = .init(false)

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
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink { [weak self] albums, showHiddenItems in
                guard let self = self else { return }

                let newAlbums: [Album]
                if showHiddenItems {
                    newAlbums = albums.sorted(by: { $0.registeredDate > $1.registeredDate })
                } else {
                    newAlbums = albums
                        .sorted(by: { $0.registeredDate > $1.registeredDate })
                        .map { $0.removingHiddenClips() }
                }

                self.albums.send(newAlbums)
                self.displayEmptyMessage.send(albums.isEmpty)
                self.isEditButtonEnabled.send(!albums.isEmpty)
            }
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

        self.editedAlbumTitle
            .sink { [weak self] albumId, newTitle in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, titleTo: newTitle) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete album. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtDeleteAlbum)
                }
            }
            .store(in: &self.cancellableBag)
    }
}
