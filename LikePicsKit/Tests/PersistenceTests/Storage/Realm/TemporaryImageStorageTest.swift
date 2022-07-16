//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
@testable import Persistence
import UIKit
import XCTest

class TemporaryImageStorageTest: XCTestCase {
    static let testDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("TemporaryImageStorageSpec", isDirectory: true)
    static let testDirectory2 = FileManager.default.temporaryDirectory
        .appendingPathComponent("TemporaryImageStorageSpec2", isDirectory: true)
    static let config = TemporaryImageStorage.Configuration(targetUrl: TemporaryImageStorageTest.testDirectory)

    let sampleImage = UIImage(named: "SampleImageBlack", in: Bundle.module, with: nil)!
    let sampleClipId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6111")!
    lazy var expectedClipDirectoryUrl = Self.testDirectory
        .appendingPathComponent("E621E1F8-C36C-495A-93FC-0C247A3E6111", isDirectory: true)

    override func setUp() {
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

    override func tearDown() {
        try! FileManager.default.removeItem(at: Self.testDirectory)
        try! FileManager.default.removeItem(at: Self.testDirectory2)
    }

    func test_init_画像保存用のディレクトリが作成される() {
        _ = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        XCTAssertTrue(FileManager.default.fileExists(atPath: Self.testDirectory.path))
    }

    func test_imageFileExists_画像が存在する場合_trueが返る() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)

        XCTAssertTrue(storage.imageFileExists(named: "hogehoge.png", inClipHaving: sampleClipId))

        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
    }

    func test_imageFileExists_画像が存在しない場合_falseが返る() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        XCTAssertFalse(storage.imageFileExists(named: "hogehoge.png", inClipHaving: sampleClipId))
    }

    func test_save_新しいクリップに画像を保存する場合_クリップ用のディレクトリが作成され画像が保存される() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)

        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path))
        let imagePath = expectedClipDirectoryUrl
            .appendingPathComponent("hogehoge.png", isDirectory: false)
            .path
        XCTAssertTrue(FileManager.default.fileExists(atPath: imagePath))

        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
    }

    func test_save_既存のクリップに画像を保存する場合_クリップ用のディレクトリに画像が保存される() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
        try! storage.save(sampleImage.pngData()!, asName: "fugafuga.png", inClipHaving: sampleClipId)

        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path))
        let firstImagePath = expectedClipDirectoryUrl
            .appendingPathComponent("hogehoge.png", isDirectory: false)
            .path
        let secondImagePath = expectedClipDirectoryUrl
            .appendingPathComponent("hogehoge.png", isDirectory: false)
            .path
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstImagePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondImagePath))

        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
    }

    func test_save_重複してに画像を保存する場合_クリップ用のディレクトリに画像が保存される() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)

        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path))
        let imagePath = expectedClipDirectoryUrl
            .appendingPathComponent("hogehoge.png", isDirectory: false)
            .path
        XCTAssertTrue(FileManager.default.fileExists(atPath: imagePath))

        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
    }

    func test_delete_クリップに複数存在するうちの1つの画像を削除する場合_ディレクトリは削除される指定した画像のみ削除される() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
        try! storage.save(sampleImage.pngData()!, asName: "fugafuga.png", inClipHaving: sampleClipId)

        try! storage.delete(fileName: "hogehoge.png", inClipHaving: sampleClipId)

        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path))
        let firstImagePath = expectedClipDirectoryUrl
            .appendingPathComponent("hogehoge.png", isDirectory: false)
            .path
        let secondImagePath = expectedClipDirectoryUrl
            .appendingPathComponent("fugafuga.png", isDirectory: false)
            .path
        XCTAssertFalse(FileManager.default.fileExists(atPath: firstImagePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondImagePath))

        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
    }

    func test_delete_クリップの最後の一枚の画像を削除する場合_クリップ用のディレクトリ毎削除される() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)

        try! storage.delete(fileName: "hogehoge.png", inClipHaving: sampleClipId)

        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedClipDirectoryUrl.path))
    }

    func test_delete_存在しない画像を削除しようとする場合_何も起きない() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        XCTAssertNoThrow {
            try storage.delete(fileName: "hogehoge.png", inClipHaving: self.sampleClipId)
        }
    }

    /*
     TODO:
     func test_deleteAll() {
     }
     */

    func test_readImage_存在する画像を読み込む場合_画像データが読み込める() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        try! storage.save(sampleImage.pngData()!, asName: "hogehoge.png", inClipHaving: sampleClipId)
        let data = try! storage.readImage(named: "hogehoge.png", inClipHaving: sampleClipId)

        XCTAssertNotNil(data)
        XCTAssertEqual(data, sampleImage.pngData()!)

        try! FileManager.default.removeItem(at: expectedClipDirectoryUrl)
    }

    func test_readImage_存在しない画像を読み込む場合_nilが返る() {
        let storage = try! TemporaryImageStorage(configuration: Self.config, fileManager: FileManager.default)
        let data = try! storage.readImage(named: "hogehoge.png", inClipHaving: sampleClipId)
        XCTAssertNil(data)
    }
}
