//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class TextEditAlert: NSObject {
    public typealias Validator = (String?) -> Bool

    public enum Action {
        case saved(text: String)
        case cancelled
        case error
    }

    public struct Configuration {
        public let title: String?
        public let message: String?
        public let placeholder: String

        public init(title: String?, message: String?, placeholder: String) {
            self.title = title
            self.message = message
            self.placeholder = placeholder
        }
    }

    private class Context {
        weak var alert: UIAlertController?
        weak var saveAction: UIAlertAction?
        let validator: Validator?

        var text: String? {
            return self.alert?.textFields?.first?.text
        }

        var isTextValid: Bool {
            guard let validator = self.validator else { return true }
            return validator(self.text)
        }

        init(alert: UIAlertController, saveAction: UIAlertAction, validator: Validator?) {
            self.alert = alert
            self.saveAction = saveAction
            self.validator = validator
        }

        func performValidation() {
            guard let validator = self.validator else { return }
            self.saveAction?.isEnabled = validator(self.text)
        }
    }

    public var isPresenting: Bool {
        self.context != nil
    }

    private let configuration: Configuration
    private var context: Context?

    // MARK: - Lifecycle

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Methods

    public func present(withText text: String?,
                        on baseView: UIViewController,
                        validator: Validator? = nil,
                        completion: @escaping (Action) -> Void)
    {
        let alert = UIAlertController(title: self.configuration.title,
                                      message: self.configuration.message,
                                      preferredStyle: .alert)

        let saveAction = UIAlertAction(title: L10n.addingAlertActionSave, style: .default) { [weak self] _ in
            guard let text = self?.context?.text else {
                completion(.error)
                return
            }
            completion(.saved(text: text))
        }
        saveAction.isEnabled = false

        let cancelAction = UIAlertAction(title: L10n.addingAlertActionCancel, style: .cancel, handler: { _ in
            completion(.cancelled)
        })

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        alert.addTextField { [weak self] textField in
            textField.placeholder = self?.configuration.placeholder ?? ""
            textField.delegate = self
            textField.addTarget(self, action: #selector(TextEditAlert.textFieldDidChange), for: .editingChanged)
            textField.text = text
        }

        self.context = .init(alert: alert, saveAction: saveAction, validator: validator)
        self.context?.performValidation()

        baseView.present(alert, animated: true, completion: nil)
    }

    @objc
    private func textFieldDidChange() {
        RunLoop.main.perform { [weak self] in
            self?.context?.performValidation()
        }
    }
}

extension TextEditAlert: UITextFieldDelegate {
    // MARK: - UITextFieldDelegate

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.context?.isTextValid ?? true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        RunLoop.main.perform { [weak self] in
            self?.context?.performValidation()
        }
        return true
    }
}
