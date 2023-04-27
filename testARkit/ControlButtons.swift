//
//  ControlButtons.swift
//  testARkit
//
//  Created by Антон Шарин on 25.04.2023.
//

import Foundation
import UIKit


protocol ControlToScene : AnyObject {
    func pressedLeft(gesture:UIGestureRecognizer)
    func pressedUp(gesture:UIGestureRecognizer)
    func pressedRight(gesture:UIGestureRecognizer)
    func pressedDown(gesture:UIGestureRecognizer)

}

final class ControlButton : UIView {
    
    weak var delegate : ControlToScene?
    
    private let leftButton : UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.setImage(UIImage(systemName: "arrow.left"), for: .normal)

        button.backgroundColor = .red
        return button
    }()
    
    private let rightButton : UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)

        button.backgroundColor = .red
        return button
    }()
    
    private let upButton : UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        button.backgroundColor = .red
        return button
    }()
    
    private let downButton : UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.setImage(UIImage(systemName: "arrow.down"), for: .normal)

        button.backgroundColor = .red
        return button
    }()
    
    
    
    
    
    
    func setup() {
        [leftButton,upButton,rightButton,downButton].forEach { element in
            addSubview(element)
        }
        setupConstraints()
        
        
        leftButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(leftButtonAction(gesture:))))
        rightButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(rightButtonAction(gesture:))))
        upButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(upButtonAction(gesture:))))
        downButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(downButtonAction(gesture:))))
        
      

        
    }
    
    private func setupConstraints() {
        [leftButton,upButton,rightButton,downButton].forEach { element in
            element.translatesAutoresizingMaskIntoConstraints = false
        }
        
        
        NSLayoutConstraint.activate([
            
            leftButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            leftButton.heightAnchor.constraint(equalToConstant: 70),
            leftButton.widthAnchor.constraint(equalToConstant: 70),
            
            upButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            upButton.topAnchor.constraint(equalTo: self.topAnchor),
            upButton.heightAnchor.constraint(equalToConstant: 70),
            upButton.widthAnchor.constraint(equalToConstant: 70),
            
            rightButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            rightButton.heightAnchor.constraint(equalToConstant: 70),
            rightButton.widthAnchor.constraint(equalToConstant: 70),
            
            downButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            downButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            downButton.heightAnchor.constraint(equalToConstant: 70),
            downButton.widthAnchor.constraint(equalToConstant: 70),
            
            ])
    }
    
    
    
    
    
    
    @objc private func leftButtonAction(gesture : UIGestureRecognizer) {
        delegate?.pressedLeft(gesture : gesture)
    }
    @objc private func rightButtonAction(gesture : UIGestureRecognizer) {
        delegate?.pressedRight(gesture : gesture)
    }
    @objc private func upButtonAction(gesture : UIGestureRecognizer) {
        delegate?.pressedUp(gesture : gesture)
    }
    @objc private func downButtonAction(gesture : UIGestureRecognizer) {
        delegate?.pressedDown(gesture : gesture)
    }
}
