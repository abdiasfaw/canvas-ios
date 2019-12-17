//
// This file is part of Canvas.
// Copyright (C) 2019-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit
import Core

class ConversationListViewController: UIViewController {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var emptyView: EmptyView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    let env = AppEnvironment.shared
    lazy var conversations = env.subscribe(GetConversations()) { [weak self] in
        self?.update()
    }

    static func create() -> ConversationListViewController {
        return loadFromStoryboard()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .named(.backgroundLightest)
        title = NSLocalizedString("Inbox", comment: "")

        activityIndicatorView.color = Brand.shared.primary

        emptyView.titleText = NSLocalizedString("Inbox Zero", comment: "")
        emptyView.bodyText = NSLocalizedString("You’re all caught up", comment: "")
        emptyView.isHidden = true

        errorView.isHidden = true
        retryButton.setTitle(NSLocalizedString("Retry", comment: ""), for: .normal)
        retryButton.layer.borderColor = UIColor.named(.borderDark).cgColor

        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl?.tintColor = Brand.shared.primary
        tableView.separatorColor = .named(.borderMedium)

        conversations.refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.useModalStyle()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func refresh() {
        emptyView.isHidden = true
        errorView.isHidden = true
        tableView.refreshControl?.beginRefreshing()
        conversations.refresh(force: true)
    }

    func showError(_ error: Error) {
        errorLabel.text = error.localizedDescription
        errorView.isHidden = false
    }

    func update() {
        activityIndicatorView.stopAnimating()
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
        if let error = conversations.error {
            showError(error)
        } else if conversations.isEmpty, !conversations.pending {
            emptyView.isHidden = false
        }
    }
}

extension ConversationListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ConversationListCell = tableView.dequeue(for: indexPath)
        if let conversation = conversations[indexPath] {
            cell.update(conversation)
        }
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isBottomReached() {
            conversations.getNextPage()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let conversation = conversations[indexPath] else { return }
        env.router.route(to: .conversation(conversation.id), from: self)
    }
}
