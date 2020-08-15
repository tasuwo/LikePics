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

    var clipItem: ClipItem {
        self.presenter.item
    }

    @IBOutlet var pageView: ClipPreviewPageView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipItemPreviewPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let data = self.presenter.loadImageData() {
            self.pageView.image = UIImage(data: data)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.pageView.shouldRecalculateInitialScale()
    }
}
