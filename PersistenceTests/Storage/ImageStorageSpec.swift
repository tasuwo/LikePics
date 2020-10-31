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
    static let testDirectory2 = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageStorageSpec2", isDirectory: true)
    static let config = ImageStorage.Configuration(targetUrl: ImageStorageSpec.testDirectory)

    override func spec() {
        var storage: ImageStorage!
        let sampleImage = UIImage(named: "SampleImageBlack", in: Bundle(for: Self.self), with: nil)!
        let sampleImage2 = UIImage(named: "SampleImageGray", in: Bundle(for: Self.self), with: nil)!
        let sampleClipId = "111222333hogehogefugafuga"
        let expectedClipDirectoryUrl = Self.testDirectory
            .appendingPathComponent("111222333hogehogefugafuga", isDirectory: true)

        beforeSuite {
            if FileManager.default.fileExists(atPath: Self.testDirectory.path) {
                try! FileManager.default.removeItem(at: Self.testDirectory)
            }
            if FileManager.default.fileExists(atPath: Self.testDirectory2.path) {
                try! FileManager.default.removeItem(at: Self.testDirectory2)
                try! FileManager.default.createDirectory(at: Self.testDirectory2, withIntermediateDirectories: true, attributes: nil)
            } else {
                try! FileManager.default.createDirectory(at: Self.testDirectory2, withIntermediateDirectories: true, attributes: nil)
            }
        }

        afterSuite {
            try! FileManager.default.removeItem(at: Self.testDirectory)
            try! FileManager.default.removeItem(at: Self.testDirectory2)
        }

        describe("init") {
            beforeEach {
                storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
            }
            it("画像保存用のディレクトリが作成されている") {
                expect(FileManager.default.fileExists(atPath: Self.testDirectory.path)).to(beTrue())
            }
        }

        describe("imageFileExists(named:inClipHaving:)") {
            context("画像が存在する") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
                }

                afterEach {
                    try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("trueが返る") {
                    expect(storage.imageFileExists(named: "hogehoge.png", inClipHaving: sampleClipId)).to(beTrue())
                }
            }

            context("存在しない画像を読み込む") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                }
                it("falseが返る") {
                    expect(storage.imageFileExists(named: "hogehoge.png", inClipHaving: sampleClipId)).to(beFalse())
                }
            }
        }

        describe("save(_:asName:inClipHaving:)") {
            context("新しいクリップに画像を保存する") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
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
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
                    try! storage.save(sampleImage.pngData()!, asName: "fugafuga.png", inClipHaving: sampleClipId)
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
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
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

        describe("delete(fileName:inClipHaving:)") {
            context("クリップに複数存在するうちの1つの画像を削除する") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
                    try! storage.save(sampleImage.pngData()!, asName: "fugafuga.png", inClipHaving: sampleClipId)

                    try! storage.delete(fileName: "hogehoge.png", inClipHaving: sampleClipId)
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
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)

                    try! storage.delete(fileName: "hogehoge.png", inClipHaving: sampleClipId)
                }

                it("クリップ用のディレクトリが削除されている") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beFalse())
                }
            }

            context("存在しない画像を削除する") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                }
                it("何も起きない") {
                    expect({
                        try storage.delete(fileName: "hogehoge.png", inClipHaving: sampleClipId)
                    }).notTo(throwError())
                }
            }
        }

        describe("deleteAll()") {
            // TODO:
        }

        describe("moveImageFile(at:withName:toClipHaving:)") {
            let sourceUrl: URL = Self.testDirectory2.appendingPathComponent("piyopiyo.png")

            context("移動元のURLが存在する") {
                beforeEach {
                    FileManager.default.createFile(atPath: sourceUrl.path, contents: sampleImage2.pngData(), attributes: nil)
                }

                afterEach {
                    try? FileManager.default.removeItem(at: sourceUrl)
                }

                context("新しいクリップに画像を移動する") {
                    beforeEach {
                        storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                        try! storage.moveImageFile(at: sourceUrl, withName: "popo.png", toClipHaving: sampleClipId)
                    }

                    afterEach {
                        try? FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                    }

                    it("クリップ用のディレクトリが作成されている") {
                        expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                    }

                    it("画像が保存されている") {
                        let imageUrl = expectedClipDirectoryUrl
                            .appendingPathComponent("popo.png", isDirectory: false)
                        expect(FileManager.default.fileExists(atPath: imageUrl.path)).to(beTrue())
                        expect(try! Data(contentsOf: imageUrl)).to(equal(sampleImage2.pngData()))
                    }

                    it("移動元のファイルが削除されている") {
                        expect(FileManager.default.fileExists(atPath: sourceUrl.path)).to(beFalse())
                    }
                }

                context("既存のクリップに画像を保存する") {
                    beforeEach {
                        storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
                        try! storage.moveImageFile(at: sourceUrl, withName: "popo.png", toClipHaving: sampleClipId)
                    }

                    afterEach {
                        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                    }

                    it("クリップ用のディレクトリが作成されている") {
                        expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                    }

                    it("画像が保存されている") {
                        let firstImageUrl = expectedClipDirectoryUrl
                            .appendingPathComponent("hogehoge.png", isDirectory: false)
                        let secondImageUrl = expectedClipDirectoryUrl
                            .appendingPathComponent("popo.png", isDirectory: false)

                        expect(FileManager.default.fileExists(atPath: firstImageUrl.path)).to(beTrue())
                        expect(FileManager.default.fileExists(atPath: secondImageUrl.path)).to(beTrue())
                        expect(try! Data(contentsOf: firstImageUrl)).to(equal(sampleImage.pngData()))
                        expect(try! Data(contentsOf: secondImageUrl)).to(equal(sampleImage2.pngData()))
                    }

                    it("移動元のファイルが削除されている") {
                        expect(FileManager.default.fileExists(atPath: sourceUrl.path)).to(beFalse())
                    }
                }

                context("重複して画像を保存する") {
                    beforeEach {
                        storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                        try! storage.save(sampleImage.pngData()!, asName: "popo.png", inClipHaving: sampleClipId)
                        try! storage.moveImageFile(at: sourceUrl, withName: "popo.png", toClipHaving: sampleClipId)
                    }

                    afterEach {
                        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                    }

                    it("クリップ用のディレクトリが作成されている") {
                        expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beTrue())
                    }

                    it("画像が上書きされている") {
                        let imageUrl = expectedClipDirectoryUrl
                            .appendingPathComponent("popo.png", isDirectory: false)
                        expect(FileManager.default.fileExists(atPath: imageUrl.path)).to(beTrue())
                        expect(try! Data(contentsOf: imageUrl)).to(equal(sampleImage2.pngData()))
                    }
                }
            }
            context("移動元のURLが存在しない") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.moveImageFile(at: sourceUrl, withName: "popo.png", toClipHaving: sampleClipId)
                }

                afterEach {
                    try? FileManager.default.removeItem(at: expectedClipDirectoryUrl)
                }

                it("クリップ用のディレクトリが作成されない") {
                    expect(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path)).to(beFalse())
                }

                it("画像が保存されていない") {
                    let imagePath = expectedClipDirectoryUrl
                        .appendingPathComponent("popo.png", isDirectory: false)
                        .path
                    expect(FileManager.default.fileExists(atPath: imagePath)).to(beFalse())
                }
            }
        }

        describe("readImage(named:inClipHaving:)") {
            var data: Data!
            context("存在する画像を読み込む") {
                beforeEach {
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)

                    data = try! storage.readImage(named: "hogehoge.png", inClipHaving: sampleClipId)
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
                    storage = try! ImageStorage(configuration: Self.config, fileManager: FileManager.default)
                    data = try! storage.readImage(named: "hogehoge.png", inClipHaving: sampleClipId)
                }
                it("nilが返る") {
                    expect(data).to(beNil())
                }
            }
        }
    }
}
