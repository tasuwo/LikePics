//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    typealias Factory = ViewControllerFactory

    // swiftlint:disable:next implicitly_unwrapped_optional
    var factory: Factory!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var presenter: SettingsPresenter!

    @IBOutlet var showHiddenItemsSwitch: UISwitch!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.showHiddenItemsSwitch.isOn = self.presenter.shouldShowHiddenItems
    }

    // MARK: - IBActions

    @IBAction func didChangeShouldShowHiddenItems(_ sender: UISwitch) {
        self.presenter.shouldShowHiddenItems = sender.isOn
    }
}
