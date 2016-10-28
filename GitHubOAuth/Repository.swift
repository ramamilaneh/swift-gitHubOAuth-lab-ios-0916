//
//  GitHubRepo.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/27/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation

struct Repository {
    
    var id: String
    var name: String
    var fullName: String
    var htmlURL: String
    
    init?(json: [String: Any]) {
        guard
            let id = json["id"] as? Int,
            let name = json["name"] as? String,
            let fullName = json["full_name"] as? String,
            let htmlURL = json["html_url"] as? String
            else { return nil }
        
        self.id = String(id)
        self.name = name
        self.fullName = fullName
        self.htmlURL = htmlURL
    }
    
}
