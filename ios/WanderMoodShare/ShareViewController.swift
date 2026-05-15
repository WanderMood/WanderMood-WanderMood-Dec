import UIKit
import UniformTypeIdentifiers

/// Share extension: forward a URL into the main app via `wandermood://share?url=…`.
/// Extensions cannot use `UIApplication.shared.open` — use `NSExtensionContext.open`.
class ShareViewController: UIViewController {

  private let appGroupId = "group.com.edviennemer.wandermood.share"
  private var progressView: UIActivityIndicatorView?
  private var didFinish = false

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
          let attachments = item.attachments,
          !attachments.isEmpty else {
      finishExtension()
      return
    }

    let ordered = attachments.sorted { a, b in
      // Prefer explicit URL types before plain text (TikTok often provides text + metadata).
      let aScore = typePriority(a)
      let bScore = typePriority(b)
      if aScore != bScore { return aScore < bScore }
      return false
    }

    loadSharedURL(from: ordered, index: 0)
  }

  /// Lower = try first (URL providers before plain text).
  private func typePriority(_ provider: NSItemProvider) -> Int {
    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
      || provider.hasItemConformingToTypeIdentifier("public.url") { return 0 }
    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
      || provider.hasItemConformingToTypeIdentifier("public.plain-text")
      || provider.hasItemConformingToTypeIdentifier("public.text") { return 1 }
    return 9
  }

  private func loadSharedURL(from providers: [NSItemProvider], index: Int) {
    if index >= providers.count {
      finishExtension()
      return
    }
    let provider = providers[index]

    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
      || provider.hasItemConformingToTypeIdentifier("public.url") {
      loadItemAsURL(provider) { [weak self] raw in
        guard let self else { return }
        if let raw, let link = self.deepLink(forSharedURL: raw) {
          self.persistPending(raw)
          self.openHostApp(deepLink: link)
        } else {
          self.loadSharedURL(from: providers, index: index + 1)
        }
      }
      return
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
      || provider.hasItemConformingToTypeIdentifier("public.plain-text")
      || provider.hasItemConformingToTypeIdentifier("public.text") {
      loadItemAsText(provider) { [weak self] text in
        guard let self else { return }
        let raw = text.flatMap { self.extractURLFromPlainText($0) }
        if let raw, let link = self.deepLink(forSharedURL: raw) {
          self.persistPending(raw)
          self.openHostApp(deepLink: link)
        } else {
          self.loadSharedURL(from: providers, index: index + 1)
        }
      }
      return
    }

    tryUnknownProvider(provider) { [weak self] raw in
      guard let self else { return }
      if let raw, let link = self.deepLink(forSharedURL: raw) {
        self.persistPending(raw)
        self.openHostApp(deepLink: link)
      } else {
        self.loadSharedURL(from: providers, index: index + 1)
      }
    }
  }

  /// Instagram / TikTok sometimes use UTIs we do not map explicitly — walk [registeredTypeIdentifiers].
  private func tryUnknownProvider(
    _ provider: NSItemProvider,
    completion: @escaping (String?) -> Void
  ) {
    let types = provider.registeredTypeIdentifiers
    tryLoadRegisteredType(provider, types: types, index: 0, completion: completion)
  }

  private func tryLoadRegisteredType(
    _ provider: NSItemProvider,
    types: [String],
    index: Int,
    completion: @escaping (String?) -> Void
  ) {
    if index >= types.count {
      completion(nil)
      return
    }
    let typeId = types[index]
    provider.loadItem(forTypeIdentifier: typeId, options: nil) { [weak self] item, _ in
      let urlString = self?.coerceItemToSharedURLString(item)
      if let s = urlString, !s.isEmpty {
        completion(s)
        return
      }
      self?.tryLoadRegisteredType(provider, types: types, index: index + 1, completion: completion)
    }
  }

  private func coerceItemToSharedURLString(_ item: Any?) -> String? {
    if let url = item as? URL, url.scheme != nil {
      return url.absoluteString
    }
    if let str = item as? String {
      if let u = URL(string: str), u.scheme != nil { return u.absoluteString }
      return extractURLFromPlainText(str)
    }
    if let data = item as? Data, let str = String(data: data, encoding: .utf8) {
      return extractURLFromPlainText(str)
    }
    if let dict = item as? [String: Any] {
      for (_, val) in dict {
        if let s = coerceItemToSharedURLString(val) { return s }
      }
    }
    return nil
  }

  private func loadItemAsURL(
    _ provider: NSItemProvider,
    completion: @escaping (String?) -> Void
  ) {
    let typeId =
      provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
      ? UTType.url.identifier : "public.url"
    provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, _ in
      if let url = item as? URL {
        completion(url.absoluteString)
        return
      }
      if let str = item as? String, let u = URL(string: str), u.scheme != nil {
        completion(u.absoluteString)
        return
      }
      completion(nil)
    }
  }

  private func loadItemAsText(
    _ provider: NSItemProvider,
    completion: @escaping (String?) -> Void
  ) {
    let typeId: String = {
      if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
        return UTType.plainText.identifier
      }
      if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
        return "public.plain-text"
      }
      return "public.text"
    }()
    provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, _ in
      if let str = item as? String {
        completion(str)
        return
      }
      if let data = item as? Data, let str = String(data: data, encoding: .utf8) {
        completion(str)
        return
      }
      completion(nil)
    }
  }

  private func extractURLFromPlainText(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if let u = URL(string: trimmed), u.scheme != nil {
      return u.absoluteString
    }
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
      return nil
    }
    let ns = trimmed as NSString
    let full = NSRange(location: 0, length: ns.length)
    if let match = detector.firstMatch(in: trimmed, options: [], range: full),
       let url = match.url {
      return url.absoluteString
    }
    return nil
  }

  /// Builds `wandermood://share?url=…` with correct query encoding (avoids broken `&` in TikTok URLs).
  private func deepLink(forSharedURL raw: String) -> URL? {
    var c = URLComponents()
    c.scheme = "wandermood"
    c.host = "share"
    c.queryItems = [URLQueryItem(name: "url", value: raw)]
    return c.url
  }

  private func persistPending(_ raw: String) {
    if let defaults = UserDefaults(suiteName: appGroupId) {
      defaults.set(raw, forKey: "pending_share_url")
      defaults.synchronize()
    }
  }

  /// Opens the containing app; **must** use extension context (not UIApplication).
  private func openHostApp(deepLink: URL) {
    guard let ctx = extensionContext else {
      finishExtension()
      return
    }
    ctx.open(deepLink, completionHandler: { [weak self] _ in
      self?.finishExtension()
    })
  }

  private func finishExtension() {
    guard !didFinish else { return }
    didFinish = true
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
