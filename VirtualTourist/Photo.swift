//
//  Photo.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/21/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import CoreData
import UIKit

class Photo : NSManagedObject {
    
    struct Keys {
        static let Id = "Id"
        static let Path = "Path"
        static let URL = "URL"
    }
    
    @NSManaged var id: String
    @NSManaged var path: String!
    @NSManaged var url: String
    @NSManaged var pin: Pin?
    
    var image: UIImage?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        print(id)
        print(path)
        print(url)
        downloadImage()
    }
    
    // Insert the new Photo into a Core Data Managed Object Context and
    // initialize its properties from a dictionary.
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // This inherited init method does the work of "inserting" our object
        // into the context that was passed in as a parameter.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dictionary[Keys.Id] as! String
        path = dictionary[Keys.Path] as? String
        url = dictionary[Keys.URL] as! String
        downloadImage()
    }
    
    func withLoadedImage(completionHandler: (image: UIImage?) -> Void) {
        if let image = image {
            completionHandler(image: image)
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                if let
                    url = NSURL(string: self.url),
                    data = NSData(contentsOfURL: url),
                    image = UIImage(data: data)
                {
                    self.image = image
                }
                else {
                    self.image = UIImage(named: "not-found")
                }
                completionHandler(image: self.image)
            })
        }
    }
    
    private func downloadImage() {
        if path == nil {
            //
            print("cadê!")
        }
    }
}
