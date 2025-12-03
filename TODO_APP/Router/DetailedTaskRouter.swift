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
        let detailedTaskViewController = DetailedTaskViewController()
        let interactor = DetailedTaskInteractor()
        let router = DetailedTaskRouter()
        let presenter = DetailedTaskPresenter(taskId: taskId)
        
        detailedTaskViewController.presenter = presenter
        presenter.detailedTaskPresenterOutputProtocol = detailedTaskViewController
        presenter.detailedTaskInteractorInputProtocol = interactor
        presenter.router = router
        presenter.taskUpdateDelegate = delegate
        interactor.detailedTaskInteractorOutputProtocol = presenter
        router.viewController = detailedTaskViewController
        
        return detailedTaskViewController
    }
}
