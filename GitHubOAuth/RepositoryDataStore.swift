//
//  ReposDataStore.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/31/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import UIKit

class RepositoryDataStore {
    
    static let sharedInstance = RepositoryDataStore()
    private init() {}
    
    var repositories: [Repository] = []
    
    func getRepositories(completionHandler: @escaping (Error?) -> ()) {
        
        GitHubAPIClient.request(.repositories) { (JSON, _, error) in
            guard let json = JSON else { completionHandler(error);return }
            json.forEach {
                if let repository = Repository(json: $0) {
                    self.repositories.append(repository)
                }
            }
            completionHandler(nil)
        }
    
    }

}
