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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.shouldShowHiddenItems
            .assign(to: \.isOn, on: self.showHiddenItemsSwitch)
            .store(in: &self.cancellableBag)
    }

    // MARK: - IBActions

    @IBAction func didChangeShouldShowHiddenItems(_ sender: UISwitch) {
        self.presenter.set(showHiddenItems: sender.isOn)
    }
}
