//
//  OvalButton.swift
//  DotphotonConvert
//
//  Created by Christoph Clausen on 02.03.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Cocoa

@IBDesignable
class StartButton: NSControl, NibLoadableView {
    
    enum StartButtonState {
        case Stopped
        case Running
    }
    
    @IBOutlet var view: NSView!
    
    @IBOutlet weak var startBox: NSBox!
    @IBOutlet var doneCircle: NSView!
    @IBOutlet var pauseCircle: NSView!
    @IBOutlet var blurBox: NSBox!
    
    private let bgColor = NSColor.Theme.windowBackground
    private var trackingArea: NSTrackingArea?
    
    private(set) var state:StartButtonState = .Stopped
    private let progressLayer = CAShapeLayer()
    
    var progress: CGFloat = 0.01 {
        didSet {
            progressLayer.strokeEnd = progress
            if progress >= 1 {
                self.animateDone()
                self.state = .Stopped
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if !isEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + (state == .Running ? 1 : 0), execute: { self.addBlurBox() })
            } else {
                blurBox.removeFromSuperview()
            }
        }
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setupFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupFromNib()
        setup()
    }
    
    fileprivate func setup() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
        
        addSubview(pauseCircle, positioned: .below, relativeTo: view)
        addSubview(doneCircle, positioned: .above, relativeTo: view)
        
        for subview in [view, doneCircle, pauseCircle] {
            subview?.wantsLayer = true
            subview?.layerContentsRedrawPolicy = .onSetNeedsDisplay
            subview?.frame = bounds
            if let frame = subview?.layer?.frame {
                subview?.layer?.position = CGPoint(x: frame.midX, y:frame.midY)
                subview?.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            }
        }
        
        setupPauseLayer()
        setupProgressLayer()
        setupDoneLayer()
    }
    
    fileprivate func addBlurBox() {
        addSubview(blurBox, positioned: .above, relativeTo: doneCircle)
        blurBox.frame.size.width = bounds.width + 10
        blurBox.frame.size.height = bounds.height + 10
        blurBox.frame.origin.x = -5
        blurBox.frame.origin.y = -5
    }
    
    fileprivate func setupPauseLayer() {
        let pauseLayer = CAShapeLayer()
        pauseLayer.frame = pauseCircle.bounds
        pauseLayer.strokeColor = NSColor.Theme.pauseCircle.cgColor
        pauseLayer.fillColor = NSColor.clear.cgColor
        pauseLayer.lineWidth = 8
        pauseLayer.lineDashPattern = [0.01, NSNumber(value: Float(pauseLayer.lineWidth * 2))]
        pauseLayer.lineCap = CAShapeLayerLineCap.round
        var frame = pauseLayer.frame
        frame.origin.x += pauseLayer.lineWidth/2
        frame.origin.y += pauseLayer.lineWidth/2
        frame.size.width -= pauseLayer.lineWidth
        frame.size.height -= pauseLayer.lineWidth
        pauseLayer.path = NSBezierPath(ovalIn: frame).cgPath
        pauseCircle.layer = pauseLayer
        
        let lineDashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        lineDashAnimation.fromValue = 0
        lineDashAnimation.toValue = pauseLayer.lineDashPattern?.reduce(0) { $0 - $1.intValue }
        lineDashAnimation.duration = 1
        lineDashAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        pauseLayer.add(lineDashAnimation, forKey: nil)
        pauseLayer.opacity = 0
    }
    
    fileprivate func setupProgressLayer() {
        progressLayer.frame = pauseCircle.bounds
        progressLayer.strokeColor = NSColor.Theme.buttonBlue.cgColor
        progressLayer.fillColor = NSColor.clear.cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = CAShapeLayerLineCap.round
        var frame = progressLayer.frame
        frame.origin.x += progressLayer.lineWidth/2
        frame.origin.y += progressLayer.lineWidth/2
        frame.size.width -= progressLayer.lineWidth
        frame.size.height -= progressLayer.lineWidth
        let arc = NSBezierPath()
        arc.appendArc(withCenter: CGPoint(x: frame.midX, y: frame.midY), radius: frame.midX - progressLayer.lineWidth / 2,
                      startAngle: 90, endAngle: 91, clockwise: true)
        progressLayer.path = arc.cgPath
        progressLayer.strokeEnd = 0.01
        pauseCircle.layer?.addSublayer(progressLayer)
    }
    
    fileprivate func setupDoneLayer() {
        doneCircle.layer?.opacity = 0
        doneCircle.layer?.transform = CATransform3DMakeScale(0.01, 0.01, 1)
    }
    
    override func updateTrackingAreas() {
        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return NSPointInRect(point, frame) && isEnabled ? self : nil
    }
    
    override func mouseDown(with event: NSEvent) {
        if state == .Stopped {
            animateShrink(startBox)
        } else {
            animateShrink(pauseCircle)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if state == .Stopped {
            if bounds.contains(point) {
                start()
                if let action = action {
                    NSApp.sendAction(action, to: target, from: self)
                }
            } else {
                animateRestore(startBox)
            }
        } else {
            animateRestore(pauseCircle)
            if bounds.contains(point) {
                state = .Stopped
                if let action = action {
                    NSApp.sendAction(action, to: target, from: self)
                }
            }
        }
    }
    
    func stop() {
        animatePause()
    }
    
    func start() {
        state = .Running
        progress = 0.01
        animateMouseUpInside()
    }
    
    func animateShrink(_ view: NSView) {
        if let frame = view.layer?.frame {
            view.layer?.position = CGPoint(x: frame.midX, y:frame.midY)
            view.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 0.9
        scale.duration = 0.1
        view.layer?.add(scale, forKey: nil)
        view.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1)
    }
    
    fileprivate func animateRestore(_ view: NSView) {
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.9
        scale.toValue = 1.0
        scale.duration = 0.1
        view.layer?.add(scale, forKey: nil)
        view.layer?.transform = CATransform3DIdentity
    }
    
    fileprivate func animateMouseUpInside() {
        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [0.9, 1, 0]
        scale.keyTimes = [0, 0.33, 1]
        scale.duration = 0.75
        startBox.layer?.add(scale, forKey: nil)
        startBox.layer?.transform = CATransform3DMakeScale(0, 0, 1)
        
        pauseCircle.layer?.opacity = 1
        let fadeIn = CAKeyframeAnimation(keyPath: "opacity")
        fadeIn.values = [0, 1]
        fadeIn.keyTimes = [0.66, 1]
        fadeIn.duration = 0.75
        fadeIn.fillMode = CAMediaTimingFillMode.backwards
        pauseCircle.layer?.add(fadeIn, forKey: nil)
    }
    
    fileprivate func animateDone() {
        let duration: CFTimeInterval = 0.3
        
        doneCircle.layer?.opacity = 1
        if let frame = view.layer?.frame {
            doneCircle.layer?.position = CGPoint(x: frame.midX, y:frame.midY)
            doneCircle.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0
        scale.toValue = 1
        scale.duration = duration
        scale.fillMode = CAMediaTimingFillMode.forwards
        doneCircle.layer?.add(scale, forKey: nil)
        doneCircle.layer?.transform = CATransform3DIdentity
        
        
        pauseCircle.layer?.opacity = 0
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.duration = duration
        fadeOut.fillMode = CAMediaTimingFillMode.backwards
        pauseCircle.layer?.add(fadeOut, forKey: nil)
        
        startBox.layer?.transform = CATransform3DIdentity
        startBox.layer?.opacity = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.doneCircle.layer?.opacity = 0
            let fadeOut = CABasicAnimation(keyPath: "opacity")
            fadeOut.fromValue = 1
            fadeOut.toValue = 0
            fadeOut.duration = duration
            fadeOut.fillMode = CAMediaTimingFillMode.backwards
            self.doneCircle.layer?.add(fadeOut, forKey: nil)
            
            self.startBox.layer?.opacity = 1
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue = 1
            fadeIn.duration = duration
            fadeIn.fillMode = CAMediaTimingFillMode.backwards
            self.startBox.layer?.add(fadeIn, forKey: nil)
        }
    }
    
    fileprivate func animatePause() {
        let duration: CFTimeInterval = 0.3
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0
        scale.toValue = 1
        scale.duration = duration
        scale.fillMode = CAMediaTimingFillMode.forwards
        startBox.layer?.add(scale, forKey: nil)
        startBox.layer?.transform = CATransform3DIdentity
        
        pauseCircle.layer?.opacity = 0
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.duration = duration
        fadeOut.fillMode = CAMediaTimingFillMode.backwards
        pauseCircle.layer?.add(fadeOut, forKey: nil)
    }
}
