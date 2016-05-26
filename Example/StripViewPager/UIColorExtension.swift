//
//  UIColorExtension.swift
//  TestNavigationBar
//
//  Created by TrungP1 on 5/20/16.
//  Copyright © 2016 TrungP1. All rights reserved.
//

import UIKit

extension UIColor {
    
    public convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var formatted = hexString.stringByReplacingOccurrencesOfString("0x", withString: "")
        formatted = formatted.stringByReplacingOccurrencesOfString("#", withString: "")
        if let hex = Int(formatted, radix: 16) {
            let red = CGFloat(CGFloat((hex & 0xFF0000) >> 16)/255.0)
            let green = CGFloat(CGFloat((hex & 0x00FF00) >> 8)/255.0)
            let blue = CGFloat(CGFloat((hex & 0x0000FF) >> 0)/255.0)
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return nil
        }
    }
}