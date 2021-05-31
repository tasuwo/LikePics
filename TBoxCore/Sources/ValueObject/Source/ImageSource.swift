//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreGraphics

public struct ImageSource: Hashable {
    enum Value: Hashable {
        case urlSet(WebImageUrlSet)
        case imageProvider(ImageProvider)
    }

    let identifier: UUID
    let value: Value

    // MARK: - Lifecycle

    init(urlSet: WebImageUrlSet) {
        self.identifier = UUID()
        self.value = .urlSet(urlSet)
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

extension ImageSource.Value {
    // MARK: - Equatable

    static func == (lhs: ImageSource.Value, rhs: ImageSource.Value) -> Bool {
        switch (lhs, rhs) {
        case let (.urlSet(lhset), .urlSet(rhset)):
            return lhset == rhset

        case let (.imageProvider(lhprovider), .imageProvider(rhprovider)):
            return lhprovider === rhprovider

        default:
            return false
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .urlSet(set):
            hasher.combine(set)

        case .imageProvider:
            // FIXME:
            return
        }
    }
}
