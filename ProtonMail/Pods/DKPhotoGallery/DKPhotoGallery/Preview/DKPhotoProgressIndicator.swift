//
//  DKPhotoProgressIndicator.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 08/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

class DKPhotoProgressIndicator: UIView, DKPhotoProgressIndicatorProtocol {
    
    private var progress: Float = 0
    
    required init(with view: UIView) {
        super.init(frame: view.bounds)
        
        view.addSubview(self)
        
        self.isHidden = true
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let lineWidth = CGFloat(2.0)
        let circleDiameter = CGFloat(37)
        let circleRect = CGRect(x: (self.bounds.width - circleDiameter) / 2, y: (self.bounds.height - circleDiameter) / 2,
                             width: circleDiameter,
                             height: circleDiameter)
        
        UIColor.white.setStroke()
        
        context.setLineWidth(lineWidth)
        context.strokeEllipse(in: circleRect)        
        
        let processPath = UIBezierPath()
        processPath.lineCapStyle = .butt
        processPath.lineWidth = lineWidth * 2
        
        let radius = circleDiameter / 2 - lineWidth / 2
        
        let startAngle = -CGFloat.pi / 2.0
        let endAngle = CGFloat(self.progress) * CGFloat(2.0) * CGFloat.pi + startAngle
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        context.setBlendMode(.copy)
        
        UIColor.white.set()
        
        processPath.stroke()
    }
    
    // MARK: - DKPhotoProgressIndicatorProtocol
    
    func startIndicator() {
        self.progress = 0
        self.isHidden = false
    }
    
    func stopIndicator() {
        self.isHidden = true
    }
    
    func setIndicatorProgress(_ progress: Float) {
        self.progress = progress
        
        self.setNeedsDisplay()
    }
}
