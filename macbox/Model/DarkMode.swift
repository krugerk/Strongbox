//
//  DarkMode.swift
//  MacBox
//
//  Created by Strongbox on 17/11/2021.
//  Copyright © 2021 Mark McGuill. All rights reserved.
//

import Foundation

struct DarkMode {
    static var isOn : Bool { // TODO: Test this
        get {
            let osxMode : String? = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
            
            return osxMode != nil && osxMode == "Dark"
        }
    }
}
