/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
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
    func createObject<T: StateType>(_ ref: FIRDatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) -> (_ state: T, _ store: Store<T>) -> Action?
    func updateObject<T: StateType>(_ ref: FIRDatabaseReference, parameters: JSONObject) -> (_ state: T, _ store: Store<T>) -> Action?
    func removeObject<T: StateType>(_ ref: FIRDatabaseReference) -> (_ state: T, _ store: Store<T>) -> Action?
    func getObject(_ objectRef: FIRDatabaseReference, completion: @escaping (_ objectJSON: JSONObject?) -> Void)
    func observeObject<T: StateType>(_ objectRef: FIRDatabaseReference, _ callback: @escaping (_ objectJSON: JSONObject?) -> Void) -> (_ state: T, _ store: Store<T>) -> Action?
    func stopObservingObject<T: StateType>(_ objectRef: FIRDatabaseReference) -> (_ state: T, _ store: Store<T>) -> Action?
    func search(_ baseQuery: FIRDatabaseQuery, key: String, value: String, completion: @escaping (_ json: JSONObject?) -> Void)
    
    
    // MARK: - Overridable authentication functions
    
    func getUserId() -> String?
    func getUserEmailVerified() -> Bool
    func sendEmailVerification<T: StateType>(_ state: T, store: Store<T>) -> Action?
    func reloadCurrentUser<T: StateType>(_ state: T, store: Store<T>) -> Action?
    func logInUser<T: StateType>(_ email: String, password: String) -> (_ state: T, _ store: Store<T>) -> Action?
    func signUpUser<T: StateType>(_ email: String, password: String, completion: ((_ userId: String?) -> Void)?) -> (_ state: T, _ store: Store<T>) -> Action?
    func changeUserPassword<T: StateType>(_ newPassword: String) -> (_ state: T, _ store: Store<T>) -> Action?
    func changeUserEmail<T: StateType>(_ email: String) -> (_ state: T, _ store: Store<T>) -> Action?
    func resetPassword<T: StateType>(_ email: String) -> (_ state: T, _ store: Store<T>) -> Action?
    func logOutUser<T: StateType>(_ state: T, store: Store<T>) -> Action?
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
    public func createObject<T: StateType>(_ ref: FIRDatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            let finalRef = createNewChildId ? ref.childByAutoId() : ref
            var parameters = parameters
            if removeId {
                parameters.removeValue(forKey: "id")
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
    public func updateObject<T: StateType>(_ ref: FIRDatabaseReference, parameters: JSONObject) -> (_ state: T, _ store: Store<T>) -> Action? {
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
    func recursivelyUpdate(_ ref: FIRDatabaseReference, parameters: JSONObject) {
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
    public func removeObject<T: StateType>(_ ref: FIRDatabaseReference) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            ref.removeValue()
            return nil
        }
    }
    
    /**
     Attempts to load data for a specific object. Passes the JSON data for the object
     to the completion handler.
     
     - Parameters:
     - objectRef:    A Firebase database reference to the data object
     - completion:   A closure to run after retrieving the data and parsing it
     */
    public func getObject(_ objectRef: FIRDatabaseReference, completion: @escaping (_ objectJSON: JSONObject?) -> Void) {
        objectRef.observeSingleEvent(of: .value, with: { snapshot in
            self.process(snapshot: snapshot, callback: completion)
        })
    }
    
    /**
     Observes all events for a given ref and calls the callback with each event emitted.
     
     - Parameters:
     - objectRef:    A Firebase database reference to the data object
     - completion:   A closure to run after retrieving the data and parsing it
     */
    public func observeObject<T: StateType>(_ objectRef: FIRDatabaseReference, _ callback: @escaping (_ objectJSON: JSONObject?) -> Void) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            objectRef.observe(.value, with: { snapshot in
                self.process(snapshot: snapshot, callback: callback)
            })
            return ObjectObserved(path: objectRef.description(), observed: true)
        }
    }
    
    fileprivate func process(snapshot: FIRDataSnapshot, callback: (_ objectJSON: JSONObject?) -> Void) {
        guard snapshot.exists() && !(snapshot.value is NSNull) else { callback(nil); return }
        if var json = snapshot.value as? JSONObject {
            json["id"] = snapshot.key
            callback(json)
        } else if let value = snapshot.value {
            callback([snapshot.key: value])
        } else {
            callback(nil)
        }
    }
    
    /**
     Remove all observers for the specific ref.
     
     - parameter objectRef: A Firebase database reference to the data object
     */
    public func stopObservingObject<T: StateType>(_ objectRef: FIRDatabaseReference) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            objectRef.removeAllObservers()
            return ObjectObserved(path: objectRef.description(), observed: false)
        }
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
    public func search(_ baseQuery: FIRDatabaseQuery, key: String, value: String, completion: @escaping (_ json: JSONObject?) -> Void) {
        let query = baseQuery.queryOrdered(byChild: key).queryEqual(toValue: value)
        query.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() && !(snapshot.value is NSNull) else { completion(nil); return }
            guard let json = snapshot.value as? JSONObject else { completion(nil); return }
            completion(json)
        })
    }
    
}
