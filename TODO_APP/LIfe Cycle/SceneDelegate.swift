//
//  SceneDelegate.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        let taskModule = TaskRouter.createModule()
        self.window = window
        window.rootViewController = taskModule
        window.makeKeyAndVisible()
    }
}
