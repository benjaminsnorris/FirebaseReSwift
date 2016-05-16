/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
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
public enum FirebaseSubscriptionError: ErrorType {
    case NoData(path: String)
    case MalformedData(path: String)
}

/**
 This protocol is adopted by a data object in order to receive updates of that from Firebase.
 
 - Note: The object must also adopt `Unmarshaling` in order to parse JSON into an object
 of that type.
 */

public extension SubscribingState {
    
    typealias SubscribingType = Self
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
         - query: The Firebase query to which to subscribe. This is usually
         constructed from the base `ref` using `childByAppendingPath(_)` or other 
         `FQuery` functions.
         - subscribingState:  A state object that provides information on whether the
         object has already been subscribed to or not.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func subscribeToObjects<T: StateType>(query: FQuery) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            if !self.subscribed {
                store.dispatch(ObjectSubscribed<SubscribingType>(subscribed: true))
                
                let idKey = "id"
                
                // Additions
                query.observeEventType(.ChildAdded, withBlock: { snapshot in
                    guard snapshot.exists() && !(snapshot.value is NSNull) else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.NoData(path: query.ref.description())))
                        return
                    }
                    guard var json = snapshot.value as? JSONObject else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.MalformedData(path: query.ref.description())))
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
                query.observeEventType(.ChildChanged, withBlock: { snapshot in
                    guard snapshot.exists() && !(snapshot.value is NSNull) else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.NoData(path: query.ref.description())))
                        return
                    }
                    guard var json = snapshot.value as? JSONObject else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.MalformedData(path: query.ref.description())))
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
                query.observeEventType(.ChildRemoved, withBlock: { snapshot in
                    guard snapshot.exists() && !(snapshot.value is NSNull) else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.NoData(path: query.ref.description())))
                        return
                    }
                    guard var json = snapshot.value as? JSONObject else {
                        store.dispatch(ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.MalformedData(path: query.ref.description())))
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
                
                return nil
            }
            
            return nil
        }
    }
    
}
