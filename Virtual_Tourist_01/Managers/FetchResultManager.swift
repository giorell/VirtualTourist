//
//  FetchResultManager.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/24/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import UIKit
import CoreData

class FetchResultManager: NSObject {
    
    // MARK: - Public properties
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    // MARK: - Public funcs
    func resetFetchController(with pin: Pin) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        fetchRequest.resultType = .managedObjectResultType
        
        fetchedResultsController = nil
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PinPhotosManager.shared.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        fetchedResultsController.fetchRequest.predicate = predicate
    }
    
    func fetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
}
