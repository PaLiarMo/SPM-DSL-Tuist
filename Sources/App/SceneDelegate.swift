import UIKit
import Router_Impl
import Router_Api

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        let navigationController = UINavigationController()

        let router: AppRouter = makeAppRouter(navigationController: navigationController)
        router.showHome()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
