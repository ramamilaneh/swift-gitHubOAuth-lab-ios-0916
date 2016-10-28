//
//  Extensions.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/31/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let closeSafariVC = Notification.Name("close-safari-view-controller")
    static let closeLoginVC = Notification.Name("close-login-view-controller")
    static let closeReposTVC = Notification.Name("close-repo-table-view-controller")
}

extension URL {
    func getQueryItemValue(named name: String) -> String? {
        
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        return query?.filter({$0.name == name}).first?.value
        
    }
}
