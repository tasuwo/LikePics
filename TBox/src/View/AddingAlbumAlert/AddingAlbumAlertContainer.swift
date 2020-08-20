//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class AddingAlbumAlertContainer: NSObject {
    static let shared = AddingAlbumAlertContainer()

    private weak var currentAlert: UIAlertController?
    private weak var currentSaveAction: UIAlertAction?

    func makeAlert(callback: @escaping ((String?) -> Void)) -> UIAlertController {
        let alert = UIAlertController(title: "新規アルバム",
                                      message: "このアルバムの名前を入力してください",
                                      preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "保存", style: .default) { [weak self] action in
            callback(self?.currentAlert?.textFields?.first?.text)
        }
        saveAction.isEnabled = false
        self.currentSaveAction = saveAction

        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        alert.addTextField { [weak self] textField in
            textField.placeholder = "タイトル"
            textField.delegate = self
        }

        self.currentAlert = alert

        return alert
    }
}

extension AddingAlbumAlertContainer: UITextFieldDelegate {
    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        self.currentSaveAction?.isEnabled = text?.count ?? 0 > 0
        return true
    }
}
