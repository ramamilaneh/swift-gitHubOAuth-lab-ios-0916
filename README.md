# GitHub OAuth

## Objectives

 * Set up your application to use the OAuth2 protocol to access a user's GitHub account

## Introduction

[GitHub's developer site](https://developer.github.com/v3/oauth/) provides a very succinct description of OAuth and why to use it.

>OAuth2 is a protocol that lets external applications request authorization to private details in a user's GitHub account without getting their password. This is preferred over Basic Authentication because tokens can be limited to specific types of data, and can be revoked by users at any time.

**IMPORTANT:** Use [GitHub's OAuth API documentation](https://developer.github.com/v3/oauth/) throughout this lab to understand the details of constructing and handling the requests and responses necessary for completing the process. Implementing the protocol requires joint effort from the application (client), the user (resource owner), and the website (resource server). Here is a brief summary of steps to use GitHub OAuth:

 1. Register your application with GitHub to receive a **Client ID** and a **Client Secret**.
 2. Set up an **Authorization callback URL** on GitHub.
 3. Set up a **URL Scheme** in Xcode for your application.
 4. Direct user at login to GitHub for authorization.  
 5. Handle callback from GitHub containing a temporary **code**.
 6. Use **code** to authenticate user and receive **access token**.
 7. Save the **access token** in your application.
 8. Use the **access token** to make requests for user account information.

So why use OAuth in your application? Since your application will use resources from your user's GitHub account, following the OAuth protocol grants you access to those resources. Additionally, the user will not have to be authenticated by GitHub **AND** your application. This saves your poor user from the agony of remembering another username and password.

This project is similar to the previous GitHub related labs, however it has been updated and organized a bit differently. Here's a run down of what's right out of the box:

 * Model
  * `Repository` class is used to create repo objects.
  * `RepositoryDataStore` class stores `Repository` objects.
 * View
  * `RepositoryTableViewCell` class is the reusable cell for the `RepositoryTableViewController`. This class also handles starring requests.
 * Controllers
  * `AppController` class handles which view controller is displayed.
  * `LoginViewController` class directs the user for authorization and authentication.
  * `RepositoryTableViewController` class displays repositories and facilitates starring a repository.  
 * Networking
  * `GitHubAPIClient` class interacts with the GitHub API.
 * Utility
  * `Constants` contains a struct of static storyboard IDs.
  * `Extensions` contains a `NSURL` extension for parsing query items and a `Notification.Name` extension of static notification names.
  * `Secrets` (you will need to add this file).
 * Pods
  * `Locksmith` is a protocol-oriented library for working the keychain.
 * Etc.

For now, you can run the application to see some animated octocats. They are cheering for you so let's get started!

### 1. Set up your callback URL
---
 * Head on over to [GitHub](https://github.com). Reference this [screenshot](https://s3.amazonaws.com/learn-verified/github-oauth-registration.jpg) to help you along the way.
 * If you don't have a **Client ID** and a **Client Secret** set up from previous labs, go to Settings > OAuth Applications > Developer Applications > Register and start registering your new application.
 * Whether you are registering a new application or have your application selected, find the header at the bottom of the form titled **Authoriation callback URL**.
 * Enter some text following this format: `gitHubOAuthLab-12345://callback`. The first section before the colon, `gitHubOAuthLab-12345`, can be whatever you want (e.g., "gitHubOAuthSuperDuperLab"). It's intended to be unique to your application.
 * Head on over to your project in Xcode and select your project in the the Project Navigator. Reference this [screenshot](https://s3.amazonaws.com/learn-verified/github-xcode-url-types.jpg) to help you along the way.
 * In the editor, select your project target, then select **Info** and look at the bottom of the list for **URL Types**.
 * Expand the **URL Types** section and click on the plus sign.
 * Enter your URL Scheme using the unique name you created above (e.g., `gitHubOAuthLab-12345`) and press enter. This will update your `Info.plist` file with your new URL scheme.

### 2. Add your Secrets file
---
 * Create your Secrets file and add your **Client ID** and **Client Secret**

 ```swift
 struct Secrets {
    static let clientID = ""
    static let clientSecret = ""
 }
 ```

### 3. Update the `GitHubRequestType` enum to include an oauth request
---

The organization of the `GitHubAPIClient` file is different from previous GitHub related labs. The `GitHubRequestType` enum has variables that provide the URL and HTTP Method for each type of request. The nested enums inside `GitHubRequestType` and the `buildParams(with:)` function are used to construct the different URL components of each type of request.

 * Begin by adding the `oauth` case to the `GitHubRequestType` enum.
  * The `oauth` case is used to redirect users to request GitHub access.
 * Add a static constant to `BaseURL` called `standard` with a value of `"https://github.com"`.
 * Add a static constant to `Path` called `oauth` with a value of `"/login/oauth/authorize"`.
 * Add a static constant to `Query` called `oauth`. Refer to the other queries already listed to understand how they are constructed. The string query should be constructed with the following parameters:
  * `"client_id"`: `Secrets.clientID`
  * `"scope"`: `"repo"`
 * Add the `oauth` case to the `method` computed variable and `return nil`.
 * Add the `oauth` case to the `url` computed variable and return the complete URL.

### 4. Use SFSafariViewController to request authorization
---

 * Locate the `loginButtonTapped(_:)` IBAction method in the `LoginViewController` class.
 * Inside the method, pass the value from `GitHubRequestType.oauth.url` to to initialize a `SFSafariViewController`.
  * _**Note:**_ The safari view controller streamlines the process of directing a user to GitHub by providing easy access to a stripped down version of the Safari web browser inside your application.
  * _**Hint:**_ Import the Safari Services framework to use `SFSafariViewController`. Also, you will need to reference the safari view controller from a couple of methods within the `LoginViewController` class.
 * Present the controller.
 * Run the application to see if your safari view controller is presented when the login button is tapped. It should direct the user to the GitHub site to enter login information (Don't bother entering your GitHub credentials yet).
 * Stop the application.

### 5. Handle the callback from GitHub
---
In the previous step the user is directed to GitHub using a safari view controller to provide authorization. Once the user successfully completes authorization, the callback you provided in your GitHub account is used to trigger the URL Scheme you provided in your project settings. Additionally, the safari view controller calls a `UIApplicatioDelegate` method called `application(_:open:options:)` that passes a URL containing a temporary code received from the GitHub callback.

 * Add the `application(_:open:options:)` method to your `AppDelegate` file.
 * Get the value for the key `UIApplicationOpenURLOptionsKey.sourceApplication` from the options dictionary argument.
 * If the value equals `"com.apple.SafariViewService"`, return `true`.
  * _**Hint:**_ The value from the options dictionary is of type `Any` and needs to be a `String` in order to make the comparison.

Up until now you probably haven't used `NotificationCenter` but you're about to take a crash course. In the simplest terms, you can **post** a notification saying, "HEY! SOMETHING HAPPENED!". An **observer** of the notification will be notified somewhere else in the application (and would probably say to themselves, "Why are you yelling at me? 😥").

Here are the two notification statements you will use in your application:

 ```swift
 // Post notification
 NotificationCenter.default.post(name:object:)

 // Add observer
 NotificationCenter.default.addObserver(_:selector:name:object:)
 ```
Now that you are a notification's expert, let's continue.

 * In the previous step you verified the value, `"com.apple.SafariViewService"` and returned `true`. Add a post notification immediately before you `return true`. Use the `Notification.Name` extension from your `Extensions` file to provide the name `.closeSafariVC`. Pass the value from the incoming `url` argument to the `object` parameter of the notification. This notification is posting a message to anyone listening that it's ok to close the `SFSafariViewController` you presented inside the `LoginViewController`. The notification also includes the `url` argument passed as an object.
  * _**Note:**_ As mentioned above, the incoming `url` argument of the `application(_:open:options:)` method contains a temporary code that we need to proceed with the GitHub authentication process.
 * Head back to the `LoginViewController` class and add a method called `safariLogin(_:)` that takes one argument called `notification` of type `Notification` and returns nothing.
 * Add a notification observer inside `viewDidLoad()` of the `LoginViewController` class.
  * The observer is the `LoginViewController`.
  * The selector is the method you just created above, `safariLogin(_:)`.
  * The name is the name you used for the post notification in the app delegate, `.closeSafariVC`.
  * The object is `nil`.
 * Inside `safariLogin(_:)` access the `.object` property of the `notification` argument to get the `URL` passed from the app delegate.
  * _**Hint:**_ The `.object` property is `Any?`. How can you turn that into a `URL`.
 * Print the `URL` to the console.
 * Dismiss the safari view controller.
 * Run the application, provide your credentials to GitHub in the safari view controller, and authorize the application.
  * The URL containing the temporary code should print to the debugger and the safari view controller should be dismissed.

### 6. Update the `GitHubRequestType` enum to include an access token request
---
Now that you have received a URL containing a temporary code from GitHub, you can make a request to receive an access token. Head back to the `GitHubAPIClient` file to update the `GitHubRequestType` enum.

 * Begin by adding the `token` case to the `GitHubRequestType` enum.
  * The `token` case is used to request an access token.
 * Update the `token` case to accept a `URL` argument named `url` as an associated value.
 * The token request should use the `standard` static constant from the `BaseURL` enum.
 * Add a static constant to `Path` called `accessToken` with a value of `"/login/oauth/access_token"`.
 * Instead of adding parameters to the `Query` enum, you are going to update the `buildParams(with code: String)` function that returns a dictionary of parameters. When requesting the access token, you will need to provide your `"client_id"`, `"client_secret"`, and the temporary `"code"` you received back from GitHub as parameters. The `code` argument in the function is the temporary code that needs to be included.
  * Complete the function by returning the dictionary of parameters. The function should only return the dictionary for the `token` case. Otherwise, it should return `nil`.
 * Add the `token` case to the `method` computed variable and `return "POST"`.
 * Add the `token` case to the `url` computed variable and return the complete URL.
  * The URL should contain the `standard` base url and the `accessToken` path. The `buildParams(with:)` function will be used elsewhere.

### 7. Update `generateURLRequest(_:)` to handle the `token` case of the `GitHubRequestType` enum
---
Before you move forward, take a moment to look through `GitHubAPIClient`. Take note of each section and how the methods are organized.
 * `// MARK: Response Typealias`
  * Type aliases are handy for giving alias names to existing types. In this lab it's used as a means to organize the response from all GitHub requests.  
 * `// MARK: Request`
  * Routes all GitHub related requests through one method using the `GitHubRequestType`.
 * `// MARK: Request Generation`
  * Returns a `URLRequest` based on the type of the request.
 * `// MARK: Session Generation`
  * Returns a default `URLSession`.
 * `// MARK: Response Generation`
  * Executes a data task using the request type, session, and request. Contains a completion handler call back to pass three different values (See the type aliases mentioned above).
 * `// MARK: Response Processing`
  * Separate methods for handling each type of request.
 * `// MARK: Token Handling`
  * Separate methods and a variable for handling the access token received from GitHub.
 * `// MARK: Error Handling`
  * An error enum to use for various errors that could occur during the request process or the response handling.

With all of that in mind, start by updating `generateURLRequest(_:)`.

 * Add the `token` case.
  * Remember this case has an associated `URL` value. When the `token` case of the `GitHubRequestType` is used, the URL containing the temporary code is passed in. You should use the associated value to extract the temporary code from the URL that's passed in. You can capture the associated value in the case declaration like this: `case .token(url: let url)`.
 * Declare a string constant called `code` where the value is the return of a `URL` extension in the `Extensions` file called `getQueryItemValue(named:)`. temporary code from the URL (`token` case associated value). To get the code, use the `URL` extension in the `Extensions` file, `getQueryItemValue(named:)` a utility function so that when you pass in `"code"` as the `named:` argument, the function will find the query item for the key `"code"` using `URLComponents`. The function returns the code as an optional string.
 * Declare a constant called `parameters` where the value is the return of the `buildParams(with:)` function. The extracted code variable you just created needs to be added to a dictionary of parameters. Remember that you updated the `buildParams(with:)` function in the previous step. The next step is to call this function and pass in the code string in order to build a completed parameters dictionary for the request.
 * Declare a


At the end of the last lab you received a temporary code back from GitHub. You are going to use that code to make a request to GitHub for the access token.
 * Inside the `safariLogin(_:)` method of the `LoginViewController`, call the `startAccessTokenRequest(url:completionHandler:)` method from the `GitHubAPIClient`.
 * Pass the URL received back from GitHub to the url parameter of the `startAccessTokenRequest(url:completionHandler:)` method.
  * *Hint:* Remember the notification argument passed in from `safariLogin(_:)` has the url stored in the object property.
 * Head over to the `GitHubAPIClient` class to define the `startAccessTokenRequest(url:completionHandler:)` method.
  * Use this order of tasks to define the method:
    * Use the `NSURL` extension from the `Extensions` file to extract the code.
    * Build your parameter dictionary for the request.
      * "client_id": *your client id*
      * "client_secret": *your client secret*
      * "code": *temporary code from GitHub*
    * Build your headers dictionary to receive JSON data back.
      * "Accept": "application/json"
    * Use `request(_:_:parameters:encoding:headers:)` from [Alamofire](http://cocoadocs.org/docsets/Alamofire/3.4.1/Functions.html#/s:F9Alamofire7requestFTOS_6MethodPS_20URLStringConvertible_10parametersGSqGVs10DictionarySSPs9AnyObject___8encodingOS_17ParameterEncoding7headersGSqGS2_SSSS___CS_7Request) to make a POST request using the `.token` string from the `URLRouter`, the parameter dictionary, and the header dictionary.
    * If the request is successful, print response and call `completionHandler(true)`, else `completionHandler(false)`.
 * Run the application to see if you are getting a successful response.

### 8. Save the access token to the keychain
---
 * Use `SwiftyJSON` to get the access token from the response you were working with in the previous step.
 * Call `saveAccess(token:completionHandler:)` to pass the access token you retrieved from the JSON data.
 * Define the `saveAccess(token:completionHandler:)` method using the [Locksmith](http://cocoadocs.org/docsets/Locksmith/2.0.8/) pod. Use the method, `try Locksmith.saveData(["some key": "some value"], forUserAccount: "myUserAccount")`.
   * Key is "access token". Value is "*token from response*". User account is "github".
   * The `completionHandler` should callback with true or false depending on whether the access token is saved successfully.
 * Back inside the response section of the `startAccessTokenRequest(url:completionHandler:)` method, update the order of tasks to be:
   * Receive response.
   * Serialize JSON data using SwiftyJSON.
   * Call `saveAccess(token:completionHandler:)` method
   * If save succeeded, call the completion handler of `startAccessTokenRequest(url:completionHandler:)` with the appropriate response.
   * Run the application using print statements accordingly to see that everything is working correctly.

### 9. Define the `getAccessToken()` method
---
 * Use the Locksmith method, `Locksmith.loadDataForUserAccount()` to retrieve the access token and return it.
 * Update the `starred(repoName:)` static function defined in the `URLRouter` enum.
   * `starredURL` needs to be combined with the access token for user account requests.
 * Update the `hasToken()` method to check if there is a token saved.
   * Use `getAccessToken()` to determine whether the method should return `true` or `false`.
 * Reset the simulator and run the application. At this point you should be able to log in again. Stop the application. Run it again and you should be directed to the table view controller containing a list of repositories.

## Advanced
Resetting the simulator and rerunning the application will indicate if everything is working correctly but it's not ideal. There are a few more pieces to this puzzle that can make it complete. Here's what's left:

 * Login
    * The `LoginViewController` starts the login process **BUT** the `AppController` doesn't know about the outcome of the process. That means it doesn't know whether it should display the table view controller or not. `startAccessTokenRequest(url:completionHandler:)` is called inside the `LoginViewController` with a callback about whether the process succeeded. If it succeeds, post a notification using the appropriate `Notification` name. The `AppController` already has the observer set up.

 * Logout
   * The `ReposTableViewController` has an IBAction for the log out button. This method needs to call `deleteAccessToken(_:)` from `GitHubAPIClient` and use the completion handler to determine whether to post a notification to the `AppController` to close the table view controller. `deleteAccessToken` still needs to be defined. It should delete the token and call back with the outcome.
