//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class SettingsViewController: UITableViewController {
    typealias Store = LikePics.Store<SettingsViewState, SettingsViewAction, SettingsViewDependency>

    // MARK: - Properties

    // MARK: View

    @IBOutlet var showHiddenItemsSwitch: UISwitch!
    @IBOutlet var syncICloudSwitch: UISwitch!
    @IBOutlet var versionLabel: UILabel!

    // MARK: Store

    var store: Store!
    var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingViewTitle

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    // MARK: - IBActions

    @IBAction func didChangeShouldShowHiddenItems(_ sender: UISwitch) {
        store.execute(.itemsVisibilityChanged(isHidden: sender.isOn))
    }

    @IBAction func didChangeSyncICloud(_ sender: UISwitch) {
        store.execute(.iCloudSyncAvailabilityChanged(isEnabled: sender.isOn))
    }
}

extension SettingsViewController {
    private func bind(to store: Store) {
        store.state
            .bind(\.isSomeItemsHidden) { [weak self] isSomeItemsHidden in
                self?.showHiddenItemsSwitch.setOn(isSomeItemsHidden, animated: true)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isSyncICloudEnabledOn) { [weak self] isSyncICloudEnabledOn in
                switch isSyncICloudEnabledOn {
                case .on:
                    self?.syncICloudSwitch.setOn(true, animated: true)

                case .off:
                    self?.syncICloudSwitch.setOn(false, animated: true)

                case .loading:
                    // NOP
                    break
                }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.versionText, to: \.text, on: versionLabel)
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in
                self?.presentAlertIfNeeded(alert)
            }
            .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(_ alert: SettingsViewState.Alert?) {
        switch alert {
        case .iCloudTurnOffConfirmation:
            presentICloudTurnOffConfirmation()

        case .iCloudSettingForceTurnOffConfirmation:
            presentICloudSettingForceTurnOffConfirmation()

        case .iCloudSettingForceTurnOnConfirmation:
            presentICloudSettingForceTurnOnConfirmation()

        case .none:
            break
        }
    }

    private func presentICloudTurnOffConfirmation() {
        let alertController = UIAlertController(title: L10n.settingsConfirmIcloudSyncOffTitle,
                                                message: L10n.settingsConfirmIcloudSyncOffMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.iCloudTurnOffConfirmed)
        }
        let cancelAction = UIAlertAction(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    private func presentICloudSettingForceTurnOffConfirmation() {
        let alertController = UIAlertController(title: L10n.errorIcloudUnavailableTitle,
                                                message: L10n.errorIcloudUnavailableMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }
        let turnOffAction = UIAlertAction(title: L10n.errorIcloudUnavailableTurnOffAction, style: .cancel) { [weak self] _ in
            self?.store.execute(.iCloudForceTurnOffConfirmed)
        }
        alertController.addAction(okAction)
        alertController.addAction(turnOffAction)
        self.present(alertController, animated: true, completion: nil)
    }

    private func presentICloudSettingForceTurnOnConfirmation() {
        let alertController = UIAlertController(title: L10n.errorIcloudUnavailableTitle,
                                                message: L10n.errorIcloudUnavailableMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }
        let turnOnAction = UIAlertAction(title: L10n.errorIcloudUnavailableTurnOnAction, style: .cancel) { [weak self] _ in
            self?.store.execute(.iCloudForceTurnOnConfirmed)
        }
        alertController.addAction(okAction)
        alertController.addAction(turnOnAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
