//
//  Model.swift
//  testARkit
//
//  Created by Антон Шарин on 27.04.2023.
//

import Foundation
import UIKit



final class NetworkService{
    let url = URL(string: "https://mix-ar.ru/content/ios/marker.jpg")!
    
    
    func downloadImage(completion: @escaping (Result<Data,Error>)-> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                completion(.failure(error!))
              // handle error
              return
           }
           guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
              // handle error
              return
           }
           if let data = data {
              // process data
               completion(.success(data))
           }
        }
        task.resume()
    }
    
    
   
}
