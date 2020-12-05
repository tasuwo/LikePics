//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class SettingsViewController: UITableViewController {
    typealias Factory = ViewControllerFactory

    // swiftlint:disable:next implicitly_unwrapped_optional
    var factory: Factory!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var presenter: SettingsPresenter!
    var cancellableBag: Set<AnyCancellable> = .init()

    @IBOutlet var showHiddenItemsSwitch: UISwitch!
    @IBOutlet var syncICloudSwitch: UISwitch!
    @IBOutlet var versionLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.view = self

        self.presenter.shouldShowHiddenItems
            .assign(to: \.isOn, on: self.showHiddenItemsSwitch)
            .store(in: &self.cancellableBag)

        self.presenter.shouldSyncICloudEnabled
            .assign(to: \.isOn, on: self.syncICloudSwitch)
            .store(in: &self.cancellableBag)

        self.presenter.displayVersion()
    }

    // MARK: - IBActions

    @IBAction func didChangeShouldShowHiddenItems(_ sender: UISwitch) {
        self.presenter.set(showHiddenItems: sender.isOn)
    }

    @IBAction func didChangeSyncICloud(_ sender: UISwitch) {
        guard self.presenter.set(isICloudSyncEnabled: sender.isOn) else {
            sender.setOnSmoothly(!sender.isOn)
            return
        }
    }
}

extension SettingsViewController: SettingsViewProtocol {
    // MARK: - SettingsViewProtocol

    func set(version: String) {
        self.versionLabel.text = version
    }

    func set(isICloudSyncEnabled: Bool) {
        self.syncICloudSwitch.setOn(isICloudSyncEnabled, animated: true)
    }

    func confirmToUnavailabilityICloudSync(shouldTurnOff: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: L10n.errorIcloudUnavailableTitle,
                                                message: L10n.errorIcloudUnavailableMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .default) { _ in
            shouldTurnOff(false)
        }
        let turnOffAction = UIAlertAction(title: L10n.errorIcloudUnavailableTurnOffAction,
                                          style: .cancel) { _ in
            shouldTurnOff(true)
        }
        alertController.addAction(okAction)
        alertController.addAction(turnOffAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func confirmToUnavailabilityICloudSync(shouldTurnOn: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: L10n.errorIcloudUnavailableTitle,
                                                message: L10n.errorIcloudUnavailableMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .default) { _ in
            shouldTurnOn(false)
        }
        let turnOnAction = UIAlertAction(title: L10n.errorIcloudUnavailableTurnOnAction,
                                          style: .cancel) { _ in
            shouldTurnOn(true)
        }
        alertController.addAction(okAction)
        alertController.addAction(turnOnAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func confirmToTurnOffICloudSync(confirmation: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: L10n.settingsConfirmIcloudSyncOffTitle,
                                                message: L10n.settingsConfirmIcloudSyncOffMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .default) { _ in confirmation(true) }
        let cancelAction = UIAlertAction(title: L10n.confirmAlertCancel, style: .cancel) { _ in confirmation(false) }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
