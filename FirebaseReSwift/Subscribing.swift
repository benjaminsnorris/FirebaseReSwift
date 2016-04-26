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


public protocol Subscribing: Unmarshaling, Hydrating { }

public extension Subscribing {
    
    typealias ObjectType = Self
    
    public static func subscribeToObjects(query: FQuery, subscribingState: SubscribingState) -> FirebaseActionCreator {
        return { state, store in
            if !subscribingState.subscribed {
                store.dispatch(ObjectSubscribed<ObjectType>(subscribed: true))
                
                // Additions
                query.observeEventType(.ChildAdded, withBlock: { snapshot in
                    if var json = snapshot.value as? JSONObject where snapshot.exists() {
                        json[FirebaseState.idKey] = snapshot.key
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
                        json[FirebaseState.idKey] = snapshot.key
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
                        json[FirebaseState.idKey] = snapshot.key
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
