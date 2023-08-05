//
//  Definition.swift
//  MyStepCounter
//
//  Created by MACNO on 05/08/2023.
//

import Foundation
import UIKit

let defaults = UserDefaults.standard
let lastCount = "LastCount"
let totalSteps = "TotalSteps"

func setUserDefault(value:Int,key:String) {
    defaults.setValue(value, forKey: key)
}

func getUserDefault(key:String) -> Int? {
    let result = defaults.integer(forKey: key)
    return result
}
func ValueAlreadyExist(key: String) -> Bool {
    return UserDefaults.standard.string(forKey: key) != nil
}

