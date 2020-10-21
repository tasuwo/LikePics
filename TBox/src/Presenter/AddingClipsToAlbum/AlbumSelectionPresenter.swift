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
    private let storage: ClipStorageProtocol
    private let cacheStorage: ThumbnailStorageProtocol
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
         storage: ClipStorageProtocol,
         cacheStorage: ThumbnailStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.context = context
        self.storage = storage
        self.cacheStorage = cacheStorage
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

    func readImageIfExists(for album: Album) -> UIImage? {
        guard let clipItem = self.resolveThumbnailItem(for: album) else { return nil }
        return self.cacheStorage.readThumbnailIfExists(for: clipItem)
    }

    func fetchImage(for album: Album, completion: @escaping (UIImage?) -> Void) {
        guard let clipItem = self.resolveThumbnailItem(for: album) else {
            completion(nil)
            return
        }
        self.cacheStorage.requestThumbnail(for: clipItem, completion: completion)
    }

    private func resolveThumbnailItem(for album: Album) -> ClipItem? {
        if self.showHiddenItems {
            return album.clips.first?.items.first
        } else {
            return album.clips.first(where: { !$0.isHidden })?.items.first
        }
    }
}
