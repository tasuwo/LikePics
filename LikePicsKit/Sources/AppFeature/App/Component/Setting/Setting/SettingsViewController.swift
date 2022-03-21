//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import UIKit

class SettingsViewController: UITableViewController {
    typealias Store = CompositeKit.Store<SettingsViewState, SettingsViewAction, SettingsViewDependency>

    // MARK: - Properties

    // MARK: View

    @IBOutlet var showHiddenItemsSwitch: UISwitch!
    @IBOutlet var syncICloudSwitch: UISwitch!
    @IBOutlet var versionLabel: UILabel!

    // MARK: Service

    var router: Router!
    var userSettingsStorage: UserSettingsStorageProtocol!

    // MARK: Store

    var store: Store!
    var subscriptions: Set<AnyCancellable> = .init()

    // MARK: State Restoration

    var appBundle: Bundle!
    private let viewDidAppeared: CurrentValueSubject<Bool, Never> = .init(false)
    private var presentingAlert: UIViewController?

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingViewTitle
        view.backgroundColor = Asset.Color.background.color

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateUserActivity(store.stateValue)
        viewDidAppeared.send(true)
    }

    // MARK: - IBActions

    @IBAction func didChangeShouldShowHiddenItems(_ sender: UISwitch) {
        store.execute(.itemsVisibilityChanged(isHidden: sender.isOn))
    }

    @IBAction func didChangeSyncICloud(_ sender: UISwitch) {
        store.execute(.iCloudSyncAvailabilityChanged(isEnabled: sender.isOn))
    }
}

// MARK: - Bind

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
            .waitUntilToBeTrue(viewDidAppeared)
            .bind(\.alert) { [weak self] alert in
                self?.presentAlertIfNeeded(alert)
            }
            .store(in: &subscriptions)

        store.state
            .receive(on: DispatchQueue.global())
            .debounce(for: 1, scheduler: DispatchQueue.global())
            .map({ $0.removingSessionStates() })
            .removeDuplicates()
            .sink { [weak self] state in self?.updateUserActivity(state) }
            .store(in: &subscriptions)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(_ alert: SettingsViewState.Alert?) {
        switch alert {
        case .iCloudTurnOffConfirmation:
            presentICloudTurnOffConfirmation()

        case .iCloudSettingForceTurnOffConfirmation:
            presentICloudSettingForceTurnOffConfirmation()

        case .iCloudSettingForceTurnOnConfirmation:
            presentICloudSettingForceTurnOnConfirmation()

        case .clearAllCacheConfirmation:
            presentClearAllCacheConfirmation()

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
        presentingAlert = alertController
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
        presentingAlert = alertController
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
        presentingAlert = alertController
        self.present(alertController, animated: true, completion: nil)
    }

    private func presentClearAllCacheConfirmation() {
        let alertController = UIAlertController(title: L10n.settingsConfirmClearCacheTitle,
                                                message: L10n.settingsConfirmClearCacheMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.confirmAlertOk, style: .destructive) { [weak self] _ in
            self?.store.execute(.clearAllCacheConfirmed)
        }
        let cancelAction = UIAlertAction(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        presentingAlert = alertController
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: User Activity

    private func updateUserActivity(_ state: SettingsViewState) {
        DispatchQueue.global().async {
            guard let activity = NSUserActivity.make(with: .setting(state.removingSessionStates()), appBundle: self.appBundle) else { return }
            DispatchQueue.main.async { self.view.window?.windowScene?.userActivity = activity }
        }
    }
}

extension SettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 0) {
            show(UserInterfaceStyleSelectionViewController(userSettingsStorage: userSettingsStorage), sender: nil)
        } else if indexPath == IndexPath(row: 0, section: 2) {
            router.showFindView()
        } else if indexPath == IndexPath(row: 0, section: 4) {
            store.execute(.clearAllCache)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = Asset.Color.secondaryBackground.color
    }
}

extension SettingsViewController: Restorable {
    // MARK: - Restorable

    func restore() -> RestorableViewController {
        presentingAlert?.dismiss(animated: false, completion: nil)

        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.module)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController
        let store = Store(initialState: store.stateValue,
                          dependency: store.dependency,
                          reducer: SettingsViewReducer())
        viewController.store = store
        viewController.router = router

        return viewController
    }
}
