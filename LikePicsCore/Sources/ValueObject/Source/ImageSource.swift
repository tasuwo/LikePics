//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreGraphics
import Domain

public struct ImageSource: Hashable {
    enum Value {
        case urlSet(WebImageUrlSet)
        case fileUrl(URL)
        case imageProvider(ImageProvider)
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

    init(provider: ImageProvider) {
        self.identifier = UUID()
        self.value = .imageProvider(provider)
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

public extension ImageSource {
    // MARK: - Equatable

    static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
