//
//  UIPhotoCell.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/22/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import UIKit

class UIPhotoCell : UICollectionViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var _photo: Photo!
    
    var photo: Photo {
        get {
            return _photo
        }
        set(photo) {
            _photo = photo
            backgroundView = UIImageView(image: UIImage(named: "loading"))
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            _photo.withLoadedImage({(image) in
                dispatch_async(dispatch_get_main_queue()) {
                    self.backgroundView = UIImageView(image: image)
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.hidden = true
                }
            })
        }
    }
}
