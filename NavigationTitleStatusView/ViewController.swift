//
//  ViewController.swift
//  NavigationTitleStatusView
//
//  Created by Corey Roberts on 7/22/21.
//

import UIKit

class ViewController: UITableViewController {

    private let titleView: NavigationTitleStatusView = {
        let titleView = NavigationTitleStatusView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        return titleView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleView.title = "Title View"
        
        navigationItem.titleView = titleView
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.titleView.subtitle = "Synchronizing with webservices now..."

            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                self?.titleView.subtitle = "Done synchronizing, yay!"
            }
        }
    }


}

