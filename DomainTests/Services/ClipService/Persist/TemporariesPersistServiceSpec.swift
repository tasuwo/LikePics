//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
@testable import Domain
import Nimble
import Quick
@testable import TestHelper

class TemporariesPersistServiceSpec: QuickSpec {
    override func spec() {
        var service: TemporariesPersistService!
        var temporaryClipStorage: TemporaryClipStorageProtocolMock!
        var temporaryImageStorage: TemporaryImageStorageProtocolMock!
        var clipStorage: ClipStorageProtocolMock!
        var referenceClipStorage: ReferenceClipStorageProtocolMock!
        var imageStorage: ImageStorageProtocolMock!

        beforeEach {
            temporaryClipStorage = TemporaryClipStorageProtocolMock()
            temporaryImageStorage = TemporaryImageStorageProtocolMock()
            clipStorage = ClipStorageProtocolMock()
            referenceClipStorage = ReferenceClipStorageProtocolMock()
            imageStorage = ImageStorageProtocolMock()

            service = .init(temporaryClipStorage: temporaryClipStorage,
                            temporaryImageStorage: temporaryImageStorage,
                            clipStorage: clipStorage,
                            referenceClipStorage: referenceClipStorage,
                            imageStorage: imageStorage,
                            logger: RootLogger.shared,
                            queue: .global())
        }

        // TODO:
    }
}
