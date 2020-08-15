//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxCore
import UIKit

class ShareNavigationRootViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ShareNavigationRootPresenter

    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ShareNavigationRootPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.indicator.startAnimating()

        self.presenter.resolveUrl(from: self.extensionContext)
    }
}

extension ShareNavigationRootViewController: ShareNavigationViewProtocol {
    // MARK: - ShareNavigationViewProtocol

    func show(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    func presentClipTargetSelectionView(by url: URL) {
        self.navigationController?.pushViewController(self.factory.makeClipTargetCollectionViewController(url: url, delegate: self), animated: true)
    }
}

extension ShareNavigationRootViewController: ClipTargetCollectionViewControllerDelegate {
    // MARK: - ClipTargetCollectionViewControllerDelegate

    func didFinish(_ viewController: ClipTargetCollectionViewController) {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
}
