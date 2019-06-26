//
//  flickrClient.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/26/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import Foundation
import UIKit
import MapKit


class FlickrClient {
    
    static let apiKey = "87d4cb89b846d8ed8d4faea0e68d7ff2"
    
    static let apiSecret = "af4c3a34d18b71e1"
    
    static let base = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key="
    
    enum Error: Swift.Error {
        case unknownAPIResponse
        case generic
    }
    
    class func searchFlickr(geopinLatitudeSearch: String, geopinLongitudeSearch: String, geopinLatitudeSearchMax: String, geopinLongitudeSearchMax: String, completion: @escaping (Result<FlickrPinResults>) -> Void) {
        guard let searchURL = FlickrClient.flickrSearchURL(geopinlatitude: geopinLatitudeSearch, geopinlongitude: geopinLongitudeSearch, geopinlongitudemax: geopinLongitudeSearchMax, geopinlatitudemax: geopinLatitudeSearchMax) else {
            completion(Result.error(Error.unknownAPIResponse))
            return
        }
        
        let searchRequest = URLRequest(url: searchURL)
        
        URLSession.shared.dataTask(with: searchRequest) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(Result.error(error))
                }
                return
            }
            
            guard
                let _ = response as? HTTPURLResponse,
                let data = data
                else {
                    DispatchQueue.main.async {
                        completion(Result.error(Error.unknownAPIResponse))
                    }
                    return
            }
            
            do {
                guard
                    let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
                    let stat = resultsDictionary["stat"] as? String
                    else {
                        DispatchQueue.main.async {
                            completion(Result.error(Error.unknownAPIResponse))
                        }
                        return
                }
                
                switch (stat) {
                case "ok":
                    print("Results processed OK")
                case "fail":
                    DispatchQueue.main.async {
                        completion(Result.error(Error.generic))
                    }
                    return
                default:
                    DispatchQueue.main.async {
                        completion(Result.error(Error.unknownAPIResponse))
                    }
                    return
                }
                
                guard
                    let photosContainer = resultsDictionary["photos"] as? [String: AnyObject],
                    let photosReceived = photosContainer["photo"] as? [[String: AnyObject]]
                    else {
                        DispatchQueue.main.async {
                            completion(Result.error(Error.unknownAPIResponse))
                        }
                        return
                }
                
                let flickrPhotos: [FlickrPhoto] = photosReceived.compactMap { photoObject in
                    guard
                        let photoID = photoObject["id"] as? String,
                        let farm = photoObject["farm"] as? Int ,
                        let server = photoObject["server"] as? String ,
                        let secret = photoObject["secret"] as? String
                        else {
                            return nil
                    }
                    
                    let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
                    return flickrPhoto
                }
                
                let searchResults = FlickrPinResults(geoPinLongitude: geopinLongitudeSearch, geoPinLatitude: geopinLatitudeSearch, searchResults: flickrPhotos)
                DispatchQueue.main.async {
                    completion(Result.results(searchResults))
                }
            } catch {
                completion(Result.error(error))
                return
            }
            }.resume()
    }
    
    
    class func flickrSearchURL(geopinlatitude: String, geopinlongitude: String, geopinlongitudemax: String, geopinlatitudemax: String) -> URL? {
        
        //Random number for page
        let number = Int.random(in: 1...20)
        
        let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FlickrClient.apiKey)&bbox=\(geopinlongitude)%2C\(geopinlatitude)%2C\(geopinlongitudemax)%2C\(geopinlatitudemax)&page=\(number)&per_page=30&format=json&nojsoncallback=1"
        print(URLString)
        return URL(string:URLString)
        
    }
}
