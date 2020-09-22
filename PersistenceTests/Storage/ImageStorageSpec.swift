//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Nimble
import Quick

import Domain
@testable import Persistence

class ImageStorageSpec: QuickSpec {
    static let testDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageStorageSpec", isDirectory: true)

    override func spec() {
        var storage: ImageStorage!
        let sampleImage = UIImage(named: "TestImage", in: Bundle(for: Self.self), with: nil)!
        let sampleClipUrl = URL(string: "https://localhost/media/hogehogefugafuga?format=hoge&name=fuga")!
        let expectedClipDirectoryUrl = Self.testDirectory
            .appendingPathComponent("https___localhost_media_hogehogefugafuga?format=hoge&name=fuga", isDirectory: true)

        beforeSuite {
            if FileManager.default.fileExists(atPath: Self.testDirectory.path) {
                try! FileManager.default.removeItem(at: Self.testDirectory)
            }
        }

        afterSuite {
            try! FileManager.default.removeItem(at: Self.testDirectory)
        }

        describe("init") {
            beforeEach {
                storage = try! ImageStorage(fileManager: FileManager.default,
                                            targetDirectoryUrl: Self.testDirectory)
            }
            it("画像保存用のディレクトリが作成されている") {
                expect(FileManager.default.fileExists(atPath: Self.testDirectory.path)).to(beTrue())
            }
        }

        describe("save(_:asName:inClip:)") {
            context("新しいクリップに画像を保存する") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)
                }

                afterEach {
                    try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("クリップ用のディレクトリが作成されている") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                }

                it("画像が保存されている") {
                    let imagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("hogehoge.png", isDirectory: false)
                        .path
                    expect(FileManager.default.fileExists(atPath: imagePath)).to(beTrue())
                }
            }

            context("既存のクリップに画像を保存する") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)
                    try! storage.save(sampleImage.pngData()!, asName: "fugafuga.png", inClip: sampleClipUrl)
                }

                afterEach {
                    try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("クリップ用のディレクトリが作成されている") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                }

                it("画像が保存されている") {
                    let firstImagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("hogehoge.png", isDirectory: false)
                        .path
                    let secondImagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("hogehoge.png", isDirectory: false)
                        .path

                    expect(FileManager.default.fileExists(atPath: firstImagePath)).to(beTrue())
                    expect(FileManager.default.fileExists(atPath: secondImagePath)).to(beTrue())
                }
            }

            context("重複して画像を保存する") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)
                }

                afterEach {
                    try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("クリップ用のディレクトリが作成されている") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                }

                it("画像が保存されている") {
                    let imagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("hogehoge.png", isDirectory: false)
                        .path
                    expect(FileManager.default.fileExists(atPath: imagePath)).to(beTrue())
                }
            }
        }

        describe("delete(fileName:inClip:)") {
            context("クリップに複数存在するうちの1つの画像を削除する") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)
                    try! storage.save(sampleImage.pngData()!, asName: "fugafuga.png", inClip: sampleClipUrl)

                    try! storage.delete(fileName: "hogehoge.png", inClip: sampleClipUrl)
                }

                afterEach {
                    try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("クリップ用のディレクトリが削除されていない") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                }

                it("指定した画像が削除されている") {
                    let firstImagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("hogehoge.png", isDirectory: false)
                        .path
                    let secondImagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("fugafuga.png", isDirectory: false)
                        .path

                    expect(FileManager.default.fileExists(atPath: firstImagePath)).to(beFalse())
                    expect(FileManager.default.fileExists(atPath: secondImagePath)).to(beTrue())
                }
            }

            context("クリップの最後の1枚の画像を削除する") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)

                    try! storage.delete(fileName: "hogehoge.png", inClip: sampleClipUrl)
                }

                it("クリップ用のディレクトリが削除されている") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beFalse())
                }
            }

            context("存在しない画像を削除する") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                }
                it("notFoundエラーがスローされる") {
                    expect(expression: {
                        try storage.delete(fileName: "hogehoge.png", inClip: sampleClipUrl)
                    }).to(throwError(ImageStorageError.notFound))
                }
            }
        }

        describe("readImage(named:inClip:)") {
            context("存在する画像を読み込む") {
                var data: Data!

                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClip: sampleClipUrl)

                    data = try! storage.readImage(named: "hogehoge.png", inClip: sampleClipUrl)
                }

                afterEach {
                    try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("画像データが読み込める") {
                    expect(data).notTo(beNil())
                    expect(data).to(equal(sampleImage.pngData()!))
                }
            }

            context("存在しない画像を読み込む") {
                beforeEach {
                    storage = try! ImageStorage(fileManager: FileManager.default,
                                                targetDirectoryUrl: Self.testDirectory)
                }
                it("notFoundエラーがスローされる") {
                    expect(expression: {
                        try storage.readImage(named: "hogehoge.png", inClip: sampleClipUrl)
                    }).to(throwError(ImageStorageError.notFound))
                }
            }
        }
    }
}