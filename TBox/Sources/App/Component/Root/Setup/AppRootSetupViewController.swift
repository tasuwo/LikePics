//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

protocol MainAppLauncher: AnyObject {
    func launch(configuration: DependencyContainerConfiguration, observer: CloudAvailabilityService)
}

class AppRootSetupViewController: UIViewController {
    private let indicator = UIActivityIndicatorView(style: .large)
    private let presenter: AppRootSetupPresenter
    weak var launcher: MainAppLauncher?

    // MARK: - Lifecycle

    init(presenter: AppRootSetupPresenter,
         launcher: MainAppLauncher)
    {
        self.presenter = presenter
        self.launcher = launcher
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.presenter.checkCloudAvailability()
    }

    private func setupAppearance() {
        self.view.backgroundColor = Asset.Color.backgroundClient.color

        self.view.addSubview(self.indicator)
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.indicator.hidesWhenStopped = true
        self.indicator.stopAnimating()
    }
}

extension AppRootSetupViewController: AppRootSetupViewProtocol {
    // MARK: - AppRootSetupViewProtocol

    func startLoading() {
        self.indicator.startAnimating()
    }

    func endLoading() {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
        }
    }

    func launchLikePics(configuration: DependencyContainerConfiguration, service: CloudAvailabilityService) {
        DispatchQueue.main.async {
            self.launcher?.launch(configuration: configuration, observer: service)
        }
    }

    func confirmAccountChanged() {
        let alertController = UIAlertController(title: L10n.errorIcloudAccountChangedTitle,
                                                message: L10n.errorIcloudAccountChangedMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk,
                                     style: .default,
                                     handler: { [weak self] _ in self?.presenter.didConfirmAccountChanged() })
        alertController.addAction(okAction)

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func confirmUnavailable() {
        let alertController = UIAlertController(title: L10n.errorIcloudUnavailableTitle,
                                                message: L10n.errorIcloudUnavailableMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk,
                                     style: .default,
                                     handler: { [weak self] _ in self?.presenter.didConfirmUnavailable() })
        alertController.addAction(okAction)

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
