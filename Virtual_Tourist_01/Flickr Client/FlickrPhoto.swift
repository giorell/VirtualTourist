//
//  FlickrPhoto.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/29/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import Foundation
import UIKit

class FlickrPhoto: Equatable {
    var thumbnail: UIImage?
    var largeImage: UIImage?
    let photoID: String
    let farm: Int
    let server: String
    let secret: String
    var imageURL: String?
    
    init (photoID: String, farm: Int, server: String, secret: String) {
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
    }
    
    func flickrImageURLString(_ size: String = "m") -> String? {
        return ("https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg")
    }
    
    func flickrImageURL(_ size: String = "m") -> URL? {
        if let url =  URL(string: flickrImageURLString(size)!) {
            self.imageURL = url.absoluteString
            return url
        }
        return nil
    }
    
    enum Error: Swift.Error {
        case invalidURL
        case noData
    }
    
    func loadLargeImage(_ completion: @escaping (Result<FlickrPhoto>) -> Void) {
        guard let loadURL = flickrImageURL("b") else {
            DispatchQueue.main.async {
                completion(Result.error(Error.invalidURL))
            }
            return
        }
        
        let loadRequest = URLRequest(url:loadURL)
        
        URLSession.shared.dataTask(with: loadRequest) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(Result.error(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(Result.error(Error.noData))
                }
                return
            }
            
            let returnedImage = UIImage(data: data)
            self.largeImage = returnedImage
            DispatchQueue.main.async {
                completion(Result.results(self))
            }
            }.resume()
    }
    
    func sizeToFillWidth(of size:CGSize) -> CGSize {
        guard let thumbnail = thumbnail else {
            return size
        }
        
        let imageSize = thumbnail.size
        var returnSize = size
        
        let aspectRatio = imageSize.width / imageSize.height
        
        returnSize.height = returnSize.width / aspectRatio
        
        if returnSize.height > size.height {
            returnSize.height = size.height
            returnSize.width = size.height * aspectRatio
        }
        
        return returnSize
    }
    
    static func ==(lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
        return lhs.photoID == rhs.photoID
    }
}
