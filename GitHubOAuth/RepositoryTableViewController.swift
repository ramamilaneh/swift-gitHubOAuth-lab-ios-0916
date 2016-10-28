//
//  ReposTableViewController.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/27/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit

class RepositoryTableViewController: UITableViewController {

    let store = RepositoryDataStore.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Repositories"
        
        store.getRepositories { error in
            
            if error == nil {
                self.tableView.reloadData()
            } else {
                print("ERROR: Unable to get repositories for table view")
            }
            
        }

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.repositories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! RepositoryTableViewCell

        cell.repository = store.repositories[indexPath.row]
        return cell
    }

    @IBAction func logoutButtonTapped(_ sender: AnyObject) {
        
        if GitHubAPIClient.deleteAccessToken() {
            NotificationCenter.default.post(name: .closeReposTVC, object: nil)
        } else {
            print("ERROR: Unable to delete access token")
        }

    }

}
