import UIKit
import SwiftUI

protocol SceneDelegateType {
    var window: UIWindow? { get }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)
    func sceneWillEnterForeground(_ scene: UIScene)
}

class SceneDelegate: SceneDelegateType {
    private(set) var window: UIWindow?
    private let paymentService: PaymentServiceType

    init(paymentService: PaymentServiceType = PaymentService.shared) {
        self.paymentService = paymentService
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ConsumableView())
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        _ = paymentService.recoveryPendingTransactions()
    }
}
