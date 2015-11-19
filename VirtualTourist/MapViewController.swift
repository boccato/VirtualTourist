//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/19/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//
//  This file was adapted from the MemoryMap app (ViewController.swift).

import MapKit
import UIKit

// Allows users to drop pins with a touch and hold gesture. When the pin drops,
// users can drag the pin until their finger is lifted.
class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Pin currently being created / dragged by the user.
    var pinInFocus: MKPointAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreMapRegion(false)
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        mapView.addGestureRecognizer(lpgr)
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        
        let tapPosition: CGPoint = sender.locationInView(self.mapView)
        let positionOnMap = mapView.convertPoint(tapPosition, toCoordinateFromView: self.mapView)
        
        switch(sender.state) {
            case .Began:
                pinInFocus = MKPointAnnotation()
                pinInFocus.coordinate = positionOnMap
                mapView.addAnnotation(pinInFocus)
            case .Changed:
                pinInFocus.coordinate = positionOnMap
            case .Ended:
                pinInFocus = nil
            default:
                if pinInFocus != nil {
                    mapView.removeAnnotation(pinInFocus)
                    pinInFocus = nil
                }
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
    
    // FIX: Use Core Data instead.
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    // MKMapViewDelegate
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
//    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        if control == view.rightCalloutAccessoryView {
//            let app = UIApplication.sharedApplication()
//            if let toOpen = view.annotation?.subtitle! {
//                app.openURL(NSURL(string: toOpen)!)
//            }
//        }
//    }
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        
//        let reuseId = "pin"
//        
//        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
//        
//        if pinView == nil {
//            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//            pinView!.canShowCallout = true
//            pinView!.pinTintColor = UIColor.redColor()
//            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
//        }
//        else {
//            pinView!.annotation = annotation
//        }
//        
//        return pinView
//    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}
