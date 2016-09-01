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
    static let sharedAccess = FirebaseNetworkAccess()
    let ref: Firebase
    init() {
        FIRApp.configure()
        Firebase.defaultConfig().persistenceEnabled = true // Only for offline access
        ref = FIRDatabase.database().reference()
    }
 }
 ```
 */
public protocol FirebaseAccess {
    /// The base ref for your Firebase app
    var ref: FIRDatabaseReference { get }
    var currentApp: FIRApp? { get }
    
    
    // MARK: - Overridable API functions
    
    func newObjectId() -> String
    func createObject<T: StateType>(ref: FIRDatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) -> (state: T, store: Store<T>) -> Action?
    func updateObject<T: StateType>(ref: FIRDatabaseReference, parameters: JSONObject) -> (state: T, store: Store<T>) -> Action?
    func removeObject<T: StateType>(ref: FIRDatabaseReference) -> (state: T, store: Store<T>) -> Action?
    func getObject(objectRef: FIRDatabaseReference, completion: (objectJSON: JSONObject?) -> Void)
    func search(baseQuery: FIRDatabaseQuery, key: String, value: String, completion: (json: JSONObject?) -> Void)
    
    
    // MARK: - Overridable authentication functions
    
    func getUserId() -> String?
    func getUserEmailVerified() -> Bool
    func sendEmailVerification<T: StateType>(state: T, store: Store<T>) -> Action?
    func reloadCurrentUser<T: StateType>(state: T, store: Store<T>) -> Action?
    func logInUser<T: StateType>(email: String, password: String) -> (state: T, store: Store<T>) -> Action?
    func signUpUser<T: StateType>(email: String, password: String, completion: ((userId: String?) -> Void)?) -> (state: T, store: Store<T>) -> Action?
    func changeUserPassword<T: StateType>(newPassword: String) -> (state: T, store: Store<T>) -> Action?
    func changeUserEmail<T: StateType>(email: String) -> (state: T, store: Store<T>) -> Action?
    func resetPassword<T: StateType>(email: String) -> (state: T, store: Store<T>) -> Action?
    func logOutUser<T: StateType>(state: T, store: Store<T>) -> Action?
}

public extension FirebaseAccess {
    
    // MARK: - Public API
    
    /// Generates an automatic id for a new child object
    public func newObjectId() -> String {
        return ref.childByAutoId().key
    }
    
    /**
     Writes a Firebase object with the parameters, overwriting any values at the specific location.
     
     - Parameters:
         - ref: The Firebase database reference to the object to be written.
         Usually constructed from the base `ref` using `childByAppendingPath(_)`
         - createNewChildId: A flag indicating whether a new child ID needs to be
         created before saving the new object.
         - removeId: A flag indicating whether the key-value pair for `id` should
         be removed before saving the new object.
         - parameters: A `JSONObject` (`[String: AnyObject]`) representing the
         object with all of its properties.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func createObject<T: StateType>(ref: FIRDatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            let finalRef = createNewChildId ? ref.childByAutoId() : ref
            var parameters = parameters
            if removeId {
                parameters.removeValueForKey("id")
            }
            finalRef.setValue(parameters)
            return nil
        }
    }
    
    /**
     Updates the Firebase object with the parameters, leaving all other values intact.

     - Parameters:
         - ref: The Firebase database reference to the object to be updated.
         Usually constructed from the base `ref` using `childByAppendingPath(_)`
         - parameters: A `JSONObject` (`[String: AnyObject]`) representing the
         fields to be updated with their values.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func updateObject<T: StateType>(ref: FIRDatabaseReference, parameters: JSONObject) -> (state: T, store: Store<T>) -> Action? {
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
        - parameters: A `JSONObject` (`[String: AnyObject]`) representing the
        fields to be updated with their values.
    */
    func recursivelyUpdate(ref: FIRDatabaseReference, parameters: JSONObject) {
        var result = JSONObject()
        for (key, value) in parameters {
            if let object = value as? JSONObject {
                recursivelyUpdate(ref.child(key), parameters: object)
            } else {
                result[key] = value
            }
        }
        ref.updateChildValues(result)
    }
    
    /**
     Removes a Firebase object at the given ref.
     
     - Parameters:
         - ref:     The Firebase database reference to the object to be removed.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose 
     type matches the `state` parameter.
     */
    public func removeObject<T: StateType>(ref: FIRDatabaseReference) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            ref.removeValue()
            return nil
        }
    }
    
    /**
     Attempts to load data for a specific object. Passes the JSON data for the object
     to the completion handler.
     
     - Parameters:
     - ref:          A Firebase database reference to the data object
     - completion:   A closure to run after retrieving the data and parsing it
     */
    public func getObject(objectRef: FIRDatabaseReference, completion: (objectJSON: JSONObject?) -> Void) {
        objectRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            guard snapshot.exists() && !(snapshot.value is NSNull) else { completion(objectJSON: nil); return }
            guard var json = snapshot.value as? JSONObject else { completion(objectJSON: nil); return }
            json["id"] = snapshot.key
            completion(objectJSON: json)
        })
    }
    
    /**
     Searches for one or more objects at the location specified in the `baseQuery`. Passes
     the JSON data for the objects found to the completion handler.
     
     - Parameters:
     - baseQuery:   A Firebase database query for the data object table
     - key:         The name of the field to be searched
     - value:       The search term to query
     - completion:  A closure to run after retrieving the data and parsing as JSON
     */
    public func search(baseQuery: FIRDatabaseQuery, key: String, value: String, completion: (json: JSONObject?) -> Void) {
        let query = baseQuery.queryOrderedByChild(key).queryEqualToValue(value)
        query.observeSingleEventOfType(.Value, withBlock: { snapshot in
            guard snapshot.exists() && !(snapshot.value is NSNull) else { completion(json: nil); return }
            guard let json = snapshot.value as? JSONObject else { completion(json: nil); return }
            completion(json: json)
        })
    }
    
}
