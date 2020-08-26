//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumContainer {
    var album: Album { get set }
}

protocol AlbumEditableViewContainer {
    var editableView: AlbumEditableViewProtocol? { get }
}

typealias AlbumEditableContainer = AlbumContainer
    & AlbumEditableViewContainer
    & SelectedClipsContainer
