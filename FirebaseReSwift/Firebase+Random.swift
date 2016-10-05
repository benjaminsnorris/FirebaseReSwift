/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase

public extension FIRApp {
    
    public static func random(with ref: FIRDatabaseReference) -> FIRApp {
        var randomNumber = arc4random_uniform(1000)
        while FIRApp(named: String(randomNumber)) != nil {
            randomNumber = arc4random_uniform(1000)
        }
        let randomName = String(randomNumber)
        let options = ref.database.app!.options
        FIRApp.configure(withName: randomName, options: options)
        return FIRApp(named: randomName)!
    }
    
}
