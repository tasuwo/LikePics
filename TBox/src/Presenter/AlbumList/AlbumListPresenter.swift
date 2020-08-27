//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumListViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func showErrorMassage(_ message: String)
    func reload()
}

class AlbumListPresenter {
    private let storage: ClipStorageProtocol

    private(set) var albums: [Album] = []

    weak var view: AlbumListViewProtocol?

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    func reload() {
        guard let view = self.view else { return }

        view.startLoading()
        switch self.storage.readAllAlbums() {
        case let .success(albums):
            self.albums = albums.sorted(by: { $0.registeredDate > $1.registeredDate })
            view.reload()
        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }

    func addAlbum(title: String?) {
        guard let title = title else {
            // TODO: Error Handling
            return
        }
        guard let view = self.view else { return }

        view.startLoading()
        switch self.storage.create(albumWithTitle: title) {
        case let .success(album):
            self.albums = (albums + [album]).sorted(by: { $0.registeredDate > $1.registeredDate })
            view.reload()
        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }

    func getThumbnailImageData(at index: Int) -> Data? {
        guard self.albums.indices.contains(index),
            let clip = self.albums[index].clips.first,
            let clipItem = clip.items.first
        else {
            return nil
        }

        switch self.storage.read(imageDataOfUrl: clipItem.thumbnail.url, forClipOfUrl: clip.url) {
        case let .success(data):
            return data
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
            return nil
        }
    }

    private static func resolveErrorMessage(_ error: Error) -> String {
        // TODO:
        return "TODO"
    }
}
