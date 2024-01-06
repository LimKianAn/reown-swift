import UIKit

import Web3Modal
import WalletConnectRelay
import WalletConnectNetworking

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let app = Application()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        Networking.configure(
            groupIdentifier: "group.com.walletconnect.dapp",
            projectId: InputConfig.projectId,
            socketFactory: DefaultSocketFactory()
        )
        Sign.configure(crypto: DefaultCryptoProvider())

        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "WalletConnect DApp sample",
            url: "wallet.connect",
            icons: ["https://avatars.githubusercontent.com/u/37784886"],
            redirect: AppMetadata.Redirect(native: "wcdapp://", universal: nil)
        )
        
        Web3Modal.configure(
            projectId: InputConfig.projectId,
            metadata: metadata
        )
        
        setupWindow(scene: scene)
    }

    private func setupWindow(scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let viewController = SignModule.create(app: app)

        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}
