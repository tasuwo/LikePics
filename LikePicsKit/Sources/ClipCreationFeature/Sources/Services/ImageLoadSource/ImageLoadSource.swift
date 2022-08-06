//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain
import Foundation

public struct ImageLoadSource: Hashable {
    enum Value {
        case urlSet(WebImageUrlSet)
        case fileUrl(URL)
        case lazyLoader(ImageLazyLoadable)
    }

    let identifier: UUID
    let value: Value

    // MARK: - Lifecycle

    init(urlSet: WebImageUrlSet) {
        self.identifier = UUID()
        self.value = .urlSet(urlSet)
    }

    init(fileUrl: URL) {
        self.identifier = UUID()
        self.value = .fileUrl(fileUrl)
    }

    init(lazyLoader: ImageLazyLoadable) {
        self.identifier = UUID()
        self.value = .lazyLoader(lazyLoader)
    }

    // MARK: - Methods

    var isValid: Bool {
        switch value {
        case let .urlSet(urlSet):
            guard let size = ImageUtility.resolveSize(for: urlSet.url) else { return false }
            return size.height != 0
                && size.width != 0
                && size.height > 10
                && size.width > 10

        default:
            return true
        }
    }
}

public extension ImageLoadSource {
    // MARK: - Equatable

    static func == (lhs: ImageLoadSource, rhs: ImageLoadSource) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
