//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol AlbumSelectionViewModelType {
    var inputs: AlbumSelectionViewModelInputs { get }
    var outputs: AlbumSelectionViewModelOutputs { get }
}

protocol AlbumSelectionViewModelInputs {
    var inputtedQuery: PassthroughSubject<String, Never> { get }
    var addedAlbum: PassthroughSubject<String, Never> { get }
    var selectedAlbum: PassthroughSubject<Album.Identity, Never> { get }
}

protocol AlbumSelectionViewModelOutputs {
    var albums: AnyPublisher<[Album], Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
    var displayEmptyMessage: AnyPublisher<Bool, Never> { get }
    var close: PassthroughSubject<Void, Never> { get }
}

protocol AlbumSelectionPresenterDelegate: AnyObject {
    func albumSelectionPresenter(_ presenter: AlbumSelectionViewModel, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?)
}

class AlbumSelectionViewModel: AlbumSelectionViewModelType,
    AlbumSelectionViewModelInputs,
    AlbumSelectionViewModelOutputs
{
    // MARK: - Properties

    // MARK: AlbumSelectionViewModelType

    var inputs: AlbumSelectionViewModelInputs { self }
    var outputs: AlbumSelectionViewModelOutputs { self }

    // MARK: AlbumSelectionViewModelInputs

    let inputtedQuery: PassthroughSubject<String, Never> = .init()
    let addedAlbum: PassthroughSubject<String, Never> = .init()
    let selectedAlbum: PassthroughSubject<Album.Identity, Never> = .init()

    // MARK: AlbumSelectionViewModelOutputs

    var albums: AnyPublisher<[Album], Never> {
        _filteredAlbumIds
            .map { $0.compactMap { [weak self] id in self?._albums.value[id] } }
            .combineLatest(settingStorage.showHiddenItems)
            .map { albums, showHiddenItems in
                guard showHiddenItems == false else { return albums }
                return albums.map { $0.removingHiddenClips() }
            }
            .eraseToAnyPublisher()
    }

    let errorMessage: PassthroughSubject<String, Never> = .init()
    var displayEmptyMessage: AnyPublisher<Bool, Never> { _displayEmptyMessage.eraseToAnyPublisher() }
    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private let _albums: CurrentValueSubject<[Album.Identity: Album], Never> = .init([:])
    private let _filteredAlbumIds: CurrentValueSubject<[Album.Identity], Never> = .init([])
    private let _displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)

    private let query: AlbumListQuery
    private let context: Any?
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable
    private var searchStorage: SearchableStorage<Album> = .init()

    private var subscriptions = Set<AnyCancellable>()

    weak var delegate: AlbumSelectionPresenterDelegate?

    // MARK: - Lifecycle

    init(query: AlbumListQuery,
         context: Any?,
         clipCommandService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.context = context
        self.clipCommandService = clipCommandService
        self.settingStorage = settingStorage
        self.logger = logger

        self.bind()
    }
}

extension AlbumSelectionViewModel {
    // MARK: - Bind

    private func bind() {
        self.query.albums
            .catch { _ -> AnyPublisher<[Album], Never> in
                return Just([Album]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(inputtedQuery, settingStorage.showHiddenItems)
            .sink { [weak self] originalAlbums, query, showHiddenItems in
                guard let self = self else { return }

                let albums = originalAlbums.reduce(into: [Album.Identity: Album]()) { dict, value in
                    dict[value.id] = value
                }

                let filteringAlbums = originalAlbums.filter { showHiddenItems ? true : $0.isHidden == false }
                let filteredAlbumIds = self.searchStorage.perform(query: query, to: filteringAlbums).map { $0.id }

                if filteringAlbums.isEmpty {
                    self._displayEmptyMessage.send(true)
                } else {
                    self._displayEmptyMessage.send(false)
                }

                self._albums.send(albums)
                self._filteredAlbumIds.send(filteredAlbumIds)
            }
            .store(in: &self.subscriptions)

        self.inputtedQuery.send("")

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
            .store(in: &self.subscriptions)

        self.selectedAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                self.delegate?.albumSelectionPresenter(self, didSelectAlbumHaving: albumId, withContext: self.context)
                self.close.send(())
            }
            .store(in: &self.subscriptions)
    }
}
