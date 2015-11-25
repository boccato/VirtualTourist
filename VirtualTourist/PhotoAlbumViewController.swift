//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/21/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var btnNewCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblNoImages: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    var pin: Pin!
    
    // UIViewController
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        
        let width = floor((self.collectionView.frame.size.width-8)/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    override func viewDidLoad() {
        if let pin = pin {
            mapView.addAnnotation(pin)
            
            let center = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: false)
            
            do {
                try fetchedResultsController.performFetch()
            } catch let error as NSError {
                self.showAlert("", message: "Error performing initial photos fetch: \(error)")
            }
            
            pin.withLoadedAlbum() {(album) in
                dispatch_async(dispatch_get_main_queue(), {
                    if album == nil {
                        self.showAlert("Error", message: "Could not load images from Flickr.")
                    }
                    self.btnNewCollection.enabled = true
                })
            }
        }
    }
    
    // UICollectionViewDataSource, UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath)
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        (cell as! UIPhotoCell).photo = photo
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    // NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // NSFetchedResultsControllerDelegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }

    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the index paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type{

        case .Insert:
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }

    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }

            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
//    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ColorCell
//        
//        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
//        if let index = selectedIndexes.indexOf(indexPath) {
//            selectedIndexes.removeAtIndex(index)
//        } else {
//            selectedIndexes.append(indexPath)
//        }
//        
//        // Then reconfigure the cell
//        configureCell(cell, atIndexPath: indexPath)
//        
//        // And update the buttom button
//        updateBottomButton()
//    }
}
