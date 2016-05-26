//
//  StripView.swift
//  TestNavigationBar
//
//  Created by TrungP1 on 4/27/16.
//  Copyright © 2016 TrungP1. All rights reserved.
//

import UIKit

public protocol StripViewDelegate {
    
    // Get number of buttons
    func numberOfItems(stripView: StripView) -> Int
    
    // Get button view
    func getButtonView(stripView: StripView, index: Int) -> UIButton
    
    // Get focus view
    func getFocusView(stripView: StripView) -> UIView
    
    // Did select on view at index
    func didSelectOnViewAtIndex(stripView: StripView, buttonIndex: Int)
    
    // Highlight item for focused status
    func highlightItem(button: UIButton, highlight: Bool)
}

@IBDesignable public class StripView: UIView, UIScrollViewDelegate {
    
    public var delegate: StripViewDelegate?
    
    /**
     StripView will monitor some callback from the host scroll view to update the state of highlight view, update position of button, offset of scroll on stripView.
     */
    public var hostScrollView: UIScrollView? {
        didSet {
            hostScrollView?.delegate = self
        }
    }
    
    /**
     All callback from host scrollView delegate will be forwarded to proxyDelegate, so that other object can receive all action callbacks regularly.
     */
    public var scrollViewProxyDelegate: UIScrollViewDelegate?
    
    /**
     Only update this property on the first setup view.
     */
    public var currentItemIndex: Int = 0
    
    // Readonly properties
    public private(set) var stripScrollView: UIScrollView? = nil
    
    // Internal properties
    private var highlightView: UIView? = nil
    private var itemViews: [UIButton]?
    private var focusedItemIndex: Int = 0
    
    @IBInspectable public var leftRightSpace: CGFloat = 10 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    @IBInspectable public var space: CGFloat = 70 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    private var highlightViewMarginLeftRight: CGFloat = -5
    
    private var focusViewWidthConstraint: NSLayoutConstraint?
    private var focusViewLeftConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override public func updateConstraints() {
        
        // Prepare view if it is not available
        setupSubViews()
        
        guard let stripScrollView = stripScrollView else { return }
        // Setup constraints for scrollView
        
        stripScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove all constraints
        for constraint in self.constraints {
            if constraint.firstItem as? UIView ?? nil == stripScrollView && constraint.secondItem as? UIView ?? nil == self {
                self.removeConstraint(constraint)
            }
        }
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[scrollView]-0-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["scrollView" : stripScrollView])
        self.addConstraints(horizontalConstraints)
        
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[scrollView]-0-|", options: NSLayoutFormatOptions.AlignmentMask, metrics: nil, views: ["scrollView" : stripScrollView])
        self.addConstraints(verticalConstraints)
        
        var previousItemView: UIView? = nil
        
        let numberOfButtons = itemViews?.count ?? 0
        for index in 0..<numberOfButtons {
            guard let itemView = itemViews?[index] else { continue }
            itemView.translatesAutoresizingMaskIntoConstraints = false
            
            // Remove left, right, height constraints between itemView and scrollView
            for constraint in self.constraints {
                if constraint.firstItem as? UIView ?? nil == itemView && constraint.secondItem as? UIView ?? nil == self {
                    self.removeConstraint(constraint)
                }
            }
            for constraint in stripScrollView.constraints {
                if constraint.firstItem as? UIView ?? nil == itemView && constraint.secondItem as? UIView ?? nil == stripScrollView {
                    stripScrollView.removeConstraint(constraint)
                }
            }
            
            // Center Y constraint
            self.addConstraint(NSLayoutConstraint(item: itemView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
            
            // Equal height constraint
            stripScrollView.addConstraint(NSLayoutConstraint(item: itemView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: stripScrollView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
            
            // Left & right constraints
            if index == 0 {
                // First button
                stripScrollView.addConstraint(NSLayoutConstraint(item: stripScrollView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: -leftRightSpace))
                
            } else if index == numberOfButtons - 1 {
                // Last button
                stripScrollView.addConstraint(NSLayoutConstraint(item: itemView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: previousItemView!, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: space))
                
                stripScrollView.addConstraint(NSLayoutConstraint(item: itemView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: stripScrollView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
                
            } else {
                
                // Other buttons will base on previous button
                stripScrollView.addConstraint(NSLayoutConstraint(item: itemView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: previousItemView!, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: space))
            }
            
            // button is never null
            previousItemView = itemView
        }
        
        configConstraintsForFocusView(true)
        
        // Clear current constraints, these constraints need to update on update progress function
        focusViewWidthConstraint = nil
        focusViewLeftConstraint = nil
        
        super.updateConstraints()
    }
}

// MARK: Setup views
extension StripView {
    
    func setupView() {
        if stripScrollView == nil {
            stripScrollView = UIScrollView()
            stripScrollView?.showsVerticalScrollIndicator = false
            stripScrollView?.showsHorizontalScrollIndicator = false
            addSubview(stripScrollView!)
        }
        
        // Init and configure layout for sub views
        setupSubViews()
        
        // Need to update constraints
        setNeedsUpdateConstraints()
    }
    
    // Setup button views
    func setupSubViews() {
        // Get number of button
        let numberOfViews = delegate?.numberOfItems(self) ?? 0
        
        // If the delegate is not configured, stop the setting up process.
        guard let delegate = delegate else { return }
        
        // Init focusView
        if highlightView == nil {
            highlightView = delegate.getFocusView(self)
            
            // Disable interaction on view
            highlightView?.userInteractionEnabled = false
        }
        
        // Init views
        if itemViews == nil {
            
            itemViews = [UIButton]()
            for index in 0..<numberOfViews {
                let itemView = delegate.getButtonView(self, index: index)
                itemView.tag = index
                itemView.addTarget(self, action: #selector(buttonAction), forControlEvents: .TouchUpInside)
                
                
                // Keep the views on array
                itemViews?.append(itemView)
                
                // Add to scrollViews
                stripScrollView?.addSubview(itemView)
            }
            
            // The supper view need to be added above buttons
            highlightView?.removeFromSuperview()
            stripScrollView?.addSubview(highlightView!)
        }
        
        // Highlight selected item after setup views
        highlightSelectedItem()
    }
    
    /**
     Clear buttons
     */
    func clearButtons() {
        guard let itemViews = itemViews else { return }
        for itemView in itemViews {
            itemView.removeFromSuperview()
        }
        self.itemViews = nil
    }
    
    /**
     Setup constraints for animating
     */
    func configConstraintsForAnimatingFocusView(baseView: UIView?) {
        guard let baseView = baseView else { return }
        if let _ = focusViewWidthConstraint { return }
        
        // Reset constraint without width constraint
        configConstraintsForFocusView(false)
        
        if let stripScrollView = stripScrollView, highlightView = highlightView {
            
            // Custom width constraint to make it animatable
            focusViewWidthConstraint = NSLayoutConstraint(item: highlightView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: baseView.bounds.size.width)
            highlightView.addConstraint(focusViewWidthConstraint!)
            
            // Custom left constraint to make it animatable
            focusViewLeftConstraint = NSLayoutConstraint(item: highlightView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: stripScrollView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: baseView.frame.origin.x)
            stripScrollView.addConstraint(focusViewLeftConstraint!)
        }
    }
    
    /**
     Setup constraints to focusView
     */
    func configConstraintsForFocusView(includeLeftWidth: Bool) {
        // Reset constraint without width constraint
        guard let highlightView = highlightView else { return }
        
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        
        highlightView.removeConstraints(highlightView.constraints)
        
        // Top constraint
        for constraint in self.constraints {
            if constraint.firstItem as? UIView ?? nil == highlightView && constraint.secondItem as? UIView ?? nil == self && constraint.firstAttribute == NSLayoutAttribute.Top {
                self.removeConstraint(constraint)
            }
        }
        let topConstraint = NSLayoutConstraint(item: highlightView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        self.addConstraint(topConstraint)
        
        // Bottom constraint
        for constraint in self.constraints {
            if constraint.firstItem as? UIView ?? nil == highlightView && constraint.secondItem as? UIView ?? nil == self && constraint.firstAttribute == NSLayoutAttribute.Bottom {
                self.removeConstraint(constraint)
            }
        }
        let bottomConstraint = NSLayoutConstraint(item: highlightView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        self.addConstraint(bottomConstraint)
        
        // Remove all old constraints
        if let stripScrollView = stripScrollView {
            
            for constraint in stripScrollView.constraints {
                if constraint.firstItem as? UIView ?? nil == highlightView && constraint.firstAttribute == NSLayoutAttribute.Left {
                    stripScrollView.removeConstraint(constraint)
                }
            }
            for constraint in stripScrollView.constraints {
                if constraint.firstItem as? UIView ?? nil == highlightView && constraint.firstAttribute == NSLayoutAttribute.Width {
                    stripScrollView.removeConstraint(constraint)
                }
            }
            
            // Left constraint
            // Do nothing if the itemViews is nil
            guard let itemViews = itemViews else { return }
            if currentItemIndex < itemViews.count ?? 0 && includeLeftWidth {
                
                let initialView = itemViews[currentItemIndex]
                
                // Width constraint
                // Left constraint
                for constraint in stripScrollView.constraints {
                    if constraint.firstItem as? UIView ?? nil == highlightView && constraint.firstAttribute == NSLayoutAttribute.Left {
                        stripScrollView.removeConstraint(constraint)
                    }
                }
                let leftConstraint = NSLayoutConstraint(item: highlightView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: initialView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: highlightViewMarginLeftRight)
                stripScrollView.addConstraint(leftConstraint)
                
                for constraint in stripScrollView.constraints {
                    if constraint.firstItem as? UIView ?? nil == highlightView && constraint.firstAttribute == NSLayoutAttribute.Width &&
                        constraint.secondItem as? UIView ?? nil == initialView && constraint.secondAttribute == NSLayoutAttribute.Width {
                        stripScrollView.removeConstraint(constraint)
                    }
                }
                let equalWidthConstraint = NSLayoutConstraint(item: highlightView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: initialView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: -highlightViewMarginLeftRight * 2)
                stripScrollView.addConstraint(equalWidthConstraint)
            }
        }
    }
    
    func highlightSelectedItem() {
        if let itemViews = itemViews {
            delegate?.highlightItem(itemViews[focusedItemIndex], highlight: false)
            delegate?.highlightItem(itemViews[currentItemIndex], highlight: true)
        }
        focusedItemIndex = currentItemIndex
    }
    
    func makeHighlightViewVisible() {
        guard let stripScrollView = stripScrollView, highlightView = highlightView else { return }
        
        let scrollViewOffsetX = stripScrollView.contentOffset.x
        let focusViewWidth = highlightView.frame.size.width
        let highlightViewX = highlightView.frame.origin.x
        let stripScrollViewWidth = stripScrollView.bounds.size.width
        
        // Determine the focusView is visible on screen
        if highlightViewX < scrollViewOffsetX {
            // We need to scroll the stripView to show the focus view
            stripScrollView.setContentOffset(CGPointMake(highlightViewX - leftRightSpace, 0), animated: true)
        } else if highlightViewX + focusViewWidth > scrollViewOffsetX + stripScrollViewWidth {
            // We need to scroll the stripView to show the focus view
            stripScrollView.setContentOffset(CGPointMake(highlightViewX - stripScrollViewWidth + focusViewWidth + leftRightSpace, 0), animated: true)
        } else {
            // It's ok, the focusView is visible on screen.
        }
        
        // Update status for item views
        highlightSelectedItem()
    }
}

// MARK: Host scrollView's delegate
extension StripView {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        // Calculate progress of scrollView
        let offsetX = scrollView.contentOffset.x % scrollView.bounds.size.width
        var progress = offsetX / scrollView.bounds.size.width
        let currentIndex = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        progress = CGFloat(currentIndex) + progress
        
        // Find view index
        let itemViewIndex = Int(progress)
        
        // Get view which the focusView's left margin value will based on
        guard let itemView = itemViews?[itemViewIndex] else { return }
        
        // The left margin value for focusView will based on the base button index(the button on left) and the next button on right.
        var _nextItemView: UIView?
        if itemViewIndex + 1 < itemViews?.count ?? 0 {
            _nextItemView = itemViews?[itemViewIndex + 1]
        } else {
            _nextItemView = itemViews?.last
        }
        guard let nextItemView = _nextItemView else { return }
        
        // progress >= 0: it means the button will not move to left over the first button.
        // buttonIndex + 1 <= buttons?.count ?? 0: it means the button will not move to right over the last button.
        if progress >= 0 && itemViewIndex + 1 <= itemViews?.count ?? 0 {
            
            // The distance between the left & right buttons
            let itemDistance = nextItemView.frame.origin.x - itemView.frame.origin.x
            
            // The difference in width of left & right buttons
            let deltaWidth = nextItemView.frame.size.width - itemView.frame.size.width
            
            // The actual percent for moving between 2 buttons. Example: the progress is 3.5, it means the focused button is 3 or 4, and the focused button will move to 4 or 3. So the moving percent will be 0.5, not the 3.5.
            let percent = progress - CGFloat(Int(progress))
            
            // The left margin for focusView, it's based on the left button and the value of moving with right button.
            let offset = itemView.frame.origin.x + itemDistance * percent
            
            // The destination width of focus view.
            let width = itemView.frame.size.width + deltaWidth * percent
            
            // On the first time, we need to resetup the constraint for focusView. The focusView is initialized the constraints with left & width is the same with the initial button. But we could not use these constraints to do animation. So we have to remove these constraints by clearing & updating new constraints for focusView. The width & left margin constrains will be configured manually.
            configConstraintsForAnimatingFocusView(itemView)
            
            // Update the constraint to change width & left margin for focusView
            if let widthConstraint = focusViewWidthConstraint {
                
                // Update new width for focusView
                widthConstraint.constant = width - (highlightViewMarginLeftRight * 2)
            }
            if let leftConstraint = focusViewLeftConstraint {
                
                // Update new left margin for focusView
                leftConstraint.constant = offset + highlightViewMarginLeftRight
            }
        }
        
        // Redraw highlight view
        highlightView?.setNeedsDisplay()
        
        // Update current item index
        currentItemIndex = itemViewIndex
        
        // Forward callback to proxy
        scrollViewProxyDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) { // any zoom scale changes
        scrollViewProxyDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    // called on start of dragging (may require some time and or distance to move)
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollViewProxyDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    // called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewProxyDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    // called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewProxyDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) { // called on finger up as we are moving
        scrollViewProxyDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    /**
     Handle end scrolling for host scroll view to update stripView offset
     */
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Scroll the stripScrollView to show highlight view
        makeHighlightViewVisible()
        
        // Forward callback to proxy
        scrollViewProxyDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) { // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
        
        // Scroll the stripScrollView to show highlight view
        makeHighlightViewVisible()
        
        // Forward callback to proxy
        scrollViewProxyDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? { // return a view that will be scaled. if delegate returns nil, nothing happens
        return scrollViewProxyDelegate?.viewForZoomingInScrollView?(scrollView)
    }
    
    public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) { // called before the scroll view begins zooming its content
        scrollViewProxyDelegate?.scrollViewWillBeginZooming?(scrollView, withView: view)
    }
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) { // scale between minimum and maximum. called after any 'bounce' animations
        scrollViewProxyDelegate?.scrollViewDidEndZooming?(scrollView, withView: view, atScale: scale)
    }
    
    public func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool { // return a yes if you want to scroll to the top. if not defined, assumes YES
        return scrollViewProxyDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true // Default is YES
    }
    
    public func scrollViewDidScrollToTop(scrollView: UIScrollView) { // called when scrolling animation finished. may be called immediately if already at top
        scrollViewProxyDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
}

// MARK: Button actions
extension StripView {
    
    func buttonAction(sender: UIButton) {
        let buttonIndex = sender.tag
        delegate?.didSelectOnViewAtIndex(self, buttonIndex: buttonIndex)
        
        // Update current item index
        currentItemIndex = buttonIndex
        
        print("cointnet size: ", stripScrollView?.contentSize.width)
        print("frame: ", stripScrollView?.frame)
    }
}
