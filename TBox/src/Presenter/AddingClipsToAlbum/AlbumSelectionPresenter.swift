//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol AlbumSelectionPresenterDelegate: AnyObject {
    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbum: Album.Identity)
}

protocol AlbumSelectionViewProtocol: AnyObject {
    func apply(_ albums: [Album])
    func showErrorMassage(_ message: String)
    func close()
}

class AlbumSelectionPresenter {
    private let query: AlbumListQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    private(set) var albums: [Album] = [] {
        didSet {
            self.view?.apply(self.albums)
        }
    }

    weak var delegate: AlbumSelectionPresenterDelegate?
    weak var view: AlbumSelectionViewProtocol?

    // MARK: - Lifecycle

    init(query: AlbumListQuery, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.query = query
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        self.query
            .albums
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at AlbumSelectionPresenter."))
            }, receiveValue: { [weak self] albums in
                self?.albums = albums
            })
            .store(in: &self.cancellableBag)
    }

    func select(albumId: Album.Identity) {
        self.delegate?.albumSelectionPresenter(self, didSelectAlbum: albumId)
        self.view?.close()
    }
}
