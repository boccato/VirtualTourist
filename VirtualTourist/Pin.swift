//
//  Pin.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/19/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import CoreData
import MapKit

class Pin : NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    // Core Data attributes.
    @NSManaged var album: [Photo]
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    
    // Swift doesn't automatically inherits init methods, we must be explicit.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Insert the new Pin into a Core Data Managed Object Context and
    // initialize its properties from a dictionary.
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // This inherited init method does the work of "inserting" our object
        // into the context that was passed in as a parameter.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
    
    func withLoadedAlbum(completionHandler: (album: [Photo]?) -> Void) {
        if album.isEmpty {
            FlickrClient.sharedInstance().searchPhotosBy(latitude, longitude: longitude) { (album, error) in
                guard error == "" else {
                    completionHandler(album: nil)
                    return
                }
                for photo in album {
                    let photo = Photo(dictionary: photo, context: self.managedObjectContext!)
                    photo.pin = self
                }
            }
        }
        completionHandler(album: album)
    }
    
    // MKAnnotation
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) {
        willChangeValueForKey("coordinate")
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        didChangeValueForKey("coordinate")
    }
}
