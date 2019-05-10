//
//  ViewController.swift
//  InteractiveAnimations
//
//  Created by Pankaj kumar on 08/05/19.
//  Copyright © 2019 Pankaj kumar. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

private enum State {
    case closed
    case open
}

extension State {
    var opposite: State {
        switch self {
        case .open:
            return .closed
        case .closed:
            return .open
        }
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak private var contentImageView: UIImageView!
    @IBOutlet weak private var overlayView: UIView!
    @IBOutlet weak private var popupView: UIView!
    @IBOutlet weak private var closedTitleLabel: UILabel!
    @IBOutlet weak private var openTitleLabel: UILabel!
    @IBOutlet weak var popupHeight: NSLayoutConstraint!
    
    private var currentState: State = .closed
    private let popupOffset: CGFloat = 440.0
    private var transitionAnimator = UIViewPropertyAnimator()
    private var animationProgress = CGFloat()

    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.addGestureRecognizer(panRecognizer)
        addShadow(view: popupView)
    }
    
    private func addShadow(view: UIView) {
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 10
    }

    private lazy var panRecognizer: InstantPanGestureRecognizer = {
        let recognizer = InstantPanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(popupViewPanned(recognizer:)))
        return recognizer
    }()
    
    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        let state = currentState.opposite
        transitionAnimator = UIViewPropertyAnimator(duration: 1, dampingRatio: 1, animations: {
            switch state {
            case .open:
                self.popupHeight.constant = 60.0 + self.popupOffset
                self.popupView.layer.cornerRadius = 20
                self.overlayView.alpha = 0.5
                self.closedTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 15))
                self.openTitleLabel.transform = .identity
                self.openTitleLabel.alpha = 1
                self.closedTitleLabel.alpha = 0
            case .closed:
                self.popupHeight.constant = 60.0
                self.popupView.layer.cornerRadius = 0
                self.overlayView.alpha = 0
                self.closedTitleLabel.transform = .identity
                self.openTitleLabel.transform = CGAffineTransform(scaleX: 0.65, y: 0.65).concatenating(CGAffineTransform(translationX: 0, y: -15))
                self.openTitleLabel.alpha = 0
                self.closedTitleLabel.alpha = 1
            }
            self.view.layoutIfNeeded()
        })
        transitionAnimator.addCompletion { position in
            switch position {
            case .start:
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current:
                ()
            @unknown default:
                print("some error occured")
            }
            switch self.currentState {
            case .open:
                self.popupHeight.constant = 60.0 + self.popupOffset
            case .closed:
                self.popupHeight.constant = 60.0
            }
        }
        transitionAnimator.startAnimation()
    }
   
    @objc private func popupViewPanned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            animateTransitionIfNeeded(to: currentState.opposite, duration: 1.5)
            animationProgress = transitionAnimator.fractionComplete
            transitionAnimator.pauseAnimation()
        case .changed:
            let translation = recognizer.translation(in: popupView)
            var fraction = -translation.y / popupOffset
            if currentState == .open { fraction *= -1 }
            if transitionAnimator.isReversed { fraction *= -1 }
            transitionAnimator.fractionComplete = fraction + animationProgress
        case .ended:
            let yVelocity = recognizer.velocity(in: popupView).y
            let shouldClose = yVelocity > 0
            if yVelocity == 0 {
                transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            switch currentState {
            case .open:
                if !shouldClose && !transitionAnimator.isReversed { transitionAnimator.isReversed = !transitionAnimator.isReversed }
                if shouldClose && transitionAnimator.isReversed { transitionAnimator.isReversed = !transitionAnimator.isReversed }
            case .closed:
                if shouldClose && !transitionAnimator.isReversed { transitionAnimator.isReversed = !transitionAnimator.isReversed }
                if !shouldClose && transitionAnimator.isReversed { transitionAnimator.isReversed = !transitionAnimator.isReversed }
            }
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        default:
            ()
        }
    }
    
}

class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if (self.state == UIGestureRecognizer.State.began) { return }
        super.touchesBegan(touches, with: event)
        self.state = UIGestureRecognizer.State.began
    }
}
