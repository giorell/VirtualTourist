//
//  PhotoAlbumViewController.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/30/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegateFlowLayout {
    enum CollectionViewState {
        case viewing
        case editing
        case loading
    }
    
    // Mark: - Outlets
    
    @IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var noImagesFoundLabel: UILabel!
    @IBOutlet private weak var bottomButton: UIButton!
    
    // MARK: - Private variables
    
    private var state: CollectionViewState = .viewing {
        didSet {
            switch state {
            case .editing:
                bottomButton.setTitle("Remove Selected Pictures", for: .normal)
                bottomButton.backgroundColor = UIColor(hexString: "555555", alpha: 0.9)
            case .viewing:
                bottomButton.setTitle("NEW COLLECTION", for: .normal)
                bottomButton.backgroundColor = UIColor(hexString: "0082FF", alpha: 0.8)
            case .loading:
                bottomButton.setTitle("Loading...", for: .normal)
                bottomButton.backgroundColor = UIColor(hexString: "CCCCCC", alpha: 0.8)
            }
        }
    }
    private let imagesToDelete = NSMutableSet()
    private var photosManager: PinPhotosManager = {
        return PinPhotosManager.shared
    }()
    private var resultsManager = FetchResultManager()
    private let reuseImageCell = "PhotoAlbumCell"
    private let cacheImages = NSCache<AnyObject, AnyObject>()
    private let sectionInsets = UIEdgeInsets(top: 5.0,
                                             left: 5.0,
                                             bottom: 5.0,
                                             right: 5.0)
    private let flickr = FlickrClient()
    private let itemsPerRow: CGFloat = 3.0
    private let cellSpacing: CGFloat = 5.0
    private var photoSpanLong: String {
        var longitude = mapPin.longitude
        longitude = longitude + 1.0
        
        return longitude.description
    }
    
    private var photoSpanLat: String {
        var latitude = mapPin.latitude
        latitude = latitude + 1.0
        
        return latitude.description
    }
    
    // MARK: - Public variables
    
    var mapPin: Pin!
    
    // MARK: View Controller Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsManager.resetFetchController(with: mapPin)
        noImagesFoundLabel.isHidden = true
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshContent(_:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    @objc func refreshContent(_ control: UIControl?) {
        guard let fetchedObjects = resultsManager.fetchedResultsController.fetchedObjects else {
            collectionView.refreshControl?.endRefreshing()
            return
        }
        cacheImages.removeAllObjects()
        photosManager.deleteFromPhotos(fetchedObjects)
        photosManager.save({ [weak self] errorString in
            if errorString != nil{
                self?.showAlert(errorString ?? "Something went wrong refreshing")
            }
        })
        fetchData()
        photosToDownload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTopImageMapScreenshot()
        photosToDownload()
    }

    // MARK: Networking Funcs
    func loadImages() {
        FlickrClient.searchFlickr(geopinLatitudeSearch: mapPin.latitude.description, geopinLongitudeSearch: mapPin.longitude.description, geopinLatitudeSearchMax: photoSpanLat, geopinLongitudeSearchMax: photoSpanLong) { [weak self] searchResults in
            switch searchResults {
            case .error(let error) :
                print("Error Searching: \(error)")
            case .results(let results):
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                self.collectionView.refreshControl?.endRefreshing()
                self.parseResponse(results.searchResults)
                self.fetchData()
            }
        }
    }
    
    func parseResponse(_ photos: [FlickrPhoto]) {
        if photos.count == 0 {
            self.noImagesFoundLabel.isHidden = false
            self.collectionView?.reloadData()
        } else {
            self.photosManager.addPhotos(photos, mapPin: self.mapPin)
            self.state = .viewing
            self.photosManager.save({ [weak self] errorString in
                if errorString != nil{
                    self?.showAlert(errorString ?? "Something went wrong parsing")
                }
            })
        }
    }
    
    func fetchData() {
        resultsManager.fetch()
        collectionView?.reloadData()
    }
    
    func photosToDownload() {
        if mapPin.photos?.count ?? 0 > 0 {
            fetchData()
            state = .viewing
            activityIndicator.stopAnimating()
        } else {
            if collectionView.refreshControl?.isRefreshing == false {
                state = .loading
                bottomButton.backgroundColor = .darkGray
                activityIndicator.startAnimating()
            }
            loadImages()
        }
    }
}

// MARK: - Actions
extension PhotoAlbumViewController {
    @IBAction func bottomButtonAction(_ sender: Any) {
        switch state {
        case .editing:
            bottomButton.isEnabled = true
            for photo in imagesToDelete {
                PinPhotosManager.shared.deleteFromMemory(photo as! Photo)
            }
            imagesToDelete.removeAllObjects()
            PinPhotosManager.shared.save({ [weak self] errorString in
                if errorString != nil{
                    self?.showAlert(errorString ?? "Something went wrong saving.")
                }
            })
            resultsManager.fetch()
            if resultsManager.fetchedResultsController.sections?[0].numberOfObjects == 0 {
                refreshContent(nil)
            }
            state = .viewing
        case .viewing:
            bottomButton.isEnabled = true
            refreshContent(nil)
            imagesToDelete.removeAllObjects()
        case .loading:
            bottomButton.isEnabled = false
        }
    
        
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension PhotoAlbumViewController: UICollectionViewDataSource   {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return resultsManager.fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsManager.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let flickrPhoto = resultsManager.fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseImageCell,
                                                      for: indexPath) as! PhotoAlbumCell

        cell.imageView.alpha = imagesToDelete.contains(flickrPhoto) ? 0.5 : 1.0
        if let imageFromCache = cacheImages.object(forKey: flickrPhoto.id! as AnyObject) as? UIImage {
            cell.imageView.image = imageFromCache
            cell.backgroundColor = .white
            cell.cellActivityIndicator.stopAnimating()
        } else {
            cell.cellActivityIndicator.startAnimating()
            ImagesLoader.loadImage(imageUrl: flickrPhoto.imageURL ?? "") { [weak self] data in
                if data == nil {
                    let image = UIImage(imageLiteralResourceName: "image_error.png")
                    cell.backgroundColor = .lightGray
                    cell.imageView.image = image
                    self?.cacheImages.setObject(image, forKey: flickrPhoto.id! as AnyObject)
                    cell.cellActivityIndicator.stopAnimating()
                } else {
                let image = UIImage(data: data!)
                cell.backgroundColor = .lightGray
                cell.imageView.image = image
                self?.cacheImages.setObject(image!, forKey: flickrPhoto.id! as AnyObject)
                cell.cellActivityIndicator.stopAnimating()
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let flickrPhoto = resultsManager.fetchedResultsController.object(at: indexPath)
        if state == .editing, imagesToDelete.contains(flickrPhoto) {
            imagesToDelete.remove(flickrPhoto)
        } else if state == .viewing || (state == .editing && imagesToDelete.contains(flickrPhoto) == false) {
            imagesToDelete.add(flickrPhoto)
        }
        
        state = imagesToDelete.count > 0 ? .editing : .viewing
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: Common
extension PhotoAlbumViewController {
    func showAlert(_ errorMessage: String) {
        let alertController = UIAlertController(title: "", message: errorMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func applyTopImageMapScreenshot() {
        let loadingActivity = UIActivityIndicatorView(style: .gray)
        loadingActivity.center = CGPoint(x: headerImageView.frame.size.width/2.0 + 20.0, y: headerImageView.frame.size.height/2.0)
        headerImageView.addSubview(loadingActivity)
        loadingActivity.startAnimating()
        makeMapScreenshotOf(pin: mapPin) { [weak self] image in
            guard let self = self else { return }
            loadingActivity.startAnimating()
            loadingActivity.removeFromSuperview()
            UIView.transition(with: self.headerImageView, duration: 0.06, options: .transitionCrossDissolve, animations: {
                self.headerImageView.image = image
            }, completion: nil)
        }
    }
    
    func makeMapScreenshotOf(pin: Pin, handler: @escaping ((UIImage?) -> Void)) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: CLLocationDistance(exactly: 900)!, longitudinalMeters: CLLocationDistance(exactly: 900)!)
        options.size = CGSize(width: view.frame.size.width, height: headerImageView.frame.size.height)
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { [weak self] snapshot, error in
            if let error = error {
                print(error)
            } else {
                guard let self = self else { return }
                UIGraphicsBeginImageContextWithOptions(options.size, true, 0)
                snapshot?.image.draw(at: .zero)
                
                let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let pinImage = pinView.image
                
                var point = snapshot?.point(for: self.mapPin.coordinate)
                
                if self.headerImageView.frame.contains(point ?? .zero) {
                    let pinCenterOffset = pinView.centerOffset
                    point?.x -= pinView.bounds.size.width / 2
                    point?.y -= pinView.bounds.size.height / 2
                    point?.x += pinCenterOffset.x
                    point?.y += pinCenterOffset.y
                    pinImage?.draw(at: point ?? .zero)
                }
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                handler(image)
            }
        }
    }
}

// MARK: - Collection View Flow Layout Delegate
extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize(in: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }

    private func cellSize(in collectionView: UICollectionView) -> CGSize {
        let collectionViewWidthWithoutSpacing = (collectionView.frame.size.width - sectionInsets.left - sectionInsets.right) - (cellSpacing * (itemsPerRow - 1.0))
        
        let cellSideSize = (collectionViewWidthWithoutSpacing / itemsPerRow)
        return CGSize(width: cellSideSize, height: cellSideSize)
    }
}
