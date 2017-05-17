/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase

public extension FirebaseApp {
    
    public static func random(with ref: DatabaseReference) -> FirebaseApp {
        var randomNumber = arc4random_uniform(1000)
        while FirebaseApp.app(name: String(randomNumber)) != nil {
            randomNumber = arc4random_uniform(1000)
        }
        let randomName = String(randomNumber)
        let options = ref.database.app!.options
        FirebaseApp.configure(name: randomName, options: options)
        return FirebaseApp.app(name: randomName)!
    }
    
}
