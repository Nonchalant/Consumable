import UIKit
import SwiftUI

class SceneDelegateProxy: UIResponder, UIWindowSceneDelegate {
    let sceneDelegate = SceneDelegate()

    var window: UIWindow? {
        get { sceneDelegate.window }
        set { assertionFailure("Unexpected window settter call: \(newValue as UIWindow?)")}
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        sceneDelegate.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        sceneDelegate.sceneWillEnterForeground(scene)
    }
}
