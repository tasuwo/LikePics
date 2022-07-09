//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
import XCTest

@testable import Domain

class ImageNameResolverTest: XCTestCase {
    func test_resolveFileName_通常_末尾のcocmpopnentを名前に採用する() {
        let url = URL(string: "https://localhost/media/cho3ga83k1hoge")!
        XCTAssertEqual(ImageNameResolver.resolveFileName(from: url), "cho3ga83k1hoge")
    }

    func test_resolveFileName_クエリパラメータがある_末尾のcomponentを名前に採用する() {
        let url = URL(string: "https://localhost/media/cho3ga83k1hoge?value=hoge&otherValue=fuga")!
        XCTAssertEqual(ImageNameResolver.resolveFileName(from: url), "cho3ga83k1hoge")
    }

    func test_resolveFileName_末尾にスラッシュが存在する_拡張子は無視する() {
        let url = URL(string: "https://localhost/media/cho3ga83k1hoge/")!
        XCTAssertEqual(ImageNameResolver.resolveFileName(from: url), "cho3ga83k1hoge")
    }

    func test_resolveFileName_末尾に拡張子が存在する_拡張子は無視する() {
        let url = URL(string: "https://localhost/media/cho3ga83k1hoge.png")!
        XCTAssertEqual(ImageNameResolver.resolveFileName(from: url), "cho3ga83k1hoge")
    }
}
