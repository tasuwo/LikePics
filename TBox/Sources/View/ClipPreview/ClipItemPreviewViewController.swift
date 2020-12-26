//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class ClipItemPreviewViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipItemPreviewPresenter
    private let thumbnailStorage: ThumbnailStorageProtocol
    private let imageQueryService: NewImageQueryServiceProtocol

    private var isInitialLoaded: Bool = false

    var itemId: ClipItem.Identity {
        return self.presenter.item.id
    }

    var itemUrl: URL? {
        return self.presenter.item.url
    }

    @IBOutlet var previewView: ClipPreviewView!

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: ClipItemPreviewPresenter,
         thumbnailStorage: ThumbnailStorageProtocol,
         imageQueryService: NewImageQueryServiceProtocol)
    {
        self.factory = factory
        self.presenter = presenter
        self.thumbnailStorage = thumbnailStorage
        self.imageQueryService = imageQueryService
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // viewDidLoad で読み込むと、大きめの画像の場合に画面遷移中に読み込み処理で操作が引っかかるので、
        // 画面遷移後に画像を読み込む
        if self.isInitialLoaded == false {
            self.isInitialLoaded = true
            // 初回のPreview画面への遷移時に操作が引っかかってしまうので、若干遅延して読み込ませる
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.loadImage()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadThumbnail()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.previewView.shouldRecalculateInitialScale()
    }

    // MARK: - Methods

    private func loadThumbnail() {
        guard let image = self.thumbnailStorage.readThumbnailIfExists(for: self.presenter.item) else { return }
        self.previewView.source = (image, image.size)
    }

    private func loadImage() {
        guard let data = try? self.imageQueryService.read(having: self.presenter.item.imageId),
            let image = UIImage(data: data)
        else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: "Failed to load image"))
            return
        }
        self.previewView.source = (image, self.presenter.item.imageSize.cgSize)
    }
}

extension ClipItemPreviewViewController: ClipItemPreviewViewProtocol {
    // MARK: - ClipItemPreviewViewProtocol

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
