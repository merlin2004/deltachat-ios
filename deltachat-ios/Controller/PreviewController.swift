import QuickLook
import UIKit

class PreviewController: QLPreviewController {

    private var urls: [URL]

    private lazy var doneButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(title: String.localized("done"), style: .done, target: self, action: #selector(doneButtonPressed(_:)))
        return button
    }()

    private let bottomToolbarIdentifier = "QLCustomToolBarModalAccessibilityIdentifier"
    private let shareIdentifier = "QLOverlayDefaultActionButtonAccessibilityIdentifier"
    private let listButtonIdentifier = "QLOverlayListButtonAccessibilityIdentifier"

    init(currentIndex: Int, urls: [URL]) {
        self.urls = urls
        super.init(nibName: nil, bundle: nil)
        dataSource = self
        currentPreviewItemIndex = currentIndex
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationController?.isBeingPresented ?? false {
            /*
             QLPreviewController comes with a done-button by default. But if is embedded in UINavigationContrller we need to set a done-button manually.
            */
            navigationItem.leftBarButtonItem = doneButtonItem
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // native toolbar is accessable just on and after viewWillAppear
        let bottomToolbar = traverseSearchToolbar(root: self.view)
        if let bottomToolbar = bottomToolbar {
            hideListItem(toolbar: bottomToolbar)
        }
        hideListButtonInNavigationBarIfNeeded()
    }

    // MARK: - actions
    @objc private func doneButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PreviewController: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        return urls.count
    }

    func previewController(_: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return urls[index] as QLPreviewItem
    }
}

// MARK: - customisation (to hide list button)
private extension PreviewController {
    // MARK: - bottom bar customisation
    func traverseSearchToolbar(root: UIView) -> UIToolbar? {

        if let toolbar = root as? UIToolbar {
            if toolbar.accessibilityIdentifier == bottomToolbarIdentifier {
                return toolbar
            }
        }
        if root.subviews.isEmpty {
            return nil
        }

        var subviews = root.subviews
        var current = subviews.popLast()
        while current != nil {
            if let current = current, let toolbar = traverseSearchToolbar(root: current) {
                return toolbar
            }
            current = subviews.popLast()
        }
        return nil
    }

    func hideListItem(toolbar: UIToolbar) {
        // share item, flex item, list item
        for item in toolbar.items ?? [] {
            if item.accessibilityIdentifier == listButtonIdentifier {
                item.tintColor = .clear
                item.action = nil
            }
        }
    }

    // MARK: - navigation bar customization

    func getQLNavigationBar(rootView: UIView) -> UINavigationBar? {
        for subview in rootView.subviews {
            if subview is UINavigationBar {
                return subview as? UINavigationBar
            } else {
                if let navigationBar = self.getQLNavigationBar(rootView: subview) {
                    return navigationBar
                }
            }
        }
        return nil
    }

    func hideListButtonInNavigationBarIfNeeded() {
        guard let navBar = getQLNavigationBar(rootView: view) else {
            return
        }
        if let items = navBar.items, let item = items.first {
           let leftItems = item.leftBarButtonItems
            let listButton = leftItems?.filter { $0.accessibilityIdentifier == listButtonIdentifier }.first
            // listButton is impossible to remove so we make it invisible
            listButton?.isEnabled = false
            listButton?.tintColor = .clear
        }
    }

}
