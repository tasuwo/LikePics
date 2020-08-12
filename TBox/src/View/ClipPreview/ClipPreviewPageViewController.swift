//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipPreviewPagePresenter

    var presentingImageUrl: URL {
        self.presenter.item.imageUrl
    }

    @IBOutlet var pageView: ClipPreviewPageView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipPreviewPagePresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pageView.image = self.presenter.item.largeImage
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.pageView.shouldRecalculateInitialScale()
    }
}
