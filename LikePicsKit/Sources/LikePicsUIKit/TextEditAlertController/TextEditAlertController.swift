//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import UIKit

public class TextEditAlertController: NSObject {
    public typealias Store = CompositeKit.Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>

    private class AlertController: UIAlertController {
        weak var store: Store?
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

    public private(set) var store: Store
    private let dependency = Dependency()

    private weak var presentingAlert: AlertController?
    private weak var presentingSaveAction: UIAlertAction?

    private var subscriptions: Set<AnyCancellable> = .init()

    public var textEditAlertDelegate: TextEditAlertDelegate? {
        get {
            dependency._textEditAlertDelegate
        }
        set {
            dependency._textEditAlertDelegate = newValue
        }
    }

    // MARK: - Lifecycle

    public init(state: TextEditAlertState) {
        self.store = .init(initialState: state, dependency: dependency, reducer: TextEditAlertReducer())
        super.init()
        bind()
    }

    public init(store: Store) {
        self.store = store
        super.init()
        bind()
    }

    // MARK: - Methods

    public func present(with text: String,
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

        let saveAction = UIAlertAction(title: L10n.alertSave, style: .default) { [weak self] _ in
            self?.store.execute(.saveActionTapped)
        }
        alert.addAction(saveAction)
        saveAction.isEnabled = store.stateValue.shouldReturn

        let cancelAction = UIAlertAction(title: L10n.alertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.cancelActionTapped)
        }
        alert.addAction(cancelAction)

        alert.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.placeholder = self.store.stateValue.placeholder
            textField.delegate = self
            textField.text = self.store.stateValue.text
            textField.keyboardType = self.store.stateValue.keyboardType ?? .default
            textField.addTarget(self, action: #selector(self.textFieldDidChange(sender:)), for: .editingChanged)
        }

        alert.store = store
        presentingAlert = alert
        presentingSaveAction = saveAction

        viewController.present(alert, animated: true) { [weak self] in
            self?.store.execute(.presented)
        }
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        presentingAlert?.dismiss(animated: animated, completion: completion)
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
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return store.stateValue.shouldReturn
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        RunLoop.main.perform { [weak self] in
            self?.store.execute(.textChanged(text: textField.text ?? ""))
        }
        return true
    }
}

// MARK: - Bind

public extension TextEditAlertController {
    func bind() {
        store.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.presentingSaveAction?.isEnabled = state.shouldReturn
            }
            .store(in: &subscriptions)
    }
}
