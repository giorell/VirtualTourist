//
//  ImagesLoader.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/24/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import UIKit

class ImagesLoader: NSObject {
    static func loadImage(imageUrl: String, handler: @escaping (_ data: Data?) -> Void ) {
        let task = URLSession.shared.dataTask(with: URL(string: imageUrl)!) { data, response, error in
            DispatchQueue.main.async {
                if error == nil {
                    handler(data)
                } else {
                    handler(nil)
                }
            }
        }
        task.resume()
    }
}
