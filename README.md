# GitHub OAuth - Part I

## Objectives

 * Set up your application to use the OAuth2 protocol to access a user's GitHub account

## Introduction

[GitHub's developer site](https://developer.github.com/v3/oauth/) provides a very succinct description of OAuth and why to use it.

>OAuth2 is a protocol that lets external applications request authorization to private details in a user's GitHub account without getting their password. This is preferred over Basic Authentication because tokens can be limited to specific types of data, and can be revoked by users at any time.

The process of implementing the protocol requires joint effort from the application (client), the user (resource owner), and the website (resource server). Here is a brief summary of steps to use GitHub OAuth:

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
  * `RepositoryTableViewCell` class is the reusable cell for the `RepositoryTableViewController`.
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
 * Enter some text following this format: `gitHubOAuthLab-12345://callback`. The first section, `gitHubOAuthLab-12345`, can be whatever you want. It's intended to be unique to your application.
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

### 3. Set up your OAuth URLs
---
 There are a few URL strings you will need for OAuth related requests. The `GitHubAPIClient` has a handy enum called `URLRouter` that keeps them organized in one place. An example usage is `let urlString = GitHubAPIClient.URLRouter.oauth`.

  * Replace the existing code inside the body of the `URLRouter` enum with the following code snippet. Check out [GitHub](https://developer.github.com/v3/oauth/) to learn about how `.oath` was constructed and what `.token` is for. You will update the static `starred(repoName:)` later to include your user's access token.

  ```swift
  static let repo = "https://api.github.com/repositories?client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)"
  static let token = "https://github.com/login/oauth/access_token"
  static let oauth = "https://github.com/login/oauth/authorize?client_id=\(Secrets.clientID)&scope=repo"

  static func starred(repoName repo: String) -> String? {

      let starredURL = "https://api.github.com/user/starred/\(repo)?client_id=\(Secrets.clientID)&client_secret=\(Secrets.clientSecret)&access_token="

      // TO DO: Add access token to starredURL string and return
    return nil
  }
  ```

### 4. Use SFSafariViewController to request authorization
---

 * Locate the `loginButtonTapped(_:)` IBAction method in the `LoginViewController` class.
 * Inside the method, use `GitHubAPIClient.URLRouter.oath` to create an `NSURL` and initialize a `SFSafariViewController` using the url.
  * *Note:* The safari view controller streamlines the process of directing a user to GitHub by providing easy access to a stripped down version of the Safari web browser.
  * **Hint:** Import the Safari Services framework to use `SFSafariViewController`. Also, you will need a reference to the safari view controller from a couple of methods within the `LoginViewController` class.
 * Present the controller.
 * Run the application to see if your safari view controller is presented when the login button is tapped (Don't bother entering your GitHub credentials yet).
 * Stop the application.

### 5. Handle the callback from GitHub
---
In the previous step the user is directed to GitHub using a safari view controller to provide authorization. Once the user successfully completes authorization, the callback you provided in your GitHub account is used to trigger the URL Scheme you provided in your project settings. Additionally, the safari view controller calls a `UIApplicatioDelegate` method called `application(_:open:options:)` that passes a URL containing a temporary code received from the GitHub callback.

 * Add the `application(_:open:options:)` method to your `AppDelegate` file.
 * Get the value for the key `"UIApplicationOpenURLOptionsSourceApplicationKey"` from the options dictionary.
 * If the value equals `"com.apple.SafariViewService"`, return `true`.

Up until now you probably haven't used `NSNotificationCenter` but you're about to take a crash course. In the simplest terms, you can post a notification saying, "HEY! SOMETHING HAPPENED!". An observer of the notification will be notified somewhere else in the application (and would probably say to themselves, "Why are you yelling at me? 😥").

Here are the two notification statements you will use in your application:

 ```swift
 // Post notification
 NSNotificationCenter.defaultCenter().postNotificationName(_:object:)

 // Add observer
 NSNotificationCenter.defaultCenter().addObserver(_:selector:name:object:)
 ```
Now that you are a notification's expert, let's continue.

 * In the previous step you verified the value, `"com.apple.SafariViewService"` and returned `true`. Add a post notification immediately before the return. Use your `Notifications` struct from your `Constants` file to provide the name `.closeSafariVC`. Pass the value from the incoming `url` argument to the `object` parameter of the notification.
  * *Note:* As mentioned above, the incoming `url` argument value contains a temporary code that we need to proceed with the GitHub authentication process.
 * Head back to the `LoginViewController` class and add a method called `safariLogin` that takes one argument called `notification` of type `NSNotification` and returns nothing.
 * Add a notification observer inside `viewDidLoad()` of the `LoginViewController` class.
  * The observer is the `LoginViewController`.
  * The selector is the method you just created above.
  * The name is the name you used for the post notification in the app delegate.
  * The object is nil.
 * Inside `safariLogin(_:)` get the absolute URL value from the notification argument and print it in the debugger.
  * *Hint:* Explore the properties on `notification`.
 * Dismiss the safari view controller.
 * Run the application, provide your credentials to GitHub in the safari view controller, and authorize the application.
  * The URL containing the temporary code should print to the debugger and the safari view controller should be dismissed.

See you in Part II!
