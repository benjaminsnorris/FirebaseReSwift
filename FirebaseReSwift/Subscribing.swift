/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Marshal
import ReSwift
import Firebase

/// A protocol to be adopted by sub states that hold a flag indicating whether an object
/// has been subscribed to in Firebase or not.
public protocol SubscribingState: StateType {
    var subscribed: Bool { get }
    associatedtype SubscribingObject: Unmarshaling, EndpointNaming
}

/// Protocol for objects which have an associated endpoint name
public protocol EndpointNaming {
    static var endpointName: String { get }
}

/**
 An error that occurred parsing data from a Firebase event.
 
 - `NoData`:    The snapshot for the event contained no data
 - `MalformedData`:  The data in the snapshot could not be parsed as JSON
 */
public enum FirebaseSubscriptionError: Error {
    case noData(path: String)
    case malformedData(path: String)
}

extension FirebaseSubscriptionError: Equatable { }

public func ==(lhs: FirebaseSubscriptionError, rhs: FirebaseSubscriptionError) -> Bool {
    switch (lhs, rhs) {
    case (.noData(_), .noData(_)):
        return true
    case (.malformedData(_), .malformedData(_)):
        return true
    default:
        return false
    }
}

/**
 This protocol is adopted by a state object in order to receive updates of a specific
 data object from Firebase.
 
 - Note: The object must also adopt `Unmarshaling` in order to parse JSON into an object
 of that type.
 */

public extension SubscribingState {
    
    typealias ObjectType = Self.SubscribingObject
    
    /**
     Calling this function results in the dispatching actions to the store for the following
     events that occur in Firebase matching the given query. The actions are generic actions
     scoped to the data object on which the function is called.
     
     - Note: The `ObjectErrored` action can be called on any of those events if the resulting
     data does not exist, or cannot be parsed from JSON into the data object. It is likewise a
     generic action scoped to the data object.
     
     - `ChildAdded` event:      `ObjectAdded` action
     - `ChildChanged` event:    `ObjectChanged` action
     - `ChildRemoved` event:    `ObjectRemoved` action
     
     - Parameters:
         - query: The Firebase database query to which to subscribe. This is usually
         constructed from the base `ref` using `childByAppendingPath(_)` or other 
         `FQuery` functions.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func subscribeToObjects<T: StateType>(_ query: FIRDatabaseQuery) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            if !self.subscribed {
                let idKey = "id"
                
                // Additions
                query.observe(.childAdded, with: { snapshot in
                    guard snapshot.exists() && !(snapshot.value is NSNull) else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.noData(path: query.ref.description())))
                        return
                    }
                    guard var json = snapshot.value as? JSONObject else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.malformedData(path: query.ref.description())))
                        return
                    }
                    json[idKey] = snapshot.key
                    do {
                        let object = try ObjectType(object: json)
                        store.dispatch(ObjectAdded(object: object))
                    } catch {
                        store.dispatch(ObjectErrored<ObjectType>(error: error))
                    }
                })
                
                // Changes
                query.observe(.childChanged, with: { snapshot in
                    guard snapshot.exists() && !(snapshot.value is NSNull) else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.noData(path: query.ref.description())))
                        return
                    }
                    guard var json = snapshot.value as? JSONObject else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.malformedData(path: query.ref.description())))
                        return
                    }
                    json[idKey] = snapshot.key
                    do {
                        let object = try ObjectType(object: json)
                        store.dispatch(ObjectChanged(object: object))
                    } catch {
                        store.dispatch(ObjectErrored<ObjectType>(error: error))
                    }
                })
                
                // Removals
                query.observe(.childRemoved, with: { snapshot in
                    guard snapshot.exists() && !(snapshot.value is NSNull) else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.noData(path: query.ref.description())))
                        return
                    }
                    guard var json = snapshot.value as? JSONObject else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.malformedData(path: query.ref.description())))
                        return
                    }
                    json[idKey] = snapshot.key
                    do {
                        let object = try ObjectType(object: json)
                        store.dispatch(ObjectRemoved(object: object))
                    } catch {
                        store.dispatch(ObjectErrored<ObjectType>(error: error))
                    }
                })
                
                return ObjectSubscribed(subscribed: true, state: self)
            }
            
            return nil
        }
    }
    
    /**
     Removes all observers on a `FIRDatabaseQuery`.
     
     - Note: This is often used when signing out, or switching Firebase apps.
     
     - Parameter query: The query that was originally used to subscribe to events.
     */
    public func removeSubscriptions<T: StateType>(_ query: FIRDatabaseQuery) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            if self.subscribed {
                query.removeAllObservers()
                return ObjectSubscribed(subscribed: false, state: self)
            }
            return nil
        }
    }
    
}
