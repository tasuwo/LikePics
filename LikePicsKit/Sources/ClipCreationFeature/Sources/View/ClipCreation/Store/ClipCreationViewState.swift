//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreMedia
import Domain
import Foundation

public struct ClipCreationViewState: Equatable {
    public enum Source: Equatable {
        case webImage
        case webPageImage
        case localImage

        var fromLocal: Bool {
            switch self {
            case .localImage:
                return true

            default:
                return false
            }
        }

        var isReloadable: Bool {
            switch self {
            case .webImage:
                return true

            default:
                return false
            }
        }
    }

    enum Modal: Equatable {
        case tagSelection(id: UUID, tagIds: Set<Tag.Identity>)
        case albumSelection(id: UUID, albumIds: Set<Album.Identity>)
    }

    enum Alert: Equatable {
        case error(title: String, message: String)
    }

    enum DisplayState: Equatable {
        case loading
        case loaded
        case saving
        case error(title: String, message: String)
    }

    let id: UUID
    let source: Source

    var url: URL?
    var tags: EntityCollectionSnapshot<Tag>
    var albums: EntityCollectionSnapshot<ListingAlbumTitle>
    var imageSources: ImageSourcesSnapshot
    var shouldSaveAsHiddenItem: Bool
    var shouldSaveAsClip: Bool

    var displayState: DisplayState

    var isSomeItemsHidden: Bool

    var isDismissed: Bool

    var modal: Modal?
    var alert: Alert?
}

extension ClipCreationViewState {
    public init(id: UUID, source: Source, url: URL?, isSomeItemsHidden: Bool) {
        self.id = id
        self.source = source
        self.url = url
        self.tags = .init()
        self.albums = .init()
        self.imageSources = .init(order: [], selections: [], imageSourceById: [:])
        self.shouldSaveAsHiddenItem = false
        self.shouldSaveAsClip = false
        self.displayState = .loading
        self.isSomeItemsHidden = isSomeItemsHidden
        self.isDismissed = false
        self.modal = nil
        self.alert = nil
    }
}

extension ClipCreationViewState {
    var isLoading: Bool {
        switch displayState {
        case .loading, .saving:
            return true

        default:
            return false
        }
    }

    var emptyMessageViewAlpha: CGFloat {
        switch displayState {
        case .error:
            return 1

        default:
            return 0
        }
    }

    var emptyMessageViewTitle: String? {
        switch displayState {
        case let .error(title: title, message: _):
            return title

        default:
            return nil
        }
    }

    var emptyMessageViewMessage: String? {
        switch displayState {
        case let .error(title: _, message: message):
            return message

        default:
            return nil
        }
    }

    var isCollectionViewHidden: Bool {
        switch displayState {
        case .loaded, .saving:
            return false

        default:
            return true
        }
    }

    var isOverlayHidden: Bool { !isLoading }
    var isReloadItemEnabled: Bool { !isLoading && source.isReloadable }
    var isDoneItemEnabled: Bool { !isLoading && !imageSources.selections.isEmpty }
    var displayReloadButton: Bool { source.isReloadable }
}
