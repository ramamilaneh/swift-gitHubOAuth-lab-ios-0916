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
    var currentViewController: UIViewController!

    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInitialViewController()
        addNotificationObservers()

    }
    
    // MARK: Set Up
    
    private func loadInitialViewController() {
        
        if GitHubAPIClient.hasToken() {
            self.currentViewController = loadViewControllerWith(id: StoryboardID.reposTVC)
            addCurrentViewController(self.currentViewController)
        } else {
            self.currentViewController = loadViewControllerWith(id: StoryboardID.loginVC)
            addCurrentViewController(self.currentViewController)
        }
        
    }
    
    private func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(switchViewController(_:)), name: .closeLoginVC, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(switchViewController(_:)), name: .closeReposTVC, object: nil)
        
    }
    
    // MARK: View Controller Handling
    
    private func loadViewControllerWith(id: String) -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        switch id {
        case StoryboardID.loginVC:
            return storyboard.instantiateViewController(withIdentifier: id) as! LoginViewController
        case StoryboardID.reposTVC:
            let vc = storyboard.instantiateViewController(withIdentifier: id) as! RepositoryTableViewController
            let navVC = UINavigationController(rootViewController: vc)
            return navVC
        default:
            fatalError("ERROR: Unable to find controller with storyboard id: \(id)")
        }
        
        
    }
    
    private func addCurrentViewController(_ controller: UIViewController) {
        
        self.addChildViewController(controller)
        self.containerView.addSubview(controller.view)
        controller.view.frame = self.containerView.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.didMove(toParentViewController: self)
        
    }
    
    func switchViewController(_ notification: Notification) {
        
        switch notification.name {
        case Notification.Name.closeLoginVC:
            switchToViewControllerWith(id: StoryboardID.reposTVC)
        case Notification.Name.closeReposTVC:
            switchToViewControllerWith(id: StoryboardID.loginVC)
        default:
            fatalError("ERROR: Unable to match notification name")
        }
        
    }
    
    private func switchToViewControllerWith(id: String) {
        
        let oldViewController = self.currentViewController
        oldViewController?.willMove(toParentViewController: nil)

        self.currentViewController = loadViewControllerWith(id: id)
        self.addChildViewController(self.currentViewController)

        addCurrentViewController(self.currentViewController)
        self.currentViewController.view.alpha = 0

        UIView.animate(withDuration: 0.5, animations: {

            self.currentViewController.view.alpha = 1
            oldViewController?.view.alpha = 0

        }) { completed in
            oldViewController?.view.removeFromSuperview()
            oldViewController?.removeFromParentViewController()
            self.currentViewController.didMove(toParentViewController: self)
        }
        
    }
    
}





