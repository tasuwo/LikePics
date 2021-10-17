//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
import MobileCoreServices
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

        describe("resolveUTType(of:)") {
            ([
                (URL(string: "hoge://fuga/piyo/ooo.bmp")!, kUTTypeBMP),
                (URL(string: "user://file/name/dyo.gif")!, kUTTypeGIF),
                (URL(string: "howa://piyo/fuga/ooooo123.png")!, kUTTypePNG),
                (URL(string: "ooo://pipi/pupu.tiff?hoge=fuga&piyo=poro")!, kUTTypeTIFF),
                (URL(string: "/Users/tasuwo/hogehoge/fuga.jpeg")!, kUTTypeJPEG),
            ] as [(URL, CFString)]).forEach { url, ext in
                context("URLが\(url.absoluteString)") {
                    it("拡張子が\(ext)になる") {
                        expect(ImageExtensionResolver.resolveUTType(of: url)).to(equal(ext))
                    }
                }
            }
        }
    }
}
