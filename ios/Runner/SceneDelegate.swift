import UIKit
import Flutter

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let flutterViewController = FlutterViewController()

    self.window = UIWindow(windowScene: windowScene)
    self.window?.rootViewController = flutterViewController
    self.window?.makeKeyAndVisible()
  }
}
