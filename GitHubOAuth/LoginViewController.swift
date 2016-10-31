//
//  LoginViewController.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/28/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit
import Locksmith

// SOLUTION: import safari services, add delegate
import SafariServices

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginImageView: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var imageBackgroundView: UIView!
    
    var safariVC: SFSafariViewController?
    let numberOfOctocatImages = 10
    var octocatImages: [UIImage] = []
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpImageViewAnimation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(safariLogin(_:)), name: .closeSafariVC, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loginImageView.startAnimating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.loginImageView.stopAnimating()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        configureButton()

    }
    
    // MARK: Set Up View
    
    private func configureButton() {
        
        self.imageBackgroundView.layer.cornerRadius = 0.5 * self.imageBackgroundView.bounds.size.width
        self.imageBackgroundView.clipsToBounds = true
    }
    
    private func setUpImageViewAnimation() {
        
        for index in 1...numberOfOctocatImages {
            if let image = UIImage(named: "octocat-\(index)") {
                octocatImages.append(image)
            }
        }
        
        self.loginImageView.animationImages = octocatImages
        self.loginImageView.animationDuration = 2.0
        
    }
    
    // MARK: Action
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        
        presentSafariViewController()
    
    }
    
    // MARK: Transition
    
    private func presentSafariViewController() {
        
        self.safariVC = SFSafariViewController(url: GitHubRequestType.oauth.url)
        guard let safariVC = self.safariVC else {return}
        let navigationController = UINavigationController(rootViewController: safariVC)
        navigationController.setNavigationBarHidden(true, animated: false)
        present(navigationController, animated: true, completion: nil)
        
    }
    
    // MARK: Notification
    
    func safariLogin(_ notification: Notification) {
        
        guard let safariVC = self.safariVC else {return}
        safariVC.dismiss(animated: true) { 
            
            guard let url = notification.object as? URL else {
                print("ERROR: Unable to receive URL from notification")
                return
            }
            print(url)
            
//            GitHubAPIClient.request(.token(url: url), completionHandler: { (_, _, error) in
//                if error == nil {
//                    NotificationCenter.default.post(name: .closeLoginVC, object: nil)
//                } else {
//                    print("ERROR: token request failed")
//                }
//            })
   
        }
    }

}







