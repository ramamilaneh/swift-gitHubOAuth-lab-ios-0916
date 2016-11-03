//
//  ReposTableViewCell.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/28/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit

class RepositoryTableViewCell: UITableViewCell {
    
    var starButton: UIButton!
    var repository: Repository? {
        
        didSet {
            
            updateTextLabel(text: repository?.fullName)
            checkStarredStatus(repo: repository!)

        }
        
    }
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
        
    }
    
    private func commonInit() {
        
        self.selectionStyle = .none
        
        starButton = UIButton()
        starButton.isHidden = true
        starButton.alpha = 0
        starButton.addTarget(self, action: #selector(starButtonPressed(_:)), for: .touchUpInside)
        self.addSubview(starButton)
        
        starButton.translatesAutoresizingMaskIntoConstraints = false
        starButton.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5).isActive = true
        starButton.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5).isActive = true
        starButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        starButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
    }
    
    // MARK: Action
    
    func starButtonPressed(_ sender: UIButton) {
        
        toggleStarStatus()
        
    }
    
    // MARK: Label
    
    private func updateTextLabel(text: String?) {
        self.textLabel?.text = text
    }
    
    // MARK: Button
    
    private func setImagesForStarred(button: UIButton) {
        self.starButton.setImage(UIImage(named: "starred"), for: .normal)
        self.starButton.setImage(UIImage(named: "starredSelected"), for: .selected)
    }
    
    private func setImagesForUnstarred(button: UIButton) {
        self.starButton.setImage(UIImage(named: "unstarred"), for: .normal)
        self.starButton.setImage(UIImage(named: "unstarredSelected"), for: .selected)
    }
    
    private func setImagesForError(button: UIButton) {
        self.starButton.setImage(UIImage(named: "error"), for: .normal)
        self.starButton.setImage(UIImage(named: "error"), for: .selected)
    }
    
    // MARK: Networking (starring)
    
    private func toggleStarStatus() {
        
        guard let repo = self.repository else { return }
        
        GitHubAPIClient.request(.checkStar(repo: repo)) { (_, starred, error) in
            
            guard let isStarred = starred else { print(error?.localizedDescription); return }
            
            self.starButton.isHidden = false
            
            if isStarred {
                
                GitHubAPIClient.request(.unStar(repo: repo), completionHandler: { (_, _, error) in
                    
                    if error == nil {
                        
                        self.setImagesForUnstarred(button: self.starButton)
                        
                    } else {
                        
                        self.setImagesForError(button: self.starButton)
                        self.starButton.isSelected = false
                        print(error?.localizedDescription)
                        
                    }
                    
                })
                
            } else {
                
                GitHubAPIClient.request(.star(repo: repo), completionHandler: { (_, _, error) in
                    
                    if error == nil {
                        
                        self.setImagesForStarred(button: self.starButton)
                        
                    } else {
                        
                        self.setImagesForError(button: self.starButton)
                        self.starButton.isSelected = false
                        print(error?.localizedDescription)
                        
                    }
                    
                })
                
            }
            
            self.starButton.isSelected = false
            self.starButton.isUserInteractionEnabled = true
            
        }
        
    }
    
    private func checkStarredStatus(repo: Repository) {
        
        GitHubAPIClient.request(.checkStar(repo: repo)) { (_, starred, error) in
            
            guard let isStarred = starred else { print(error?.localizedDescription); return }
            
            self.starButton.isHidden = false
            
            if isStarred {
                
                self.setImagesForStarred(button: self.starButton)
                UIView.animate(withDuration: 0.5, animations: { 
                    self.starButton.alpha = 1
                })
                
            } else {
                
                self.setImagesForUnstarred(button: self.starButton)
                UIView.animate(withDuration: 0.5, animations: {
                    self.starButton.alpha = 1
                })
                
            }
            
        }
        
    }
    
}

