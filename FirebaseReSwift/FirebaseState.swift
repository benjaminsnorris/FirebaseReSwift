/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import ReSwift

public struct FirebaseState: StateType {
    static let idKey = "id"
    public init() { }
}

public typealias FirebaseActionCreator = Store<FirebaseState>.ActionCreator
