//
//  ViewModel.swift
//  testARkit
//
//  Created by Антон Шарин on 25.04.2023.
//

import Foundation
import UIKit

protocol viewModelToView : AnyObject {
    func addImage(image : UIImage)
}

final class ViewModel {
    
    
    let network = NetworkService()
    
    weak var delegate : viewModelToView?
    
    func loadImage() {
        network.downloadImage { result in
            switch result{
            case .success(let data):
                guard let image = UIImage(data: data) else {return}
                self.delegate?.addImage(image: image)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private let colors : [UIColor] = [.red,.blue,.green,.systemPink,.yellow]
    
    func giveColor() -> UIColor {
        colors.randomElement()!
    }
}
