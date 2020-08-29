//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

enum AlbumViewNavigationItem {
    case cancel
    case edit
    case save
}

protocol AlbumViewProtocol: ClipsListViewProtocol {
    func setNavigationItems(_ items: [AlbumViewNavigationItem])

    func setNavigationTitle(_ title: String, asEditable: Bool)
}

protocol AlbumPresenterProtocol: ClipsListPresenterProtocol & AddingClipsToAlbumPresenterDelegate {
    var album: Album { get }

    func setup()

    func set(view: AlbumViewProtocol)

    func deleteFromAlbum()

    func updateAlbumTitle()

    func replaceAlbum(by album: Album)

    func setTitleEditing(_ editing: Bool)

    func edit(title: String)
}

class AlbumPresenter: ClipsListPresenter {
    enum EditTarget {
        case clip
        case title
    }

    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    var clips: [Clip] {
        return self.album.clips
    }

    var selectedClips: [Clip]

    var isEditing: Bool {
        get {
            return self.editingTarget != nil
        }
        set {
            // NOP
        }
    }

    var storage: ClipStorageProtocol

    // MARK: AlbumPresenterProtocol

    var album: Album

    // MARK: Internal

    private weak var internalView: AlbumViewProtocol?

    private var editingTarget: EditTarget? {
        didSet {
            self.updateNavigationItem()
        }
    }

    private var editingTitle: String? {
        didSet {
            self.updateNavigationItem()
        }
    }

    // MARK: - Lifecycle

    init(album: Album, storage: ClipStorageProtocol) {
        self.album = album
        self.storage = storage
        self.selectedClips = []
    }

    // MARK: - Methods

    private func updateNavigationItem() {
        let items: [AlbumViewNavigationItem] = {
            switch self.editingTarget {
            case .title:
                return []
            case .clip where self.editingTitle?.isEmpty == false:
                return [.save]
            case .clip:
                return [.cancel]
            case .none:
                return [.edit]
            }
        }()
        self.internalView?.setNavigationItems(items)
    }
}

extension AlbumPresenter: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    func updateClips(to clips: [Clip]) {
        self.album = self.album.updatingClips(to: clips)
    }

    func setEditing(_ editing: Bool) {
        if self.isEditing != editing {
            self.editingTitle = nil
            self.selectedClips = []
            self.view?.deselectAll()
        }
        self.editingTarget = editing ? .clip : nil
        self.internalView?.setNavigationTitle(self.album.title, asEditable: self.isEditing)
    }

    func setup() {
        self.setEditing(false)
    }

    func set(view: AlbumViewProtocol) {
        self.internalView = view
    }

    func deleteFromAlbum() {
        switch self.storage.update(byDeletingClips: self.selectedClips.map { $0.url }, fromAlbum: self.album) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
            return
        }

        let newClips: [Clip] = self.album.clips.compactMap { clip in
            if self.selectedClips.contains(where: { clip.url == $0.url }) { return nil }
            return clip
        }
        self.album = self.album.updatingClips(to: newClips)

        self.selectedClips = []
        self.internalView?.deselectAll()

        self.internalView?.reload()

        self.internalView?.endEditing()
    }

    func updateAlbumTitle() {
        guard let newTitle = self.editingTitle, !newTitle.isEmpty else { return }
        switch self.storage.update(titleOfAlbum: self.album, to: newTitle) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
            return
        }
        self.album = self.album.updatingTitle(to: newTitle)
    }

    func replaceAlbum(by album: Album) {
        self.album = album
        self.internalView?.reload()
    }

    func setTitleEditing(_ editing: Bool) {
        guard self.isEditing else { return }
        self.editingTarget = editing ? .title : .clip
    }

    func edit(title: String) {
        self.editingTitle = title
    }
}
