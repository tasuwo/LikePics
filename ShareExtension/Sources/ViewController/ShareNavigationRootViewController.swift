//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import LikePicsCore
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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.indicator.hidesWhenStopped = true
        self.indicator.startAnimating()

        // swiftlint:disable:next force_unwrapping
        self.presenter.resolveUrl(from: extensionContext!)
    }
}

extension ShareNavigationRootViewController: ShareNavigationViewProtocol {
    // MARK: - ShareNavigationViewProtocol

    func show(errorMessage: String) {
        if self.indicator.isAnimating {
            self.indicator.stopAnimating()
        }

        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: { [weak self] _ in
            let error = NSError(domain: "net.tasuwo.TBox",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "An error description"])
            self?.extensionContext?.cancelRequest(withError: error)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func presentClipTargetSelectionView(by url: URL) {
        self.navigationController?.pushViewController(self.factory.makeClipTargetCollectionViewController(webUrl: url, delegate: self), animated: true)
    }

    func presentClipTargetSelectionView(by providers: [ImageProvider], fileUrls: [URL]) {
        self.navigationController?.pushViewController(self.factory.makeClipTargetCollectionViewController(imageProviders: providers, fileUrls: fileUrls, delegate: self), animated: true)
    }
}

extension ShareNavigationRootViewController: ClipCreationDelegate {
    // MARK: - ClipTargetCollectionViewControllerDelegate

    func didFinish(_ viewController: ClipCreationViewController) {
        DarwinNotificationCenter.default.post(name: .shareExtensionDidCompleteRequest)
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    func didCancel(_ viewController: ClipCreationViewController) {
        let error = NSError(domain: "net.tasuwo.TBox",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "An error description"])
        self.extensionContext?.cancelRequest(withError: error)
    }
}
