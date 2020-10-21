//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol AlbumListViewProtocol: AnyObject {
    func apply(_ albums: [Album])
    func reload()
    func showErrorMessage(_ message: String)
}

class AlbumListPresenter {
    private let query: AlbumListQuery
    private let storage: ClipStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()
    private var showHiddenItems: Bool = false {
        didSet {
            if oldValue != self.showHiddenItems {
                self.view?.reload()
            }
        }
    }

    private(set) var albums: [Album] = [] {
        didSet {
            self.view?.apply(self.albums)
        }
    }

    weak var view: AlbumListViewProtocol?

    // MARK: - Lifecycle

    init(query: AlbumListQuery,
         storage: ClipStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.storage = storage
        self.settingStorage = settingStorage
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        self.query
            .albums
            .catch { _ -> AnyPublisher<[Album], Never> in
                return Just([Album]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at AlbumListView."))
            }, receiveValue: { [weak self] albums, showHiddenItems in
                guard let self = self else { return }
                self.albums = albums
                    .sorted(by: { $0.registeredDate > $1.registeredDate })
                self.showHiddenItems = showHiddenItems
            })
            .store(in: &self.cancellableBag)
    }

    func addAlbum(title: String) {
        if case let .failure(error) = self.storage.create(albumWithTitle: title) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add album. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtAddAlbum)\n(\(error.makeErrorCode())")
        }
    }

    func deleteAlbum(_ album: Album) {
        if case let .failure(error) = self.storage.deleteAlbum(having: album.identity) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete album. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtDeleteAlbum)\n(\(error.makeErrorCode())")
        }
    }
}
