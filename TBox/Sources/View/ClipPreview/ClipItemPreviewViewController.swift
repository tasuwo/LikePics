//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class ClipItemPreviewViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipItemPreviewPresenter

    var itemId: ClipItem.Identity {
        return self.presenter.itemId
    }

    var itemUrl: URL? {
        return self.presenter.itemUrl
    }

    @IBOutlet var previewView: ClipPreviewView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipItemPreviewPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let thumbnail = self.presenter.readThumbnailIfExists()
        if let imageSize = self.presenter.imageSize,
            let url = self.presenter.resolveImageUrl()
        {
            self.previewView.source = (url, imageSize.cgSize, thumbnail)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.previewView.shouldRecalculateInitialScale()
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
