//  TaskViewController.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import UIKit

protocol TaskUpdateDelegate: AnyObject {
    func didUpdateTaskDescription(for taskId: UUID, newDescription: String?)
}

class TaskViewController: UIViewController {
    
    // MARK: - Properties
    var presenter: TaskPresenterInputProtocol?
    private var tasks: [TodoTask] = []
    let blurTag = 9999
    
    // MARK: - UI Components
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .black
        searchBar.searchTextField.backgroundColor = UIColor(white: 0.1, alpha: 1)
        searchBar.searchTextField.textColor = .white
        searchBar.showsBookmarkButton = true
        searchBar.setImage(UIImage(systemName: "mic.fill"), for: .bookmark, state: .normal)
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.identifier)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.darkGray.withAlphaComponent(0.5)
        tableView.estimatedRowHeight = 125
        return tableView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = Colors.counterColor
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var footerBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.footerBackground
        return view
    }()
    
    private lazy var footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        if let addButtonImage = UIImage(named: "new") {
            button.setImage(addButtonImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Navigation bar Configuration
    private func configureNavigationBar() {
        navigationItem.title = "Задачи"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        navigationController?.navigationBar.barStyle = .black
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .white
    }
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         presenter?.viewDidLoad()
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        configureNavigationBar()
        setupUI()
        presenter?.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeBlurFast()
        
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            restoreCellBackground(at: indexPath)
        }
    }

    
    // MARK: - UI Layouts
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(footerBackgroundView)
        
        [searchBar, tableView, loadingIndicator, footerLabel, addButton].forEach {
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            
            footerBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBackgroundView.topAnchor.constraint(equalTo: footerLabel.topAnchor),
            footerBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerLabel.topAnchor, constant: -10),
            
            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            footerLabel.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: 20),
            footerLabel.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            addButton.widthAnchor.constraint(equalToConstant: 68),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

// MARK: - Actions
extension TaskViewController {
    @objc private func addButtonTapped() {
        let alert = AlertManager.createAlert(for: .add { [weak self] title, description in
            self?.presenter?.didTapAddTask(title: title, description: description)
        })
        present(alert, animated: true)
    }
    
    private func editTask(_ task: TodoTask) {
        let alert = AlertManager.createAlert(for: .edit(task: task) { [weak self] title, description in
            self?.presenter?.didUpdateTask(task, newTitle: title, newDescription: description)
        })
        present(alert, animated: true)
    }
    
    private func shareTask(_ task: TodoTask) {
        let text = "Task: \(task.title)\nDescription: \(task.description ?? "")"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - Presenter Output
extension TaskViewController: TaskPresenterOutputProtocol {
    func displayTasks(_ tasks: [TodoTask]) {
        self.tasks = tasks
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }
    
    func displayError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = AlertManager.createAlert(for: .error(message: message))
            self?.present(alert, animated: true)
        }
    }
    
    func showLoading(_ isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isLoading {
                self?.loadingIndicator.startAnimating()
                self?.footerLabel.text = "Loading..."
                self?.footerLabel.textColor = Colors.counterColor
            } else {
                self?.loadingIndicator.stopAnimating()
                self?.footerLabel.textColor = .white
            }
        }
    }
    
    func updateFooter(_ total: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.footerLabel.text = "\(total) Задач"
            self?.footerLabel.textColor = .white
        }
    }
}
// MARK: - UITableViewDataSource & UITableViewDelegate
extension TaskViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.identifier, for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        
        let task = tasks[indexPath.row]
        cell.configure(with: task)
        cell.onCheckboxTapped = { [weak self] in
            self?.presenter?.didSelectTask(task)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = tasks[indexPath.row]
        let detailedVC = DetailedTaskRouter.createModule(taskId: task.id.uuidString, delegate: self)
        detailedVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailedVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let task = tasks[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) as? TaskCell {
            let grayColor = UIColor.systemGray4.withAlphaComponent(0.8)
            cell.contentView.backgroundColor = grayColor
            cell.backgroundColor = grayColor
        
            let backgroundView = UIView()
            backgroundView.backgroundColor = grayColor
            cell.selectedBackgroundView = backgroundView
        }
        
        addBlur()
        
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: { [weak self] _ in
                let editAction = UIAction(
                    title: "Редактировать",
                    image: UIImage(systemName: "pencil")
                ) { _ in
                    // INSTANT RESTORATION
                    self?.restoreCellInstantly(at: indexPath)
                    self?.removeBlurFast()
                    self?.editTask(task)
                }
                
                let shareAction = UIAction(
                    title: "Поделиться",
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { _ in
                    self?.restoreCellInstantly(at: indexPath)
                    self?.removeBlurFast()
                    self?.shareTask(task)
                }
                
                let deleteAction = UIAction(
                    title: "Удалить",
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { _ in
                    self?.restoreCellInstantly(at: indexPath)
                    self?.removeBlurFast()
                    self?.presenter?.didDeleteTask(task)
                }
                
                return UIMenu(title: "", children: [editAction, shareAction, deleteAction])
            }
        )
    }
    
    private func restoreCellInstantly(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TaskCell {
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            cell.selectedBackgroundView = nil
        }
    }
    
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            if let cell = tableView.cellForRow(at: indexPath) as? TaskCell {
                cell.contentView.backgroundColor = .clear
                cell.backgroundColor = .clear
                cell.selectedBackgroundView = nil
            }
        }
        
        removeBlurFast()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.presenter?.didDeleteTask(task)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
// MARK: - UISearchBarDelegate
extension TaskViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter?.didSearch(text: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        presenter?.didSearch(text: "")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}
// MARK: -  TaskUpdateDelegate
extension TaskViewController: TaskUpdateDelegate {
    func didUpdateTaskDescription(for taskId: UUID, newDescription: String?) {
        DispatchQueue.main.async { [weak self] in
            if let index = self?.tasks.firstIndex(where: { $0.id == taskId }) {
                self?.tasks[index].description = newDescription
                let indexPath = IndexPath(row: index, section: 0)
                self?.tableView.reloadRows(at: [indexPath], with: .none)
                self?.updateFooter(self?.tasks.count ?? 0)
            }
        }
    }
}

// MARK: - Blur helpers
extension TaskViewController {
    private func addBlur() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if window.viewWithTag(self.blurTag) != nil {
            return
        }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = window.bounds
        blurView.tag = self.blurTag
        blurView.alpha = 0
        window.addSubview(blurView)
        
        UIView.animate(withDuration: 0.1) {
            blurView.alpha = 1
        }
    }
    
    private func removeBlurFast() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let blurView = window.viewWithTag(self.blurTag) as? UIVisualEffectView else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            blurView.alpha = 0
        }) { _ in
            blurView.removeFromSuperview()
        }
    }
    
    private func restoreCellBackground(at indexPath: IndexPath) {
        restoreCellInstantly(at: indexPath)
    }
    
    private func removeBlurAndRestoreCell(at indexPath: IndexPath) {
        restoreCellInstantly(at: indexPath)
        removeBlurFast()
    }
}
