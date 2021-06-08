//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreMedia
import Domain

public struct ClipCreationViewState: Equatable {
    public enum Source: Equatable {
        case webImage
        case rawImage
    }

    enum Alert: Equatable {
        case error(title: String, body: String)
    }

    enum Modal: Equatable {
        case tagSelection(id: UUID, tagIds: Set<Tag.Identity>)
    }

    let source: Source

    var url: URL?
    var tags: EntityCollectionSnapshot<Tag>
    var imageSources: EntityCollectionSnapshot<ImageSource>
    var shouldSaveAsHiddenItem: Bool

    var isLoading: Bool
    var isEmptyMessageViewHidden: Bool
    var isCollectionViewHidden: Bool
    var isSomeItemsHidden: Bool

    var isDismissed: Bool

    var alert: Alert?
    var modal: Modal?
}

public extension ClipCreationViewState {
    init(source: Source, url: URL?, isSomeItemsHidden: Bool) {
        self.source = source
        self.url = url
        self.tags = .init()
        self.imageSources = .init()
        self.shouldSaveAsHiddenItem = false
        self.isLoading = true
        self.isEmptyMessageViewHidden = true
        self.isCollectionViewHidden = true
        self.isSomeItemsHidden = isSomeItemsHidden
        self.isDismissed = false
        self.alert = nil
        self.modal = nil
    }
}

extension ClipCreationViewState {
    var isOverlayHidden: Bool { !isLoading }
    var isReloadItemEnabled: Bool { !isLoading }
    var isDoneItemEnabled: Bool { !isLoading }
    var emptyMessageViewAlpha: CGFloat { isEmptyMessageViewHidden ? 0 : 1 }
    var displayReloadButton: Bool {
        switch source {
        case .webImage:
            return true

        case .rawImage:
            return false
        }
    }
}
