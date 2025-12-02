//
//  TaskCell.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import UIKit

class TaskCell: UITableViewCell {
    // MARK: - Identifier
    static let identifier = "TaskCell"
    
    // MARK: - Properties
    var onCheckboxTapped: (() -> Void)?
    var presenter: TaskPresenterInputProtocol?
    
    // MARK: - UI Components
    private lazy var checkboxButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "unchecked"), for: .normal)
        button.setImage(UIImage(named: "checked"), for: .selected)
        button.tintColor = Colors.counterColor
        button.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.isHidden = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 2
        label.isHidden = false
        return label
    }()
    
    private lazy var createdAtLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.isHidden = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, createdAtLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.distribution = .fillProportionally
        return stack
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Cell Config
    func configure(with task: TodoTask) {
        checkboxButton.isSelected = task.isCompleted
        dashCompleted(at: task)
        configDescription(for: task)
        
        createdAtLabel.text = task.createdAt.formattedTaskDate
    }
    // MARK: - Actions
    @objc private func checkboxTapped() {
        onCheckboxTapped?()
    }
    
    // MARK: - UI Layouts
    private func setupUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black
        
        contentView.addSubview(checkboxButton)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkboxButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 48),
            
            stackView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    private func dashCompleted(at task: TodoTask) {
        if task.isCompleted {
            let attributedString = NSMutableAttributedString(string: task.title)
            attributedString.addAttribute(.strikethroughStyle,
                                          value: NSUnderlineStyle.single.rawValue,
                                          range: NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.lightGray,
                                          range: NSRange(location: 0, length: attributedString.length))
            titleLabel.attributedText = attributedString
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = task.title
            titleLabel.textColor = .white
        }
    }
    
    private func configDescription(for task: TodoTask ) {
        if let description = task.description, !description.isEmpty {
            descriptionLabel.text = description
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.text = nil
            descriptionLabel.isHidden = true
        }
        descriptionLabel.textColor = task.isCompleted ? .lightGray : .white
    }
}
