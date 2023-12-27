//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

private struct ImageQueryServiceKey: EnvironmentKey {
    private class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: ImageContainer.Identity) throws -> Data? {
            assertionFailure("Not Implemented")
            return nil
        }
    }

    static var defaultValue: ImageQueryServiceProtocol = _ImageQueryService()
}

extension EnvironmentValues {
    var imageQueryService: ImageQueryServiceProtocol {
        get { self[ImageQueryServiceKey.self] }
        set { self[ImageQueryServiceKey.self] = newValue }
    }
}
