//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class AddingAlert: NSObject {
    enum Action {
        case saved(text: String)
        case cancelled
        case error
    }

    struct Configuration {
        let title: String?
        let message: String?
        let placeholder: String
    }

    var isPresenting: Bool {
        self.currentAlert != nil
    }

    private let configuration: Configuration
    private weak var baseView: UIViewController?
    private weak var currentAlert: UIAlertController?
    private weak var currentSaveAction: UIAlertAction?

    // MARK: - Lifecycle

    init(configuration: Configuration, baseView: UIViewController) {
        self.configuration = configuration
        self.baseView = baseView
    }

    // MARK: - Methods

    func present(completion: @escaping (Action) -> Void) {
        let alert = UIAlertController(title: self.configuration.title,
                                      message: self.configuration.message,
                                      preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let text = self?.currentAlert?.textFields?.first?.text else {
                completion(.error)
                return
            }
            completion(.saved(text: text))
        }
        saveAction.isEnabled = false

        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in
            completion(.cancelled)
        })

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        alert.addTextField { [weak self] textField in
            textField.placeholder = self?.configuration.placeholder ?? ""
            textField.delegate = self
        }

        self.currentAlert = alert
        self.currentSaveAction = saveAction

        self.baseView?.present(alert, animated: true, completion: nil)
    }
}

extension AddingAlert: UITextFieldDelegate {
    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        self.currentSaveAction?.isEnabled = text?.count ?? 0 > 0
        return true
    }
}
