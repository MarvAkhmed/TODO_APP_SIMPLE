//
//  TaskRouter.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import UIKit

protocol TaskRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
}

final class TaskRouter: TaskRouterProtocol {
    static func createModule() -> UIViewController {
        let view = TaskViewController()
        let presenter = TaskPresenter()
        let interactor = TaskInteractor()
        let router = TaskRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        let navigationController = UINavigationController(rootViewController: view)
        return navigationController
    }
}
