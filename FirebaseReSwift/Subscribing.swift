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

/**
 This protocol is adopted by a data object in order to receive updates of that from Firebase.
 
 - Note: The object must also adopt `Unmarshaling` in order to parse JSON into an object
 of that type. It must also adopt `Hydrating` in order to dispatch hydration actions.
 */
public protocol Subscribing: Unmarshaling, Hydrating { }

public extension Subscribing {
    
    typealias ObjectType = Self
    private static var idKey: String { return "id" }
    
    /**
     Calling this function results in the dispatching actions to the store for the following
     events that occur in Firebase matching the given query. The actions are generic actions
     scoped to the data object on which the function is called.
     
     - `ChildAdded` event:      `ObjectAdded` action
     - `ChildChanged` event:    `ObjectChanged` action
     - `ChildRemoved` event:    `ObjectRemoved` action
     
     - Note: The `ObjectErrored` action can be called on any of those events if the resulting
     data does not exist, or cannot be parsed from JSON into the data object. It is likewise a
     generic action scoped to the data object.
     
     - parameter query:     The Firebase query to which to subscribe. This is usually
     constructed from the base `ref` using `childByAppendingPath(_)` or other 
     `FQuery` functions.
     - parameter subscribingState:  A state object that provides information on whether the
     object has already been subscribed to or not.
     - parameter state: An object of type `StateType` which resolves the generic state type
     for the return value.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose type matches the `state` parameter.
     */
    public static func subscribeToObjects<T: StateType>(query: FQuery, subscribingState: SubscribingState, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            if !subscribingState.subscribed {
                store.dispatch(ObjectSubscribed<ObjectType>(subscribed: true))
                
                // Additions
                query.observeEventType(.ChildAdded, withBlock: { snapshot in
                    if var json = snapshot.value as? JSONObject where snapshot.exists() {
                        json[idKey] = snapshot.key
                        do {
                            let object = try Self(object: json)
                            store.dispatch(ObjectAdded(object: object))
                            store.dispatch(HydrateObject(object: object))
                        } catch {
                            store.dispatch(ObjectErrored<ObjectType>(error: error))
                        }
                    } else {
                        store.dispatch(ObjectErrored<ObjectType>(error: nil))
                    }
                })
                
                // Changes
                query.observeEventType(.ChildChanged, withBlock: { snapshot in
                    if var json = snapshot.value as? JSONObject where snapshot.exists() {
                        json[idKey] = snapshot.key
                        do {
                            let object = try Self(object: json)
                            store.dispatch(ObjectChanged(object: object))
                            store.dispatch(HydrateObject(object: object))
                        } catch {
                            store.dispatch(ObjectErrored<ObjectType>(error: error))
                        }
                    } else {
                        store.dispatch(ObjectErrored<ObjectType>(error: nil))
                    }
                })
                
                // Removals
                query.observeEventType(.ChildRemoved, withBlock: { snapshot in
                    if var json = snapshot.value as? JSONObject where snapshot.exists() {
                        json[idKey] = snapshot.key
                        do {
                            let object = try Self(object: json)
                            store.dispatch(ObjectRemoved(object: object))
                        } catch {
                            store.dispatch(ObjectErrored<ObjectType>(error: error))
                        }
                    } else {
                        store.dispatch(ObjectErrored<ObjectType>(error: nil))
                    }
                })
            }
            
            return nil
        }
    }
    
}