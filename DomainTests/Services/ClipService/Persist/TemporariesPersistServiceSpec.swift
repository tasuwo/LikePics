//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Nimble
import Quick
@testable import TestHelper
@testable import Domain

class TemporariesPersistServiceSpec: QuickSpec {
    override func spec() {
        var service: TemporariesPersistService!
        var temporaryClipStorage: ClipStorageProtocolMock!
        var temporaryImageStorage: ImageStorageProtocolMock!
        var clipStorage: ClipStorageProtocolMock!
        var referenceClipStorage: ReferenceClipStorageProtocolMock!
        var imageStorage: NewImageStorageProtocolMock!

        beforeEach {
            temporaryClipStorage = ClipStorageProtocolMock()
            temporaryImageStorage = ImageStorageProtocolMock()
            clipStorage = ClipStorageProtocolMock()
            referenceClipStorage = ReferenceClipStorageProtocolMock()
            imageStorage = NewImageStorageProtocolMock()

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
