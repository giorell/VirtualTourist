//
//  ViewController.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/22/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Oulets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    // MARK: - Private variables
    
    private var appDelegate: AppDelegate!
    private var sharedContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    // MARK: - Public variables
    
    var centerLat: CLLocationDegrees?
    var centerLong: CLLocationDegrees?
    var spanLat: CLLocationDegrees?
    var spanLong: CLLocationDegrees?
    
    let startLat: CLLocationDegrees = 34
    let startLong: CLLocationDegrees = -118
    let startSpanLat: CLLocationDegrees = 1
    let startSpanLong: CLLocationDegrees = 1

    // MARK: - View Controller Funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewDidLoad()
        
        mapView.addAnnotations(fetchAllPins())
        
        setupFetchedResultsController()
        
        mapLoader()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deletePinsLabel.isHidden = !editing
    }
    
    fileprivate func setupViewDidLoad() {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        sharedContext = appDelegate.persistentContainer.viewContext
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        deletePinsLabel.isHidden = true
        
        mapView.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        
        var location = sender.location(in: self.mapView)
        
        var locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        
        let annotation = MKPointAnnotation()
        
        if sender.state == .ended {
            
            // Save this PIN to CoreData
            
            mapView.removeAnnotation(annotation)
            
            location = sender.location(in: self.mapView)
            locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            annotation.coordinate = locCoord
            print(annotation.coordinate)
            annotation.title = "Pin"
            annotation.subtitle = "Click Me"
            
            print("saved pin")
            
            let pin = Pin(context: sharedContext!)
            pin.id = UUID().uuidString
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            try? sharedContext.save()
            mapView.addAnnotation(pin)
            
        }
    }
    
    // MARK: - Map Funcs
    
    func savePin(_ annotation: MKPointAnnotation ) {
        let pin = Pin(context: sharedContext!)
        pin.id = UUID().uuidString
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        try? sharedContext.save()
        mapView.addAnnotation(pin)
    }
    
    fileprivate func mapLoader() {
        
        // Load coordinates from User Defaults or else start coordinates near Los Angeles
        
        let centerLatitude: CLLocationDegrees? = appDelegate.mapDefaults.object(forKey: "centerLatitude") as? CLLocationDegrees
        let centerLongitude: CLLocationDegrees? = appDelegate.mapDefaults.object(forKey: "centerLongitude") as? CLLocationDegrees
        let spanLatitude: CLLocationDegrees? = appDelegate.mapDefaults.object(forKey: "spanLatitude") as? CLLocationDegrees
        let spanLongitude: CLLocationDegrees? = appDelegate.mapDefaults.object(forKey: "spanLongitude") as? CLLocationDegrees
        
        if centerLatitude == nil {
            
            let noLocation = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
            let locSpan = MKCoordinateSpan(latitudeDelta: startSpanLat, longitudeDelta: startSpanLong)
            let viewRegion = MKCoordinateRegion(center: noLocation, span: locSpan)
            
            mapView.setRegion(viewRegion, animated: false)
            
        } else {
            
            let noLocation = CLLocationCoordinate2D(latitude: centerLatitude!, longitude: centerLongitude!)
            let locSpan = MKCoordinateSpan(latitudeDelta: spanLatitude!, longitudeDelta: spanLongitude!)
            let viewRegion = MKCoordinateRegion(center: noLocation, span: locSpan)
            
            mapView.setRegion(viewRegion, animated: false)
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "longitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func fetchAllPins() -> [Pin] {
        
        // Return all pins from memory
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        let results = try? sharedContext.fetch(fetchRequest)

        return results as! [Pin]
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Setup Map View
        
        let mapPinLatitude = view.annotation?.coordinate.latitude as! Double
        let mapPinLongitude = view.annotation?.coordinate.longitude as! Double
        
        let fetchPin = { (latitude: Double, longitude: Double) -> Pin? in
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            let predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", latitude, longitude)
            fetchRequest.predicate = predicate
            
            guard let pin = (try? self.sharedContext.fetch(fetchRequest))!.first
                else {
                    return nil
            }
            return pin
            }
            
        guard let pin = fetchPin(mapPinLatitude, mapPinLongitude)
            else {
                return
        }
        
        if isEditing {
            
            // Delete pins or perform segue
            
            self.appDelegate.persistentContainer.viewContext.delete(pin)
            try? self.sharedContext.save()
            mapView.removeAnnotation(view.annotation!)
        } else {
            print("Transition Made")
            performSegue(withIdentifier: "PinPhotoAlbum", sender: pin)
        }
        
    
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        
        // Find map center and save it to User Defaults
        
        centerLat = mapView.region.center.latitude
        centerLong = mapView.region.center.longitude
        spanLat = mapView.region.span.latitudeDelta
        spanLong = mapView.region.span.longitudeDelta
        
        appDelegate.mapDefaults.set(centerLat, forKey: "centerLatitude")
        appDelegate.mapDefaults.set(centerLong, forKey: "centerLongitude")
        appDelegate.mapDefaults.set(spanLat, forKey: "spanLatitude")
        appDelegate.mapDefaults.set(spanLong, forKey: "spanLongitude")
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        print(mapView.region)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //Save pin coordinates to PhotoAlbum View Controller
        
        if let vc = segue.destination as? PhotoAlbumViewController {
            let pin = sender as! Pin
            vc.mapPin = pin
        }
    }
} 
    


