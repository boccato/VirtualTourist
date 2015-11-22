//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/19/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import CoreData
import MapKit
import UIKit

// Allows users to drop pins with a touch and hold gesture. When the pin drops,
// users can drag the pin until their finger is lifted.
class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var btnEdit: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    // Pin currently being created / dragged by the user.
    var pinInFocus: Pin!
    var savedMapRegion: MapRegion!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreMapRegion(false)
        // restoreSavedPins()
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            self.showAlert("", message: "Error performing initial pins fetch: \(error)")
        }

        
        if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
            mapView.addAnnotations(pins)
        }
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        mapView.addGestureRecognizer(lpgr)
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        let tapPosition: CGPoint = sender.locationInView(self.mapView)
        let positionOnMap = mapView.convertPoint(tapPosition, toCoordinateFromView: self.mapView)
        
        switch(sender.state) {
            case .Began:
                let pin = [
                    Pin.Keys.Latitude: positionOnMap.latitude,
                    Pin.Keys.Longitude: positionOnMap.longitude
                ]
                pinInFocus = Pin(dictionary: pin, context: sharedContext)
                mapView.addAnnotation(pinInFocus)
            case .Changed:
                pinInFocus.setCoordinate(positionOnMap)
            case .Ended:
                CoreDataStackManager.sharedInstance().saveContext()
                // Pre-fetch photos for the new pin.
                pinInFocus = nil
            default:
                if pinInFocus != nil {
                    mapView.removeAnnotation(pinInFocus)
                    CoreDataStackManager.sharedInstance().rollbackContext()
                    pinInFocus = nil
                }
        }
        
    }
    
    // Helper: Core Data
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    } ()

    func fetchMapRegion()  {
        let fetchRequest = NSFetchRequest(entityName: "MapRegion")
        do {
            let data = try sharedContext.executeFetchRequest(fetchRequest) as! [MapRegion]
            if data.isEmpty {
                savedMapRegion = MapRegion(region: mapView.region, context: sharedContext)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            else {
                savedMapRegion = data[0]
            }
        } catch {
            savedMapRegion = MapRegion(region: mapView.region, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    // Helper: Save region and zoom level.
    
    // Here we use the same filePath strategy as the Persistent Master Detail
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        savedMapRegion.region = mapView.region
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func restoreMapRegion(animated: Bool) {
        fetchMapRegion()
        if let region = savedMapRegion?.region {
            mapView.setRegion(region, animated: animated)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? PhotoAlbumViewController {
            vc.pin = self.mapView.selectedAnnotations[0] as! Pin
        }
    }
    
    // MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        performSegueWithIdentifier("photoAlbum", sender: self)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}
