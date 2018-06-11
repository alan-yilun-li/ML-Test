import UIKit

class PrincipalDisplayViewController: UIViewController {

    var presenter: PrincipalDisplayPresenter

    private var tableView = UITableView(frame: .zero)
    var cameraDisplayView = CameraDisplayView(frame: .zero)
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

    init(presenter: PrincipalDisplayPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        tableView.dataSource = presenter
        presenter.viewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(
            IdentifierTableViewCell.self,
            forCellReuseIdentifier: IdentifierTableViewCell.reuseID
        )
        setupViews()
        setupConstraints()
        presenter.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.viewDidAppear()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        presenter.viewDidDisappear()
    }
}

// MARK: - Actions
extension PrincipalDisplayViewController {

    func showLoadingSpinner() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    func hideLoadingSpinner(permanently: Bool) {
        if permanently {
            activityIndicator.removeFromSuperview()
        } else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
    }

    func reloadData() {
        tableView.reloadData()
    }
}

// MARK: - View Setup
private extension PrincipalDisplayViewController {

    func setupViews() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true

        tableView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = tableView.frame
        tableView.backgroundView = blurEffectView
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)

        cameraDisplayView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false 

        activityIndicator.isHidden = true
        
        view.addSubview(cameraDisplayView)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
    }

    func setupConstraints() {
        let cameraDisplayConstraints = [
            cameraDisplayView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraDisplayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraDisplayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraDisplayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        let tableViewConstraints = [
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/4)
        ]
        let activityConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(cameraDisplayConstraints)
        NSLayoutConstraint.activate(tableViewConstraints)
        NSLayoutConstraint.activate(activityConstraints)
    }
}
