/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import ReSwift
import Marshal

/// Simple protocol to help categorize actions
public protocol FirebaseSeriousErrorAction: Action {
    var error: Error { get }
}

/// Simple protocol to help categorize actions
public protocol FirebaseMinorErrorAction: Action {
    var error: Error { get }
}

/// Empty protocol to help categorize actions
public protocol FirebaseDataAction: Action { }


/**
 Generic action indicating that an object was added from Firebase and should be stored
 in the app state. The action is scoped to the object type that was added.
 - Parameters:
     - T:       The type of object that was added.
     - object:  The actual object that was added.
 */
public struct ObjectAdded<T>: FirebaseDataAction {
    public var object: T
    public init(object: T) { self.object = object }
}

/**
 Generic action indicating that an object was changed in Firebase and should be modified
 in the app state. The action is scoped to the object type that was added.
 - Parameters:
     - T:       The type of object that was changed.
     - object:  The actual object that was changed.
 */
public struct ObjectChanged<T>: FirebaseDataAction {
    public var object: T
    public init(object: T) { self.object = object }
}

/**
 Generic action indicating that an object was removed from Firebase and should be removed
 in the app state. The action is scoped to the object type that was added.
 - Parameters:
     - T:       The type of object that was removed.
     - object:  The actual object that was removed.
 */
public struct ObjectRemoved<T>: FirebaseDataAction {
    public var object: T
    public init(object: T) { self.object = object }
}

/** 
 Generic action indicating that an object has an error when parsing from a Firebase event.
 The action is scoped to the object type that was added.
 - Parameters:
     - T:       The type of object that produced the error
     - error:   An optional error indicating the problem that occurred
 */
public struct ObjectErrored<T>: Action, FirebaseMinorErrorAction {
    public var error: Error
    public init(error: Error) { self.error = error }
}

/**
 Generic action indicating that an object was subscribed to in Firebase.
 The action is scoped to whatever you need to track the subscription status.
 - Parameters:
     - T:           The type of state that can be subscribed or not
     - subscribed:  Flag indicating subscription status
 */
public struct ObjectSubscribed<T>: FirebaseDataAction {
    public var subscribed: Bool
    public var state: T
    public init(subscribed: Bool, state: T) {
        self.subscribed = subscribed
        self.state = state
    }
}

/**
 Action indicating that an object changed observed status.
 - Parameters:
    - path:     The path of the ref to the object
    - observed: Flag indicating when the object is being observed
 */
public struct ObjectObserved: FirebaseDataAction {
    public var path: String
    public var observed: Bool
    public init(path: String, observed: Bool) {
        self.path = path
        self.observed = observed
    }
}
