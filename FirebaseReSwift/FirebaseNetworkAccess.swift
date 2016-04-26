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

public protocol FirebaseAccess {
    static var sharedAccess: FirebaseAccess { get }
    var ref: Firebase { get }
}

public extension FirebaseAccess {
    
    // MARK: - Query helpers
    
    public func newObjectId(ref: Firebase) -> String? {
        guard let id = ref.childByAutoId().key else { return nil }
        return id
    }
    
    
    // MARK: - Public API
    
    public func updateObject(ref: Firebase, parameters: MarshaledObject) -> FirebaseActionCreator {
        return { state, store in
            ref.updateChildValues(parameters)
            return nil
        }
    }
    
    public func createObject(ref: Firebase, parameters: MarshaledObject) -> FirebaseActionCreator {
        return { state, store in
            ref.setValue(parameters)
            return nil
        }
    }
    
}


// MARK: - Subscribing protocol

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
