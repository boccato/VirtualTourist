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
    
    private lazy var group: dispatch_group_t = { return dispatch_group_create() }()
    private var image: UIImage?
    
    
    // Swift doesn't automatically inherits init methods, we must be explicit.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER)
            
                if self.image == nil {
                    self.image = self.loadImage(self.path)
                }
                
                completionHandler(image: self.image)
            }
        }
    }
    
    private func downloadImage() {
        if path == nil {
            dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
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
                self.path = self.saveImage(self.image)
            }
        }
    }
    
    private func loadImage(path: String?) -> UIImage? {
        if let path = path {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    
    private func saveImage(image: UIImage?) -> String? {
        if let image = image {
            if let data = UIImageJPEGRepresentation(image, 1) {
                let manager = NSFileManager.defaultManager()
                let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
                let path = url.URLByAppendingPathComponent(id).path!
                data.writeToFile(path, atomically: true)
                return path
            }
        }
        return nil
    }
}
