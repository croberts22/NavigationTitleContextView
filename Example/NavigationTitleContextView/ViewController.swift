//
//  ViewController.swift
//  NavigationTitleContextView
//
//  Created by Corey Roberts on 7/22/21.
//

import Combine
import UIKit

// MARK: - ViewController

class ViewController: UITableViewController {

    private var cancellables = Set<AnyCancellable>()

    private let titleView: NavigationTitleContextView = {
        let titleView = NavigationTitleContextView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        return titleView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        titleView.title = "Context Title Demo"
        navigationItem.titleView = titleView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")

        titleView.userInteractionPublisher
            .sink { [weak self] in
                let alert = UIAlertController(title: "You pressed me!", message: "What do you want to do?", preferredStyle: .actionSheet)

                let animateAction = UIAlertAction(title: "Animate subtitle updates", style: .default) { [weak self] _ in
                    self?.titleView.animateSubtitleUpdates = true
                    print("Subtitle updates will now be animated.")
                }

                let dontAnimateAction = UIAlertAction(title: "Don't animate subtitle updates", style: .default) { [weak self] _ in
                    self?.titleView.animateSubtitleUpdates = false
                    print("Subtitle updates will now _not_ be animated.")
                }

                let cancelAction = UIAlertAction(title: "（╯°□°）╯︵ ┻━┻", style: .cancel)

                alert.addAction(animateAction)
                alert.addAction(dontAnimateAction)
                alert.addAction(cancelAction)

                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &cancellables)
    }
}

extension ViewController {

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Display a long subtitle (2 seconds)"
        case 1:
            cell.textLabel?.text = "Display a subtitle, interrupt with another"
        default:
            break
        }

        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            titleView.setSubtitle("Displaying a long subtitle for two seconds...", hideAfter: 2.0)
        case 1:
            titleView.subtitle = "This subtitle will get interrupted in two seconds..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.titleView.subtitle = "New subtitle coming in~"
            }
        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
