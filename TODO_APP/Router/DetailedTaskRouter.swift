//
//  DetailedTaskRouter.swift
//  TODO_APP
//
//  Created by Marwa Awad on 02.12.2025.
//

import UIKit

protocol DetailedTaskRouterProtocol: AnyObject {
    static func createModule(taskId: String, delegate: TaskUpdateDelegate?) -> UIViewController
}

final class DetailedTaskRouter: DetailedTaskRouterProtocol {
    weak var viewController: UIViewController?
    
    static func createModule(taskId: String, delegate: TaskUpdateDelegate? = nil) -> UIViewController {
        let view = DetailedTaskViewController()
        let interactor = DetailedTaskInteractor()
        let router = DetailedTaskRouter()
        let presenter = DetailedTaskPresenter(taskId: taskId)
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        presenter.taskUpdateDelegate = delegate
        interactor.output = presenter
        router.viewController = view
        
        return view
    }
}
