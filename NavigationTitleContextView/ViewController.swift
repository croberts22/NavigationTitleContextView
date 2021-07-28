//
//  ViewController.swift
//  NavigationTitleContextView
//
//  Created by Corey Roberts on 7/22/21.
//

import UIKit

class ViewController: UITableViewController {

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
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.titleView.subtitle = "Synchronizing with webservices now..."
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
//                self?.titleView.subtitle = "Done synchronizing, yay!"
//            }
//        }
    }

}

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
    
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Display subtitle, animated, for 3 seconds"
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            titleView.animateSubtitleUpdates = true
            titleView.subtitle = "Displaying a long subtitle for a few seconds..."
        default:
            break
        }
    }
    
}

