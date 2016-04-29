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
         - state: An object of type `StateType` which resolves the generic state type
         for the return value.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func createObject<T>(ref: Firebase, createNewChildId: Bool = false, parameters: MarshaledObject, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            let finalRef = createNewChildId ? ref.childByAutoId() : ref
            finalRef.setValue(parameters)
            return FirebaseDataChanged()
        }
    }
    
    /**
     Updates the Firebase object with the parameters, leaving all other values intact.
     
     - Parameters:
         - ref: The Firebase reference to the object to be updated.
         Usually constructed from the base `ref` using `childByAppendingPath(_)`
         - parameters: A `MarshaledObject` (`[String: AnyObject]`) representing the
         fields to be updated with their values.
         - state: An object of type `StateType` which resolves the generic state type
         for the return value.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func updateObject<T: StateType>(ref: Firebase, parameters: MarshaledObject, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            ref.updateChildValues(parameters)
            return FirebaseDataChanged()
        }
    }
    
    /**
     Removes a Firebase object at the given ref.
     
     - Parameters:
         - ref:     The Firebase reference to the object to be removed.
         - state:   An object of type `StateType` which resolves the generic state type
         for the return value.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose 
     type matches the `state` parameter.
     */
    public func removeObject<T>(ref: Firebase, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            ref.removeValue()
            return FirebaseDataChanged()
        }
    }
    
}
