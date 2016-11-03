//
//  GitHubAPIClient.swift
//  GitHubOAuth
//
//  Created by Joel Bell on 7/31/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation
import Locksmith

// MARK: Request Type

enum GitHubRequestType {
    
    case checkStar(repo: Repository)
    case repositories
    case star(repo: Repository)
    case unStar(repo: Repository)
    case oauth
    case token(url: URL)
    
    private enum BaseURL {
        
        static let api = "https://api.github.com"
        static let standard = "https://github.com"
        
    }
    
    private enum Path {
        
        static let repositories = "/repositories"
        static func starred(repo: Repository) -> String { return "/user/starred/\(repo.fullName)" }
        static let oauth = "/login/oauth/authorize"
        static let accessToken = "/login/oauth/access_token"
        
    }
    
    private enum Query {
        
        static let repositories = "?client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)"
        static func starred(token: String) -> String {
            return "?client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)&access_token=\(token)"
        }
        static let oauth = "?client_id=\(Secrets.clientID)&scope=repo"
    }
    
    fileprivate func buildParams(with code: String) -> [String: String]? {
        let parameters = ["client_id": Secrets.clientID,
                          "client_secret": Secrets.clientSecret,
                          "code": code]
        switch self {
        case .token:
            return parameters
        default:
            return nil
        }
        
        
    }
    
    var method: String? {
        
        switch self {
        case .checkStar, .repositories:
            return "GET"
        case .star:
            return "PUT"
        case .unStar:
            return "DELETE"
        case .oauth:
            return nil
        case .token:
            return "POST"
        }
        
    }
    
    var url: URL {
        
        switch self {
        case .checkStar(repo: let repo), .star(repo: let repo), .unStar(repo: let repo):
            return URL(string: BaseURL.api + Path.starred(repo: repo) + Query.starred(token: GitHubAPIClient.accessToken))!
        case .repositories:
            return URL(string: BaseURL.api + Path.repositories + Query.repositories)!
        case .oauth:
            return URL(string: BaseURL.standard + Path.oauth + Query.oauth)!
        case .token:
            return URL(string: BaseURL.standard + Path.accessToken)!
        }
        
    }
    
}

// MARK: Response Typealias

typealias JSON = [String: Any]
typealias Starred = Bool
typealias Response = ([JSON]?, Starred?, Error?)
typealias GitHubResponse =  ([JSON]?, Starred?, Error?) -> ()


// MARK: GitHub API Client

struct GitHubAPIClient {
    
    // MARK: Request
    
    static func request(_ type: GitHubRequestType, completionHandler: @escaping GitHubResponse) {
        
        guard let request = generateURLRequest(type) else { completionHandler(nil, nil, GitHubError.request); return }
        let session = generateURLSession()
        
        generateResponse(type: type, session: session, request: request) { (json, starred, error) in
            
            OperationQueue.main.addOperation {
                
                completionHandler(json, starred, error)
                
            }
            
        }
        
    }
    
    // MARK: Request Generation
    
    private static func generateURLRequest(_ type: GitHubRequestType) -> URLRequest? {
        
        switch type {
            
        case .repositories, .checkStar, .star, .unStar:
            
            var request = URLRequest(url: type.url)
            request.httpMethod = type.method!
            return request
        case .token(url: let url):
            let code = url.getQueryItemValue(named: "code")
            let parameters = type.buildParams(with: code!)
            var request = URLRequest(url: type.url)
            request.httpMethod = type.method!
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters!, options: [])
                return request
            }catch{
                return nil
            }
        default:
            return nil
        }
        
    }
    
    // MARK: Session Generation
    
    private static func generateURLSession() -> URLSession {
        return URLSession(configuration: .default)
    }
    
    // MARK: Response Generation
    
    static func generateResponse(type: GitHubRequestType, session: URLSession, request: URLRequest, completionHandler: @escaping GitHubResponse) {
        
        session.dataTask(with: request) { (response) in
            
            var (json, starred, error): Response
            
            switch type {
            case .checkStar:
                (json, starred, error) = processStarCheck(response: response)
            case .repositories:
                (json, starred, error) = processRepositories(response: response)
            case .star, .unStar:
                (json, starred, error) = processStarred(response: response)
            case .token:
               (json, starred, error) =  processToken(response: response)
            default:
                (json, starred, error) = (nil, nil, GitHubError.response)
                
            }
            completionHandler(json, starred, error)
            
            }.resume()
        
    }
    
    // MARK: Response Processing
    
    private static func processRepositories(response: (Data?, URLResponse?, Error?)) -> Response {
        
        let (data, _, error) = response
        if error != nil { return (nil, nil, error) }
        guard let repoData = data else { return (nil, nil, GitHubError.data) }
        
        do {
            let JSON = try JSONSerialization.jsonObject(with: repoData, options: []) as? [JSON]
            return (JSON, nil, nil)
        } catch let error {
            return (nil, nil, error)
        }
        
    }
    
    private static func processStarCheck(response: (Data?, URLResponse?, Error?)) -> Response {
        
        let (_, urlResponse, error) = response
        if error != nil { return (nil, nil, error) }
        let httpResponse = urlResponse as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 404:
            return (nil, false, nil)
        case 204:
            return (nil, true, nil)
        default:
            return (nil, nil, GitHubError.statusCode)
        }
        
    }
    
    private static func processStarred(response: (Data?, URLResponse?, Error?)) -> Response {
        
        let (_, urlResponse, error) = response
        if error != nil { return (nil, nil, error) }
        let httpResponse = urlResponse as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 204:
            return (nil, nil, nil)
        default:
            return (nil, nil, GitHubError.statusCode)
        }
        
    }
    
    private static func processToken(response: (Data?, URLResponse?, Error?)) -> Response {
        let (data, _, error) = response
        if error != nil { return (nil, nil, error) }
        if let unwrappedData = data {
            
            print("1. \(unwrappedData)")
            do{
              let response = try JSONSerialization.jsonObject(with: unwrappedData, options: []) as! [String:Any]
                let accessToken = response["access_token"] as! String
                return (nil, nil, saveAccess(token: accessToken))
                
            }catch{
                
            }
        }
        return (nil, nil, nil)
        
    }
    
    // MARK: Token Handling
    
    fileprivate static var accessToken: String {
        
        if let data = Locksmith.loadDataForUserAccount(userAccount: "github") {
            return data["token"] as! String
        }
        return ""
        
    }
    
    static func hasToken() -> Bool {
        
        return self.accessToken.isEmpty ? false : true
        
    }
    
    private static func saveAccess(token: String) -> Error? {
        
        do {
            try Locksmith.saveData(data: ["token": token], forUserAccount: "github")
            return nil
        } catch let error {
            return error
        }
        
    }
    
    static func deleteAccessToken() -> Error?  {
        
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: "github")
            return nil
        } catch let error {
            return error
        }
        
    }
    
    // MARK: Error Handling
    
    enum GitHubError: Error {
        
        case data
        case request
        case response
        case statusCode
        case token
        
        var localizedDescription: String {
            
            switch self {
            case .data: return "ERROR: Data value is nil"
            case .request: return "ERROR: Unable to build url request"
            case .response: return "ERROR: Unable to process response"
            case .statusCode: return "ERROR: Incorrect status code"
            case .token: return "ERROR: Unable to retrieve token from JSON"
            }
            
        }
        
    }
    
}
