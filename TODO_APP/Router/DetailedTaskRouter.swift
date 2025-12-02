//
//  DetailedTaskRouter.swift
//  TODO_APP
//
//  Created by Marwa Awad on 02.12.2025.
//

import UIKit

protocol DetailedTaskRouterProtocol: AnyObject {
    func navigateBack()
}

final class DetailedTaskRouter: DetailedTaskRouterProtocol {
    
    weak var viewController: UIViewController?
    
    static func createModule(taskId: String) -> UIViewController {
        let view = DetailedTaskViewController()
        let interactor = DetailedTaskInteractor()
        let router = DetailedTaskRouter()
        let presenter = DetailedTaskPresenter(taskId: taskId)
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.output = presenter
        router.viewController = view
        
        return view
    }
    
    func navigateBack() {
        DispatchQueue.main.async {
            if let navigationController = self.viewController?.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.viewController?.dismiss(animated: true)
            }
        }
    }
}
