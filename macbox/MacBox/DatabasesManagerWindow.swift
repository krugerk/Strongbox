//
//  DatabasesManagerWindow.swift
//  MacBox
//
//  Created by Strongbox on 23/11/2021.
//  Copyright © 2021 Mark McGuill. All rights reserved.
//

import Cocoa

class DatabasesManagerWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override func cancelOperation(_: Any?) { // Pickup Esc
        close()
    }
}