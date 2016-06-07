/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase
import Marshal
import ReSwift

/**
 This protocol along with its extension defines some core functionality with Firebase.
 
 You will typically adopt this in a struct that might look like this:
 
 ```swift
 struct FirebaseNetworkAccess: FirebaseAccess {
    static let sharedAccess: FirebaseAccess = FirebaseNetworkAccess()
    let ref: Firebase
    init() {
        Firebase.defaultConfig().persistenceEnabled = true // Only for offline access
        self.ref = Firebase(url: "https://your-app.firebaseio.com")
    }
 }
 ```
 */
public protocol FirebaseAccess {
    /// The sharedAcccess that should be used when accessing Firebase
    static var sharedAccess: FirebaseAccess { get }
    /// The base ref for your Firebase app
    var ref: Firebase { get }
    
    
    // MARK: - Overridable API functions
    
    func newObjectId() -> String?
    func createObject<T>(ref: Firebase, createNewChildId: Bool, parameters: MarshaledObject) -> (state: T, store: Store<T>) -> Action?
    func updateObject<T: StateType>(ref: Firebase, parameters: MarshaledObject) -> (state: T, store: Store<T>) -> Action?
    func removeObject<T>(ref: Firebase) -> (state: T, store: Store<T>) -> Action?
    func getObject(objectRef: Firebase, completion: (objectJSON: JSONObject?) -> Void)
    
    
    // MARK: - Overridable authentication functions
    
    func getUserId() -> String?
    func logInUser<T: StateType>(email: String, password: String) -> (state: T, store: Store<T>) -> Action?
    func signUpUser<T: StateType>(email: String, password: String) -> (state: T, store: Store<T>) -> Action?
    func changeUserPassword<T: StateType>(email: String, oldPassword: String, newPassword: String) -> (state: T, store: Store<T>) -> Action?
    func changeUserEmail<T: StateType>(email: String, password: String, newEmail: String) -> (state: T, store: Store<T>) -> Action?
    func resetPassword<T: StateType>(email: String) -> (state: T, store: Store<T>) -> Action?
    func logOutUser<T: StateType>(state: T, store: Store<T>) -> Action?
}

public extension FirebaseAccess {
    
    // MARK: - Public API
    
    /// Generates an automatic id for a new child object
    public func newObjectId() -> String? {
        guard let id = ref.childByAutoId().key else { return nil }
        return id
    }
    
    /**
     Writes a Firebase object with the parameters, overwriting any values at the specific location.
     
     - Parameters:
         - ref: The Firebase reference to the object to be written.
         Usually constructed from the base `ref` using `childByAppendingPath(_)`
         - createNewChildId: A flag indicating whether a new child ID needs to be
         created before saving the new object.
         - parameters: A `MarshaledObject` (`[String: AnyObject]`) representing the
         object with all of its properties.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func createObject<T: StateType>(ref: Firebase, createNewChildId: Bool = false, parameters: MarshaledObject) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            let finalRef = createNewChildId ? ref.childByAutoId() : ref
            finalRef.setValue(parameters)
            return nil
        }
    }
    
    /**
     Updates the Firebase object with the parameters, leaving all other values intact.
     
     Note: If the parameters include child node(s) as sibling(s) to leaf node(s), there
     is a chance that properties could be removed when updating.

     - Parameters:
         - ref: The Firebase reference to the object to be updated.
         Usually constructed from the base `ref` using `childByAppendingPath(_)`
         - parameters: A `MarshaledObject` (`[String: AnyObject]`) representing the
         fields to be updated with their values.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func updateObject<T: StateType>(ref: Firebase, parameters: MarshaledObject) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.recursivelyUpdate(ref, parameters: parameters)
            return nil
        }
    }
    
    /**
     Recurses through parameters until only the leaf node(s) are included,
     modifying the ref through each recursion. This ensures that no other properties
     are removed from the ref when the update occurs.
     
     - Parameters:
        - ref: The Firebase reference to the object to be updated.
        - parameters: A `MarshaledObject` (`[String: AnyObject]`) representing the
        fields to be updated with their values.
    */
    func recursivelyUpdate(ref: Firebase, parameters: MarshaledObject) {
        if let key = parameters.first?.0, value = parameters.first?.1 as? MarshaledObject where parameters.count == 1 {
            recursivelyUpdate(ref.childByAppendingPath(key), parameters: value)
        } else {
            ref.updateChildValues(parameters)
        }
    }
    
    /**
     Removes a Firebase object at the given ref.
     
     - Parameters:
         - ref:     The Firebase reference to the object to be removed.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose 
     type matches the `state` parameter.
     */
    public func removeObject<T: StateType>(ref: Firebase) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            ref.removeValue()
            return nil
        }
    }
    
    /**
     Attempts to load data for a specific object. Passes the JSON data for the object
     to the completion handler
     
     - Parameters:
     - ref:          A Firebase reference to the data object
     - completion:   A closure to run after retrieving the data and parsing it
     */
    public func getObject(objectRef: Firebase, completion: (objectJSON: JSONObject?) -> Void) {
        objectRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            guard snapshot.exists() && !(snapshot.value is NSNull) else { completion(objectJSON: nil); return }
            guard var json = snapshot.value as? JSONObject else { completion(objectJSON: nil); return }
            json["id"] = snapshot.key
            completion(objectJSON: json)
        })
    }
    
}
