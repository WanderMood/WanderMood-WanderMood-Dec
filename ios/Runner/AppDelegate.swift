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
}
