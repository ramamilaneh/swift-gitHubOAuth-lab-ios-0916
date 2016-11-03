//
//  AppController.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/29/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit

class AppController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    var actingViewController: UIViewController!

    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInitialViewController()
        addNotificationObservers()

    }
    
    // MARK: Set Up
    
    private func loadInitialViewController() {
        
        if GitHubAPIClient.hasToken() {
            actingViewController = loadViewController(withID: .reposTVC)
        } else {
            actingViewController = loadViewController(withID: .loginVC)
        }
        addActing(viewController: actingViewController)
        
    }
    
    private func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(switchViewController(with:)), name: .closeLoginVC, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(switchViewController(with:)), name: .closeReposTVC, object: nil)
        
    }
    
    // MARK: View Controller Handling
    
    private func loadViewController(withID id: StoryboardID) -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        switch id {
        case .loginVC:
            return storyboard.instantiateViewController(withIdentifier: id.rawValue) as! LoginViewController
        case .reposTVC:
            let vc = storyboard.instantiateViewController(withIdentifier: id.rawValue) as! RepositoryTableViewController
            let navVC = UINavigationController(rootViewController: vc)
            return navVC
        default:
            fatalError("ERROR: Unable to find controller with storyboard id: \(id)")
        }
        
        
    }
    
    private func addActing(viewController: UIViewController) {
        
        self.addChildViewController(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParentViewController: self)
        
    }
    
    func switchViewController(with notification: Notification) {
        
        switch notification.name {
        case Notification.Name.closeLoginVC:
            switchToViewController(withID: .reposTVC)
        case Notification.Name.closeReposTVC:
            switchToViewController(withID: .loginVC)
        default:
            fatalError("ERROR: Unable to match notification name")
        }
        
    }
    
    private func switchToViewController(withID id: StoryboardID) {
        
        let exitingViewController = actingViewController
        exitingViewController?.willMove(toParentViewController: nil)

        actingViewController = loadViewController(withID: id)
        self.addChildViewController(actingViewController)

        addActing(viewController: actingViewController)
        actingViewController.view.alpha = 0

        UIView.animate(withDuration: 0.5, animations: {

            self.actingViewController.view.alpha = 1
            exitingViewController?.view.alpha = 0

        }) { completed in
            exitingViewController?.view.removeFromSuperview()
            exitingViewController?.removeFromParentViewController()
            self.actingViewController.didMove(toParentViewController: self)
        }
        
    }
    
}





