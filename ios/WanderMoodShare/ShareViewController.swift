import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

  private let appGroupId = "group.com.edviennemer.wandermood.share"
  private var progressView: UIActivityIndicatorView?

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    extractAndForward()
  }

  private func setupUI() {
    view.backgroundColor = UIColor(red: 0.102, green: 0.090, blue: 0.078, alpha: 1)

    let circle = UIView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    circle.backgroundColor = UIColor(red: 0.165, green: 0.376, blue: 0.286, alpha: 1)
    circle.layer.cornerRadius = 32
    circle.center = CGPoint(x: view.center.x, y: view.center.y - 30)

    let label = UILabel()
    label.text = "M"
    label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    label.textColor = UIColor(red: 0.365, green: 0.792, blue: 0.647, alpha: 1)
    label.sizeToFit()
    label.center = CGPoint(x: 32, y: 32)
    circle.addSubview(label)
    view.addSubview(circle)

    let sub = UILabel()
    sub.text = "Aan het zoeken..."
    sub.font = UIFont.systemFont(ofSize: 14)
    sub.textColor = UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 0.7)
    sub.sizeToFit()
    sub.center = CGPoint(x: view.center.x, y: view.center.y + 20)
    view.addSubview(sub)

    let spinner = UIActivityIndicatorView(style: .medium)
    spinner.color = UIColor(red: 0.365, green: 0.792, blue: 0.647, alpha: 1)
    spinner.center = CGPoint(x: view.center.x, y: view.center.y + 52)
    spinner.startAnimating()
    view.addSubview(spinner)
    progressView = spinner
  }

  private func extractAndForward() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments else {
      finishExtension()
      return
    }

    let urlType = UTType.url.identifier
    guard let provider = attachments.first(where: {
      $0.hasItemConformingToTypeIdentifier(urlType) ||
        $0.hasItemConformingToTypeIdentifier("public.url")
    }) else {
      finishExtension()
      return
    }

    provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] item, _ in
      let urlString: String?
      if let url = item as? URL {
        urlString = url.absoluteString
      } else if let str = item as? String {
        urlString = str
      } else {
        urlString = nil
      }

      guard let raw = urlString,
            let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let deepLink = URL(string: "wandermood://share?url=\(encoded)") else {
        self?.finishExtension()
        return
      }

      if let defaults = UserDefaults(suiteName: self?.appGroupId ?? "") {
        defaults.set(raw, forKey: "pending_share_url")
        defaults.synchronize()
      }

      self?.extensionContext?.completeRequest(returningItems: nil) { _ in
        _ = self?.openURL(deepLink)
      }
    }
  }

  private func finishExtension() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  @objc func openURL(_ url: URL) -> Bool {
    var responder: UIResponder? = self
    while let current = responder {
      if let application = current as? UIApplication {
        return application.perform(#selector(openURL(_:)), with: url) != nil
      }
      responder = current.next
    }
    return false
  }
}
