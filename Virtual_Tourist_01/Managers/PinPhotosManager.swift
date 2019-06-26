//
//  PinPhotosManager.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/24/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import UIKit
import CoreData

class PinPhotosManager: NSObject {
    
    static let shared = PinPhotosManager()
    
    // MARK: - Public properties
    var sharedContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func addPhoto(_ photo: FlickrPhoto, mapPin: Pin) {
        
        // Add coredata info to photo, then save to SharedContext
        
        let photoToAdd = Photo(context: sharedContext)
        photoToAdd.id = photo.photoID
        photoToAdd.pin = mapPin
        photoToAdd.imageData = photo.largeImage?.pngData()
        photoToAdd.imageURL = photo.flickrImageURLString()
    }
    
    func addPhotos(_ photos: [FlickrPhoto], mapPin: Pin) {
        
        //batch save photos
        for photo in photos {
            addPhoto(photo, mapPin: mapPin)
        }
    }
    
    func save(_ handler: ((String?) -> Void)?) {
        do {
            // Save Managed Object Context
            print("Saved Success")
            try sharedContext.save()
            handler?(nil)
        } catch {
            handler?(error.localizedDescription)
        }
    }
    
    func deleteFromMemory(_ photo: Photo) {
        sharedContext.delete(photo)
    }
    
    func deleteFromPhotos(_ photos: [Photo]) {
        for photo in photos {
            deleteFromMemory(photo)
        }
    }
}
