import UIKit

private let minimumSpacing: CGFloat = 16.0

class IdentifierTableViewCell: UITableViewCell {

    static let reuseID = "IDENTIFIER_REUSE_ID"

    private var identifierLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var identifierText: String {
        get { return identifierLabel.text ?? "" }
        set { identifierLabel.text = newValue }
    }

    private var confidenceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var confidence: String {
        get { return confidenceLabel.text ?? "" }
        set { confidenceLabel.text = newValue }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Setup

private extension IdentifierTableViewCell {

    func setupViews() {
        backgroundColor = .clear
        addSubview(identifierLabel)
        addSubview(confidenceLabel)
    }

    func setupConstraints() {
        let identifierConstraints = [
            identifierLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            identifierLabel.trailingAnchor.constraint(
                equalTo: confidenceLabel.leadingAnchor,
                constant: -minimumSpacing
            ),
            identifierLabel.topAnchor.constraint(equalTo: readableContentGuide.topAnchor),
            identifierLabel.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor)
        ]
        let confidenceConstraints = [
            confidenceLabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            confidenceLabel.centerYAnchor.constraint(equalTo: identifierLabel.centerYAnchor)
        ]
        NSLayoutConstraint.activate(identifierConstraints)
        NSLayoutConstraint.activate(confidenceConstraints)
    }
}
