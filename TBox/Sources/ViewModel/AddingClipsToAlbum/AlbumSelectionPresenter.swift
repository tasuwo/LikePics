//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol AlbumSelectionPresenterDelegate: AnyObject {
    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?)
}

protocol AlbumSelectionViewProtocol: AnyObject {
    func apply(_ albums: [Album])
    func reload()
    func showErrorMessage(_ message: String)
    func close()
}

class AlbumSelectionPresenter {
    private let query: AlbumListQuery
    private let context: Any?
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    private(set) var albums: [Album] = [] {
        didSet {
            self.view?.apply(self.albums)
        }
    }

    private var showHiddenItems: Bool = false {
        didSet {
            if oldValue != self.showHiddenItems {
                self.view?.reload()
            }
        }
    }

    weak var delegate: AlbumSelectionPresenterDelegate?
    weak var view: AlbumSelectionViewProtocol?

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
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at AlbumSelectionPresenter."))
            }, receiveValue: { [weak self] albums, showHiddenItems in
                guard let self = self else { return }
                self.albums = albums
                    .sorted(by: { $0.registeredDate > $1.registeredDate })
                self.showHiddenItems = showHiddenItems
            })
            .store(in: &self.cancellableBag)
    }

    func select(albumId: Album.Identity) {
        self.delegate?.albumSelectionPresenter(self, didSelectAlbumHaving: albumId, withContext: self.context)
        self.view?.close()
    }

    func addAlbum(title: String) {
        if case let .failure(error) = self.clipCommandService.create(albumWithTitle: title) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add album. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtAddAlbum)\n(\(error.makeErrorCode())")
        }
    }
}
