import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps: prefer GMSApiKey from Info.plist ($(GOOGLE_MAPS_API_KEY) via Secrets.xcconfig).
    // If the key is missing or still contains $(...) after build, fall back to the same key as
    // AndroidManifest — otherwise Release builds call provideAPIKey with an empty string and tiles never load.
    let plistKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String
    let manifestAlignedFallback = "AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k"
    var mapsKey = (plistKey?.isEmpty == false) ? plistKey! : manifestAlignedFallback
    if mapsKey.contains("$(") {
      mapsKey = manifestAlignedFallback
    }
    if !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "wandermood",
       url.host == "share",
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let urlParam = components.queryItems?
         .first(where: { $0.name == "url" })?.value {
      notifyFlutterSharedUrl(urlParam)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  private func notifyFlutterSharedUrl(_ urlParam: String) {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.wandermood/share",
      binaryMessenger: controller.binaryMessenger
    )
    channel.invokeMethod("handleSharedUrl", arguments: ["url": urlParam])
  }
}
