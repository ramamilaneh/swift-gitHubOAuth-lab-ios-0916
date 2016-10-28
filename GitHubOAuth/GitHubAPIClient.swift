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

    case oauth
    case repositories
    case star(repo: Repository)
    case unStar(repo: Repository)
    case checkStar(repo: Repository)
    case token(url: URL)
    
    
    private enum BaseURL {
        
        static let api = "https://api.github.com"
        static let standard = "https://github.com"
        
    }
    
    private enum Path {
        
        static let repositories = "/repositories"
        static let accessToken = "/login/oauth/access_token"
        static let oauth = "/login/oauth/authorize"
        static func starred(repo: Repository) -> String { return "/user/starred/\(repo.fullName)" }
        
    }
    
    private enum Query {
        
        static let oauth = "?client_id=\(Secrets.clientID)&scope=repo"
        static let repositories = "?client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)"
        static func starred(token: String) -> String {
            let query = "?client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)&access_token="
            return query + token
        }
    }
    
    fileprivate func buildParams(with code: String) -> [String: String]? {
        
        switch self {
        case .token:
            return ["client_id": Secrets.clientID, "client_secret": Secrets.clientSecret, "code": code]
        default:
            return nil
        }
    
    }
    
    var url: URL? {
        
        switch self {
        case .oauth:
            return URL(string: BaseURL.standard + Path.oauth + Query.oauth)
        case .repositories:
            return URL(string: BaseURL.api + Path.repositories + Query.repositories)
        case .star(repo: let repo), .unStar(repo: let repo), .checkStar(repo: let repo):
            guard let token = GitHubAPIClient.accessToken else {return nil}
            return URL(string: BaseURL.api + Path.starred(repo: repo) + Query.starred(token: token))
        case .token:
            return URL(string: BaseURL.standard + Path.accessToken)
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
        case .token:
            return "POST"
        case .oauth:
            return nil
        }
    
    }

}

// MARK: Response Typealias

typealias JSON = [String: Any]
typealias Starred = Bool
typealias Response = ([JSON]?, Starred?, Error?) -> ()


// MARK: GitHub API Client

struct GitHubAPIClient {
    
    fileprivate static var accessToken: String? {
        
        if let data = Locksmith.loadDataForUserAccount(userAccount: "github") {
            return data["token"] as? String
        }
        return nil
        
    }
    
    // MARK: Request
    
    static func request(_ type: GitHubRequestType, completionHandler: @escaping Response) {
        
        let (request, error) = generateURLRequest(type: type)
        let session = generateURLSession()
        
        guard let urlRequest = request else {completionHandler(nil, nil, error);return}
        
        generateResponse(type: type, session: session, request: urlRequest) { (JSON, starred, error) in
            
            OperationQueue.main.addOperation {
                completionHandler(JSON, starred, error)
            }
    
        }
        
    }
    
    // MARK: Request Generation
    
    private static func generateURLRequest(type: GitHubRequestType) -> (URLRequest?, Error?) {
        
        guard let url = type.url else { return(nil, RequestError.url) }
        
        switch type {
            
        case .repositories, .checkStar, .star, .unStar:
            
            var request = URLRequest(url: url)
            request.httpMethod = type.method!
            return (request, nil)
        
        case .token(url: let redirectURL):
            
            guard let code = redirectURL.getQueryItemValue(named: "code") else { return (nil, RequestError.code) }
            guard let parameters = type.buildParams(with: code) else { return (nil, RequestError.parameters) }

            var request = URLRequest(url: url)
            request.httpMethod = type.method!
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch let error {
                return (nil, error)
            }
            return (request, nil)
            
        default:
            return(nil, nil)
        }
        
    }
    
    // MARK: Session Generation
        
    private static func generateURLSession() -> URLSession {
        return URLSession(configuration: .default)
    }
    
    // MARK: Reponse Generation
        
    static func generateResponse(type: GitHubRequestType, session: URLSession, request: URLRequest, completionHandler: @escaping Response) {
        
        session.dataTask(with: request) { (response) in
            
            switch type {
            case .repositories:
                let (JSON, error) = processRepositories(response: response)
                completionHandler(JSON, nil, error)
            case .token:
                let error = processToken(response: response)
                completionHandler(nil, nil, error)
            case .checkStar:
                let (isStarred, error) = processStarCheck(response: response)
                completionHandler(nil, isStarred, error)
            case .star, .unStar:
                let error = processStarred(response: response)
                completionHandler(nil, nil, error)
            default:
                completionHandler(nil, nil, nil)
            }
            
        }.resume()

    }
    
    // MARK: Response Processing
    
    private static func processRepositories(response: (Data?, URLResponse?, Error?)) -> ([JSON]?, Error?) {
        
        let (data, _, error) = response
        if error != nil { return (nil, error) }
        guard let repoData = data else { return (nil, ResponseError.data) }
        
        do {
            let JSON = try JSONSerialization.jsonObject(with: repoData, options: []) as? [[String: Any]]
            return (JSON, nil)
        } catch let error {
            return (nil, error)
        }
        
    }
    
    private static func processToken(response: (Data?, URLResponse?, Error?)) -> Error? {
        
        let (data, _, error) = response
        if error != nil { return error }
        guard let tokenData = data else { return (ResponseError.data) }
        
        do {
            let json = try JSONSerialization.jsonObject(with: tokenData, options: []) as? [String: Any]
            guard let accessToken = json?["access_token"] as? String else { return ResponseError.token }
            saveAccess(token: accessToken)
            return nil
    
        } catch let error {
            return error
        }
        
    }
    
    private static func processStarCheck(response: (Data?, URLResponse?, Error?)) -> (Bool?, Error?) {
        
        let (_, urlResponse, error) = response
        if error != nil { return (nil, error) }
        let httpResponse = urlResponse as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 404:
            return (false, nil)
        case 204:
            return (true, nil)
        default:
            return (nil, nil)
        }
    
    }
    
    private static func processStarred(response: (Data?, URLResponse?, Error?)) -> Error? {
        
        let (_, urlResponse, error) = response
        if error != nil { return error }
        let httpResponse = urlResponse as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 204:
            return nil
        default:
            return nil
        }
    
    }

    // MARK: Token Handling 
    
    static func hasToken() -> Bool {
        
        let token = getAccessToken()
        if token != nil {
            return true
        }
        return false
        
    }

    private static func saveAccess(token: String) {
        
        do {
            try Locksmith.saveData(data: ["token": token], forUserAccount: "github")
        } catch let error {
            print(error.localizedDescription)
        }

    }

    private static func getAccessToken() -> String? {
        
        if let data = Locksmith.loadDataForUserAccount(userAccount: "github") {
            return data["token"] as? String
        }
        return nil
        
    }
    
    static func deleteAccessToken() -> Bool  {
        
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: "github")
            return true
        } catch let error {
            print(error.localizedDescription)
            return false
        }
        
    }
    
}

extension GitHubAPIClient {
    
    // MARK: Error Handling
    
    enum RequestError: Error {
        
        case url
        case code
        case parameters
        case request
        
        var description: String {
            
            switch self {
            case .url: return "ERROR: Unable to create URL"
            case .code: return "ERROR: Unable to parse temporary code from GitHub redirect URL"
            case .parameters: return "ERROR: Unable to build parameters dictionary"
            case .request: return "ERROR: Unable to build url request"
            }
        }
    }
    
    enum ResponseError: Error {
        
        case data
        case token
        case saveToken
        
        var description: String {
            
            switch self {
            case .data: return "ERROR: Data value is nil"
            case .token: return "ERROR: Unable to retrieve token from JSON"
            case .saveToken: return "ERROR: Unable to save token"
            }
        }
        
    }
    
}
