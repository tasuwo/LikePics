//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

class TextEditAlertController: NSObject {
    typealias TextEditAlertStore = Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>

    private class AlertController: UIAlertController {
        weak var store: Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>?
        deinit {
            store?.execute(.dismissed)
        }
    }

    private var store: TextEditAlertStore

    private weak var presentingAlert: AlertController?
    private weak var presentingSaveAction: UIAlertAction?

    var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(store: TextEditAlertStore) {
        self.store = store
        super.init()

        bind()
    }

    // MARK: - Methods

    func present(with text: String,
                 validator: @escaping (String?) -> Bool,
                 on viewController: UIViewController)
    {
        guard presentingAlert == nil else {
            RootLogger.shared.write(ConsoleLog(level: .info, message: "既にアラート表示中のためpresentを無視します"))
            return
        }

        store.execute(.textChanged(text: text))
        _validator = validator

        let alert = AlertController(title: store.stateValue.title,
                                    message: store.stateValue.message,
                                    preferredStyle: .alert)

        let saveAction = UIAlertAction(title: L10n.confirmAlertSave, style: .default) { [weak self] _ in
            self?.store.execute(.saveActionTapped)
        }
        alert.addAction(saveAction)
        saveAction.isEnabled = store.stateValue.shouldReturn

        let cancelAction = UIAlertAction(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.cancelActionTapped)
        }
        alert.addAction(cancelAction)

        alert.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.placeholder = self.store.stateValue.placeholder
            textField.delegate = self
            textField.text = self.store.stateValue.text
            textField.addTarget(self, action: #selector(self.textFieldDidChange(sender:)), for: .editingChanged)
        }

        alert.store = store
        presentingAlert = alert
        presentingSaveAction = saveAction

        viewController.present(alert, animated: true, completion: nil)
    }

    @objc
    private func textFieldDidChange(sender: UITextField) {
        RunLoop.main.perform { [weak self] in
            self?.store.execute(.textChanged(text: sender.text ?? ""))
        }
    }
}

// MARK: - UITextFieldDelegate

extension TextEditAlertController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return store.stateValue.shouldReturn
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        RunLoop.main.perform { [weak self] in
            self?.store.execute(.textChanged(text: textField.text ?? ""))
        }
        return true
    }
}

// MARK: - Bind

extension TextEditAlertController {
    func bind() {
        store.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.presentingSaveAction?.isEnabled = state.shouldReturn
            }
            .store(in: &subscriptions)
    }
}
