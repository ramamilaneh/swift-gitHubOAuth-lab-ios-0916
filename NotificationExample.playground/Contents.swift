import UIKit
import PlaygroundSupport

// MARK: Notification.Name extension

// Used for organizing and providing unique names for inidividual notifications.
extension Notification.Name {

    static let notificationForViewControllerA = Notification.Name("Notification for view controller A")
    
}


// MARK: View Controller A

class ViewControllerA: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a notification observer to receive notifications with the name from the extension above.
        // Selector method will be called when the notification is received.
        NotificationCenter.default.addObserver(self, selector: #selector(notificationRecieved(_:)), name: .notificationForViewControllerA, object: nil)

    }
    
    // Method that will be called by the notification observer if and when a notification is received
    func notificationRecieved(_ notification: Notification) {
        
        // Get the string "Hello" message from the object property of the notification argument
        let message = notification.object as! String
        
        // Print the message to the console
        print(message)
        
    }
    
}


// MARK: View Controller B

class ViewControllerB: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Post a notification to ViewController A using the name from the extension above
        // Pass a string object with the post notification to be printed out in view controller B
        NotificationCenter.default.post(name: .notificationForViewControllerA, object: "Hello")
        
    }
    
}

// MARK: View Controller Instances

let viewControllerA = ViewControllerA()
let viewControllerB = ViewControllerB()
PlaygroundPage.current.liveView = viewControllerA
PlaygroundPage.current.liveView = viewControllerB


