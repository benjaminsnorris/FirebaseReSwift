/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import ReSwift
import Marshal

/**
 Generic action indicating that an object was added from Firebase and should be stored
 in the app state. The action is scoped to the object type that was added.
 - Parameters:
     - T:       The type of object that was added.
     - object:  The actual object that was added.
 */
public struct ObjectAdded<T>: Action {
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
public struct ObjectChanged<T>: Action {
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
public struct ObjectRemoved<T>: Action {
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
public struct ObjectErrored<T>: Action {
    public var error: ErrorType
    public init(error: ErrorType) { self.error = error }
}

/**
 Generic action indicating that an object was subscribed to in Firebase.
 The action is scoped to whatever you need to track the subscription status.
 - Parameters:
     - T:           The type of state that can be subscribed or not
     - subscribed:  Flag indicating subscription status
 */
public struct ObjectSubscribed<T>: Action {
    public var subscribed: Bool
    public init(subscribed: Bool) { self.subscribed = subscribed }
}

/**
 Placeholder action to indicate that an action creator was dispatched.
 
 **Usage:** Return an action of this type instead of nil when dispatching an action creator.
 */
public struct ActionCreatorDispatched: Action {
    public init() { }
}

/**
 Placeholder action to indicate that data was changed in Firebase.
 
 **Usage:** Return an action of this type when nothing is being dispatched, but data has
 been changed in Firebase.
 */
public struct FirebaseDataChanged: Action {
    public init() { }
}
