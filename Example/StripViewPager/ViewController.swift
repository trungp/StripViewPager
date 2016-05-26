//
//  ViewController.swift
//  TestNavigationBar
//
//  Created by TrungP1 on 4/27/16.
//  Copyright © 2016 TrungP1. All rights reserved.
//

import UIKit
import StripViewPager

class ViewController: UIViewController, UIScrollViewDelegate, StripViewDelegate, ViewPagerDelegate {
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet var stripView: StripView?
    @IBOutlet var viewPager: ViewPager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide toolbar first.
        navigationController?.navigationBarHidden = true
        
        topBarView?.backgroundColor = Colors.topBarColor
        stripView?.delegate = self
        stripView?.hostScrollView = viewPager?.scrollView
        stripView?.scrollViewProxyDelegate = self
        
        // Config viewPager
        viewPager?.hostViewController = self
        viewPager?.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

// MARK: ViewPagerDelegate
extension ViewController {
    
    // Get number of view controllers
    func numberOfViews() -> Int {
        return 5
    }
    
    // Build view controller
    func getViewControllerAtIndex(index: Int) -> UIViewController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let vc = mainStoryboard.instantiateViewControllerWithIdentifier("PageViewController") as? PageViewController ?? PageViewController()
        return vc
    }
}

// MARK: StripViewDelegate
extension ViewController {
    
    // Get number of items in stripView
    func numberOfItems(stripView: StripView) -> Int {
        return 5
    }
    
    // Get button view
    func getButtonView(stripView: StripView, index: Int) -> UIButton {
        let button = UIButton()
        button.setTitle("Button \(index)", forState: .Normal)
        return button
    }
    
    // Get focus view
    func getFocusView(stripView: StripView) -> UIView {
        let view = HighlightView()
        return view
    }
    
    // Handle select on view
    func didSelectOnViewAtIndex(stripView: StripView, buttonIndex: Int) {
        guard let scrollViewWidth = viewPager?.scrollView?.bounds.size.width else { return }
        viewPager?.scrollView?.setContentOffset(CGPointMake(scrollViewWidth * CGFloat(buttonIndex), 0), animated: true)
    }
    
    // Highlight selected item
    func highlightItem(button: UIButton, highlight: Bool) {
        button.setTitleColor(highlight ? Colors.highlightTopMenuColor : UIColor.whiteColor(), forState: .Normal)
    }
}

