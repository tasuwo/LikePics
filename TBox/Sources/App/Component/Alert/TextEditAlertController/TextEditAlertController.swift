//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

class TextEditAlertController: NSObject {
    typealias TextEditAlertStore = Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>

    private class AlertController: UIAlertController {
        weak var store: TextEditAlertStore?
        deinit {
            store?.execute(.dismissed)
        }
    }

    private class Dependency: TextEditAlertDependency {
        // swiftlint:disable identifier_name
        var _textValidator: ((String?) -> Bool)?
        weak var _textEditAlertDelegate: TextEditAlertDelegate?

        var textValidator: (String?) -> Bool {
            return { [weak self] text in
                guard let validator = self?._textValidator else { return true }
                return validator(text)
            }
        }

        var textEditAlertDelegate: TextEditAlertDelegate? { _textEditAlertDelegate }
    }

    private(set) var store: TextEditAlertStore
    private let dependency = Dependency()

    private weak var presentingAlert: AlertController?
    private weak var presentingSaveAction: UIAlertAction?

    private var subscriptions: Set<AnyCancellable> = .init()

    var textEditAlertDelegate: TextEditAlertDelegate? {
        get {
            dependency._textEditAlertDelegate
        }
        set {
            dependency._textEditAlertDelegate = newValue
        }
    }

    // MARK: - Lifecycle

    init(state: TextEditAlertState) {
        self.store = .init(initialState: state, dependency: dependency, reducer: TextEditAlertReducer.self)
        super.init()
        bind()
    }

    // MARK: - Methods

    func present(with text: String,
                 validator: @escaping (String?) -> Bool,
                 on viewController: UIViewController)
    {
        guard presentingAlert == nil else {
            return
        }

        dependency._textValidator = validator
        store.execute(.textChanged(text: text))

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

        viewController.present(alert, animated: true) { [weak self] in
            self?.store.execute(.presented)
        }
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
