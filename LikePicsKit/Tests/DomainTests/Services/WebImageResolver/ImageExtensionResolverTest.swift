//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
import MobileCoreServices
import XCTest

@testable import Domain

class ImageExtensionResolverTest: XCTestCase {
    func test_resolveFileExtensionForMimeType_期待した拡張子になる() {
        let testCases: [(line: UInt, mimeType: String, ext: String)] = [
            (#line, "image/bmp", "bmp"),
            (#line, "image/gif", "gif"),
            (#line, "image/png", "png"),
            (#line, "image/tiff", "tiff"),
            (#line, "image/jpeg", "jpeg"),
        ]
        testCases.forEach { testCase in
            XCTAssertEqual(ImageExtensionResolver.resolveFileExtension(forMimeType: testCase.mimeType), testCase.ext, line: testCase.line)
        }
    }

    func test_resolveUTTypeOf_期待した拡張子になる() {
        let testCases: [(line: UInt, url: URL, ext: CFString)] = [
            (#line, URL(string: "hoge://fuga/piyo/ooo.bmp")!, kUTTypeBMP),
            (#line, URL(string: "user://file/name/dyo.gif")!, kUTTypeGIF),
            (#line, URL(string: "howa://piyo/fuga/ooooo123.png")!, kUTTypePNG),
            (#line, URL(string: "ooo://pipi/pupu.tiff?hoge=fuga&piyo=poro")!, kUTTypeTIFF),
            (#line, URL(string: "/Users/tasuwo/hogehoge/fuga.jpeg")!, kUTTypeJPEG),
        ]
        testCases.forEach { testCase in
            XCTAssertEqual(ImageExtensionResolver.resolveUTType(of: testCase.url), testCase.ext, line: testCase.line)
        }
    }
}
