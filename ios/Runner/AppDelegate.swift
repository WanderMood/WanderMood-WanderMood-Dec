import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps: release uses GMSApiKey from Info.plist ($(GOOGLE_MAPS_API_KEY) via Secrets.xcconfig).
    let plistKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String
    #if DEBUG
    let debugFallback = "AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k"
    #else
    let debugFallback = ""
    #endif
    let mapsKey = (plistKey?.isEmpty == false) ? plistKey! : debugFallback
    if !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
