//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class ClipInformationViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipInformationPresenter
    private weak var dataSource: ClipInformationViewDataSource?

    @IBOutlet var informationView: ClipInformationView!

    // MARK: - Lifecycle

    init(factory: Factory, dataSource: ClipInformationViewDataSource, presenter: ClipInformationPresenter) {
        self.factory = factory
        self.presenter = presenter
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.informationView.delegate = self
        self.informationView.dataSource = self.dataSource
        self.informationView.siteUrl = self.presenter.clip.url.absoluteString
        self.informationView.imageUrl = self.presenter.item.image.url.absoluteString
        self.informationView.tags = self.presenter.clip.tags
    }
}

extension ClipInformationViewController: ClipInformationViewProtocol {
    // MARK: - ClipInformationViewProtocol
}

extension ClipInformationViewController: ClipInformationViewDelegate {
    // MARK: - ClipInformationViewDelegate

    func clipInformationView(_ view: ClipInformationView, didSelectTag name: String) {
        // TODO:
        print(name)
    }

    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL) {
        UIPasteboard.general.string = url.absoluteString
    }

    func clipInformationView(_ view: ClipInformationView, shouldSearch url: URL) {
        // TODO:
        print(url)
    }
}
