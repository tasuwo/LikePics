//
//  Copyright © 2024 Tasuku Tozawa. All rights reserved.
//

import Cocoa
import ShareExtensionDesktopFeature

let bundleIdentifier = {
    guard var components = Bundle.main.bundleIdentifier?.components(separatedBy: ".") else { fatalError() }
    components.removeLast()
    return components.joined(separator: ".")
}()

final class ShareViewController: NSViewController {
    private let container = Container(bundleIdentifier: bundleIdentifier)

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    override func loadView() {
        super.loadView()
    
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachments = item.attachments {
            NSLog("Attachments = %@", attachments as NSArray)
        } else {
            NSLog("No Attachments")
        }
    }

    @IBAction func send(_ sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation by setting the appropriate value on the output item
    
        let outputItems = [outputItem]
        self.extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
}

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }

}