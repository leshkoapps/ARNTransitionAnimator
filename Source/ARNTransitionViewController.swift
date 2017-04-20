//
//  SoundCloudTransitionViewController.swift
//  ARNTransitionAnimator
//
//  Created by Artem Meleshko on 12/29/15.
//  Copyright © 2015 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit



@objc public class ARNTransitionViewController: UIViewController {
    
    
    public enum ARNOverlayViewControllerState: Int {
        case unknown
        case presenting
        case presented
        case dismissing
        case dismissed
    }
    
    @objc public enum ARNOverlayViewControllerInitialState: Int {
        case dismissed
        case presented
        case presentedWithAnimation
    }
    
    var animator : ARNTransitionAnimator!
    open var overlayState : ARNOverlayViewControllerState = .unknown
    public var overlayViewController : UIViewController!
    public var contentViewController : UIViewController!
    public var overlayViewControllerCanBePresented: Bool = false
    open var overlayViewControllerInitialState: ARNOverlayViewControllerInitialState = .dismissed
    @objc public var enableInteractiveGesture: Bool = true {
        didSet{
            if self.animator != nil  {
                self.animator.enableInteractiveGesture = self.enableInteractiveGesture
            }
        }
    }
    public weak var contentView : UIView!
    
    // handlers
    
    open var presentationBeforeHandler : ((_ containerView: UIView, _ transitionContext: UIViewControllerContextTransitioning) ->())?
    open var presentationAnimationHandler : ((_ containerView: UIView, _ percentComplete: CGFloat) ->())?
    open var presentationCancelAnimationHandler : ((_ containerView: UIView) ->())?
    open var presentationCompletionHandler : ((_ containerView: UIView, _ completeTransition: Bool) ->())?
    
    open var dismissalBeforeHandler : ((_ containerView: UIView, _ transitionContext: UIViewControllerContextTransitioning) ->())?
    open var dismissalAnimationHandler : ((_ containerView: UIView, _ percentComplete: CGFloat) ->())?
    open var dismissalCancelAnimationHandler : ((_ containerView: UIView) ->())?
    open var dismissalCompletionHandler : ((_ containerView: UIView, _ completeTransition: Bool) ->())?
    
    @objc public init(contentViewController: UIViewController!,overlayViewController:UIViewController!, overlayViewControllerInitialState:ARNOverlayViewControllerInitialState){
        super.init(nibName: nil, bundle: nil)
        self.contentViewController = contentViewController
        self.overlayViewController = overlayViewController
        self.overlayViewControllerInitialState = overlayViewControllerInitialState
        self.overlayState = .dismissed
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let cv : UIView = UIView(frame: self.view.bounds)
        cv.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.addSubview(cv)
        self.contentView = cv
        
        if self.contentViewController != nil && self.contentViewController.parent != self  {
            self.addChildViewController(self.contentViewController)
            self.contentViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            self.contentViewController.view.frame = self.contentView.bounds
            self.contentView.addSubview(self.contentViewController.view)
            self.contentViewController.didMove(toParentViewController: self)
        }
        
        self.overlayViewController.modalPresentationStyle = .custom
        
        self.setupAnimator()
 
    }
    
    open func setupOverlayControllerInitialState() {
        let shouldShowOverlayController : Bool = self.overlayViewControllerInitialState == .presentedWithAnimation || self.overlayViewControllerInitialState == .presented
        let animated : Bool = self.overlayViewControllerInitialState == .presentedWithAnimation
        if shouldShowOverlayController {
            showOverlayController(animated,completion: nil)
        }
        self.overlayViewControllerInitialState = .dismissed
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.animator.interactiveType = .present
        self.overlayViewControllerCanBePresented = true;
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.overlayViewControllerCanBePresented = false;
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.overlayViewControllerCanBePresented {
            setupOverlayControllerInitialState()
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @objc open func showOverlayController(_ animated: Bool, completion: (() -> Void)?) {
        assert(self.overlayViewControllerCanBePresented)
        self.animator.interactiveType = .none
        self.present(self.overlayViewController, animated: animated, completion: completion)
    }
    
    @objc open func hideOverlayController(_ animated: Bool, completion: (() -> Void)?) {
        self.dismiss(animated: animated, completion: completion)
    }
    
    func setupAnimator() {
        
        weak var weakSelf = self
        weak var weakOverlayController = self.overlayViewController
        self.animator = ARNTransitionAnimator(operationType: .present, fromVC: weakSelf!, toVC: weakOverlayController!)
        self.animator.enableInteractiveGesture = self.enableInteractiveGesture
        
        
        // Present
        self.animator.presentationBeforeHandler = { [weak self] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
            self!.overlayState = .presenting
            self!.presentationBeforeHandler?(containerView, transitionContext)
        }
        
        self.animator.presentationCancelAnimationHandler = { [weak self] (containerView: UIView) in
            self!.overlayState = .dismissed
            self!.presentationCancelAnimationHandler?(containerView)
        }
        
        self.animator.presentationAnimationHandler = { [weak self] (containerView: UIView, percentComplete: CGFloat) in
            self!.presentationAnimationHandler?(containerView, percentComplete)
        }
        
        self.animator.presentationCompletionHandler = { [weak self] (containerView: UIView, completeTransition: Bool) in
            self!.overlayState = .presented
            self!.presentationCompletionHandler?(containerView, completeTransition)
        }
        
        // Dismiss
        self.animator.dismissalBeforeHandler = { [weak self] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
            self!.overlayState = .dismissing
            self!.dismissalBeforeHandler?(containerView, transitionContext)
        }
        
        self.animator.dismissalCancelAnimationHandler = { [weak self] (containerView: UIView) in
            self!.overlayState = .presented
            self!.dismissalCancelAnimationHandler?(containerView)
        }
        
        self.animator.dismissalAnimationHandler = { [weak self] (containerView: UIView, percentComplete: CGFloat) in
            self!.dismissalAnimationHandler?(containerView, percentComplete)
        }
        
        self.animator.dismissalCompletionHandler = { [weak self] (containerView: UIView, completeTransition: Bool) in
            self!.overlayState = .dismissed
            self!.animator.interactiveType = .present
            self!.dismissalCompletionHandler?(containerView, completeTransition)
        }
        
        self.overlayViewController.transitioningDelegate = self.animator
    }
    
    open override var shouldAutorotate : Bool {
        return self.visibleViewController().shouldAutorotate
    }
    
    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return self.visibleViewController().supportedInterfaceOrientations
    }
    
    open override var edgesForExtendedLayout: UIRectEdge{
        get{
            return self.visibleViewController().edgesForExtendedLayout
        }
        set{
            self.visibleViewController().edgesForExtendedLayout = newValue
        }
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.visibleViewController().preferredStatusBarStyle
    }
    
    open override var prefersStatusBarHidden : Bool {
        return self.visibleViewController().prefersStatusBarHidden
    }
    
    open func visibleViewController() -> UIViewController {
        if self.overlayState == .presented || self.overlayState == .presenting {
            return self.overlayViewController
        }
        return self.contentViewController
    }
    
}
