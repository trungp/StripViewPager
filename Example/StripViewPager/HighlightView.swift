//
//  HighlightView.swift
//  TestNavigationBar
//
//  Created by TrungP1 on 5/20/16.
//  Copyright © 2016 TrungP1. All rights reserved.
//

import UIKit

class HighlightView: UIView {
    
    var borderHeight: CGFloat = 26
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        let drawRect = CGRectMake(1, (self.bounds.size.height - borderHeight) / 2, self.bounds.size.width - 2, borderHeight)
        let ovalPath = UIBezierPath(roundedRect: drawRect, cornerRadius: borderHeight / 2)
        Colors.highlightTopMenuColor!.setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
    }
}
