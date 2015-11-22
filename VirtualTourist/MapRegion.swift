//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/22/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import CoreData
import MapKit

class MapRegion : NSManagedObject {
    
    struct Keys {
        static let Latitude = "Latitude"
        static let Longitude = "Longitude"
        static let LatitudeDelta = "LatitudeDelta"
        static let LongitudeDelta = "LongitudeDelta"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitudeDelta: Double
    @NSManaged var longitudeDelta: Double
    
    // Swift doesn't automatically inherits init methods, we must be explicit.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Insert the new MapRegion into a Core Data Managed Object Context and
    // initialize its properties from a dictionary.
    init(region: MKCoordinateRegion, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("MapRegion", inManagedObjectContext: context)!
        
        // This inherited init method does the work of "inserting" our object
        // into the context that was passed in as a parameter.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.region = region
    }
    
    var region: MKCoordinateRegion {
        get {
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            return MKCoordinateRegion(center: center, span: span)
        }
        set(region) {
            latitude = region.center.latitude
            longitude = region.center.longitude
            latitudeDelta = region.span.latitudeDelta
            longitudeDelta = region.span.longitudeDelta
        }
    }

}