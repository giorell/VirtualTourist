//
//  Pin+Extension.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/22/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import Foundation
import CoreData
import MapKit

//@objc(Pin)

extension Pin: MKAnnotation {
    
    convenience init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)
        self.init(entity: entity!, insertInto: context)
        self.longitude = annotationLongitude
        self.latitude = annotationLatitude
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
}
