//
//  ViewPager.swift
//  TestNavigationBar
//
//  Created by TrungP1 on 5/18/16.
//  Copyright © 2016 TrungP1. All rights reserved.
//

import UIKit

public protocol ViewPagerDelegate {
    
    // Get number of view controllers
    func numberOfViews() -> Int
    
    // Init viewController at index
    func getViewControllerAtIndex(index: Int) -> UIViewController
    
}

@IBDesignable public class ViewPager: UIView {
    
    /**
     Delegate for view pager
     */
    public var delegate: ViewPagerDelegate?
    
    /**
     The view controller which host the view pager. This view controller use to add child view controller is the view pager.
     */
    public var hostViewController: UIViewController?
    
    // Readonly properties
    public private(set) var scrollView: UIScrollView?
    
    // Internal views
    public private(set) var viewControllers: [UIViewController]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        if scrollView == nil {
            scrollView = UIScrollView()
            
            // Enable paging
            scrollView?.pagingEnabled = true
            addSubview(scrollView!)
        }
        
        setupSubViews()
        
        setNeedsUpdateConstraints()
    }
    
    func setupSubViews() {
        guard let delegate = delegate else { return }
        guard let scrollView = scrollView else { return }
        guard let hostViewController = hostViewController else {
            print("Host view controller must be configured")
            return
        }
        if let _ = viewControllers { return }
        
        viewControllers = [UIViewController]()
        
        let numberOfViews = delegate.numberOfViews()
        for index in 0..<numberOfViews {
            let viewController = delegate.getViewControllerAtIndex(index)
            hostViewController.addChildViewController(viewController)
            // Add view to scrollView
            scrollView.addSubview(viewController.view)
            
            viewController.didMoveToParentViewController(hostViewController)
            
            // Keep the viewController in array to update constraints
            viewControllers?.append(viewController)
        }
        scrollView.contentSize = CGSizeMake(CGFloat(numberOfViews) * scrollView.bounds.size.width, 1)
    }
    
    // Reload child view controllers
    public func reload() {
        guard let viewControllers = viewControllers else { return }
        for viewController in viewControllers {
            viewController.willMoveToParentViewController(hostViewController)
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
            viewController.didMoveToParentViewController(hostViewController)
        }
        self.viewControllers = nil
    }
    
    /**
     Get viewController at index
     */
    public func getViewControllerAtIndex(index: Int) -> UIViewController? {
        if index < viewControllers?.count ?? 0 {
            return viewControllers?[index]
        }
        return nil
    }
    
    public override func updateConstraints() {
        // Init the view if needed
        setupSubViews()
        
        guard let scrollView = scrollView else { return }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove all constraints
        for constraint in self.constraints {
            if constraint.firstItem as? UIView ?? nil == scrollView && constraint.secondItem as? UIView ?? nil == self {
                self.removeConstraint(constraint)
            }
        }
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[scrollView]-0-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["scrollView" : scrollView])
        self.addConstraints(horizontalConstraints)
        
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[scrollView]-0-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["scrollView" : scrollView])
        self.addConstraints(verticalConstraints)
        
        /*
         scrollView.snp_makeConstraints { make in
         make.left.equalTo(self.snp_left)
         make.top.equalTo(self.snp_top)
         make.right.equalTo(self.snp_right)
         make.bottom.equalTo(self.snp_bottom)
         }*/
        
        let numberOfViews = viewControllers?.count ?? 0
        var previousView: UIView?
        for index in 0..<numberOfViews {
            guard let viewController = viewControllers?[index] else { continue }
            
            let view = viewController.view
            
            view.translatesAutoresizingMaskIntoConstraints = false
            
            // Remove left, right, height constraints between itemView and scrollView
            for constraint in self.constraints {
                if constraint.firstItem as? UIView ?? nil == view && constraint.secondItem as? UIView ?? nil == self {
                    self.removeConstraint(constraint)
                }
            }
            for constraint in scrollView.constraints {
                if constraint.firstItem as? UIView ?? nil == view && constraint.secondItem as? UIView ?? nil == scrollView {
                    scrollView.removeConstraint(constraint)
                }
            }
            
            // Width
            scrollView.addConstraint(NSLayoutConstraint(item: scrollView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
            
            // Top
            self.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
            
            // Bottom
            self.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
            
            // Left & right constraints
            if index == 0 {
                // First button
                scrollView.addConstraint(NSLayoutConstraint(item: scrollView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
                
            } else if index == numberOfViews - 1 {
                // Last button
                scrollView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: previousView!, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
                
                scrollView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: scrollView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
                
            } else {
                
                // Other buttons will base on previous button
                scrollView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: previousView!, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
            }
            
            /*
             // Layout
             view.snp_makeConstraints { make in
             make.width.equalTo(scrollView)
             make.top.equalTo(self)
             make.bottom.equalTo(self)
             
             if index == 0 {
             // First view in scroll
             make.left.equalTo(scrollView)
             } else if index == numberOfViews - 1 {
             // Last view
             guard let previousView = previousView else { return }
             make.left.equalTo(previousView.snp_right)
             // right
             make.right.equalTo(scrollView)
             } else {
             // Other view
             guard let previousView = previousView else { return }
             make.left.equalTo(previousView.snp_right)
             }
             }*/
            
            // The previous view is never nil
            previousView = view
        }
        super.updateConstraints()
    }
    
}
