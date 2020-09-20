//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Nimble
import Quick

@testable import Domain

class ImageExtensionResolverSpec: QuickSpec {
    override func spec() {
        describe("resolveFileExtension(forMimeType:)") {
            [
                ("image/bmp", "bmp"),
                ("image/gif", "gif"),
                ("image/png", "png"),
                ("image/tiff", "tiff"),
                ("image/jpeg", "jpeg"),
            ].forEach { mimeType, ext in
                context("MimeTypeが\(mimeType)") {
                    it("拡張子が\(ext)になる") {
                        expect(ImageExtensionResolver.resolveFileExtension(forMimeType: mimeType)).to(equal(ext))
                    }
                }
            }
        }
    }
}
