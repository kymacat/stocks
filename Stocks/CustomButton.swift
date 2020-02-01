//
//  CustomButton.swift
//  Stocks
//
//  Created by Const. on 01.02.2020.
//  Copyright © 2020 Oleginc. All rights reserved.
//

import UIKit

class CustomButton : UIButton {
    var color: UIColor = .black
    let touchDownAlpha: CGFloat = 0.3

    func setup() {
        backgroundColor = .clear
        layer.backgroundColor = color.cgColor

        layer.cornerRadius = 15
        clipsToBounds = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let backgroundColor = backgroundColor {
            color = backgroundColor
        }
        
        setup()
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                touchDown()
            } else {
                cancelTracking(with: nil)
                touchUp()
            }
        }
    }
    
    weak var timer: Timer?

    func stopTimer() {
        timer?.invalidate()
    }

    deinit {
        stopTimer()
    }

    func touchDown() {
        stopTimer()
        layer.backgroundColor = color.withAlphaComponent(touchDownAlpha).cgColor
    }

    let timerStep: TimeInterval = 0.01
    let animateTime: TimeInterval = 0.4
    lazy var alphaStep: CGFloat = {
        return (1 - touchDownAlpha) / CGFloat(animateTime / timerStep)
    }()

    func touchUp() {
        timer = Timer.scheduledTimer(timeInterval: timerStep,
                                     target: self,
                                     selector: #selector(animation),
                                     userInfo: nil,
                                     repeats: true)
    }

    @objc func animation() {
        guard let backgroundAlpha = layer.backgroundColor?.alpha else {
            stopTimer()

            return
        }

        let newAlpha = backgroundAlpha + alphaStep

        if newAlpha < 1 {
            layer.backgroundColor = color.withAlphaComponent(newAlpha).cgColor
        } else {
            layer.backgroundColor = color.cgColor

            stopTimer()
        }
    }
}
