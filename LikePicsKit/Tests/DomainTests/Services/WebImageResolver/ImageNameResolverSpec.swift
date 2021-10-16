//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Nimble
import Quick

@testable import Domain

class ImageNameResolverSpec: QuickSpec {
    override func spec() {
        describe("resolveFileName(from:)") {
            context("") {
                it("末尾のcomponentを名前に採用する") {
                    let url = URL(string: "https://localhost/media/cho3ga83k1hoge")!
                    expect(ImageNameResolver.resolveFileName(from: url)).to(equal("cho3ga83k1hoge"))
                }
            }
            context("クエリパラメータがある") {
                it("末尾のcomponentを名前に採用する") {
                    let url = URL(string: "https://localhost/media/cho3ga83k1hoge?value=hoge&otherValue=fuga")!
                    expect(ImageNameResolver.resolveFileName(from: url)).to(equal("cho3ga83k1hoge"))
                }
            }
            context("末尾に/が存在する") {
                it("拡張子は無視する") {
                    let url = URL(string: "https://localhost/media/cho3ga83k1hoge/")!
                    expect(ImageNameResolver.resolveFileName(from: url)).to(equal("cho3ga83k1hoge"))
                }
            }
            context("末尾に拡張子が存在する") {
                it("拡張子は無視する") {
                    let url = URL(string: "https://localhost/media/cho3ga83k1hoge.png")!
                    expect(ImageNameResolver.resolveFileName(from: url)).to(equal("cho3ga83k1hoge"))
                }
            }
        }
    }
}
