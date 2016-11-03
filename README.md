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
  * `Locksmith` is a protocol-oriented library for working the keychain (e.g., save user's access token).
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

Up until now you probably haven't used `NotificationCenter` but you're about to take a crash course. In the simplest terms, you can **post** a notification saying, "HEY! SOMETHING HAPPENED!" An **observer** of the notification will be notified somewhere else in the application (and would probably say to themselves, "Why are you yelling at me? 😥").

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
  * The URL should contain the `standard` base url and the `accessToken` path. The `buildParams(with:)` function will be used in the next step.

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
 * Declare a string constant called `code` where the value is the return of a `URL` extension in the `Extensions` file called `getQueryItemValue(named:)`. To get the code from the URL, pass in `"code"` as the `named:` argument, the function will find the query item for the key `"code"` using `URLComponents`. The function returns the code as an optional string.
 * Declare a constant called `parameters` where the value is the return of the `buildParams(with:)` function. The `code` constant you just created needs to be added to a dictionary of parameters. Remember that you updated the `buildParams(with:)` function in the previous step. Use this function to pass in the code string in order to build a completed parameters dictionary for the request.
 * Create a `URLRequest` called `request` and update the `.httpMethod` string property of the request using the type argument (Use the previous cases as a reference).
 * Use the `addValue(_:forHTTPHeaderField:)` function on `URLRequest` to add the two following values to the header:
  * `"application/json"` for header field, `"Accept"`.
    * Included to indicate to GitHub how the response should be formatted.
  * `"application/json"` for header field, `"Content-Type"`.
    * Included to indicate to GitHub how the parameters are formatted in the request.
 * Use the `.httpBody` data property of `URLRequest` to add your `parameters` dictionary.
  * The current format of `parameters` needs to be serialized using `JSONSerialization` before it's applied as the value to `.httpBody`. Use the class function on `JSONSerialization` called `data(withJSONObject:options:)` where the object is `parameters` and the options are an empty array.
 * After applying the serialized parameters to `.httpBody` return the `request`. `return nil` if the serialization fails.

### 8. Update `generateResponse(type:session:request:completionHandler:)`  to handle the `token` case of the `GitHubRequestType` enum
---

 * Add the `token` case to the switch statement. Call `processToken(response:)` to process the response. Use the other cases as a reference.

### 9. Update `processToken(response:)` to handle the received access token
---
 * Update the `processToken(response:)` method to get the "access_token" from the JSON dictionary (use the incoming `Data?` argument to implement the JSON serialization). Once you get the access token from the JSON dictionary, save it as a string using `saveAccess(token: String)`. The string is saved using the `Locksmith` pod. If all goes well, your `Response` return should be all `nil` values, otherwise bubble up an error in your response.
  * _**HINT:**_ If you're unsure of how to construct the method, use the other response processing methods as a reference.

### 10. Make the token request inside the `safariLogin(_:)` method of the `LoginViewController`   
---
Now that the `GitHubAPIClient` file has been updated to handle the request for an access token, it's time to turn your attention back to the `LoginViewController`. If you remember, the `LoginViewController` presents a `SFSafariViewController` to begin the authorization process with GitHub.  

When GitHub redirects to your application with a temporary code, `application(_:open:options:)` is called in the app delegate. This is where you posted a notification saying it's ok to close the safari view controller. The notification observer you added to the `LoginViewController` calls `safariLogin(_:)`. This is the method where you retrieved the URL from the notification `object` property.

As mentioned previously, the URL containing the temporary code now needs to be passed in as a part of the request to the `GitHubAPIClient` using the `token` case of the `GitHubRequestType` enum.

 * Call the `request(_:completionHandler:)` from `GitHubAPIClient` using the `token` request type. Pass the URL as the associated value.
 * If error is `nil`, add the following statement: `NotificationCenter.default.post(name: .closeLoginVC, object: nil)`.
  * _**NOTE:**_ The completion handler has three arguments. For the token request, you are only concerned with whether or not an error has occurred. If there has not been an error, a notification will be posted to an observer in the `AppController` to close the `LoginViewController` and present the `RepositoryTableViewController`.
 * Build and run the application. If everything is set up correctly, you should see the `RepositoryTableViewController` displaying a list of repositories.

## Advanced

 * Starring
  * Update the `starred(token:)` static function of the private `Query` enum inside `GitHubRequestType`. The incoming token argument needs to be added to the return string in order for the application to star/unstar the repositories listed in the `ReposTableViewController`. Build and run the application to see if a star icon appears in each row next to the repository name. A user should be able to tap a star icon to star/unstar repositories.

 * Logout
   * The `RepositoryTableViewController` has an IBAction for the log out button. This method needs to call `deleteAccessToken()` from `GitHubAPIClient` and use the optional `Error` return to determine whether to post a notification to the `AppController` to close the table view controller. `deleteAccessToken()` still needs to be defined. It should delete the token and return an error if one occurs.
