//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Ricardo Boccato Alves on 11/21/15.
//  Copyright © 2015 Ricardo Boccato Alves. All rights reserved.
//

import Foundation

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "de887233ff9159222d38832e7dc7ab60"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

class FlickrClient {
    
    func searchPhotosBy(latitude: Double, longitude: Double, completionHandler: (album: [[String:AnyObject]], error: String) -> Void) {
        guard validLatitude(latitude) else {
            completionHandler(album: [], error: "Latitude Invalid.\nIt should be [-90, 90].")
            return
        }
        guard validLongitude(longitude) else {
            completionHandler(album: [], error: "Longitude Invalid.\nIt should be [-180, 180].")
            return
        }
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": "25"
        ]
        getImagesFromFlickrBySearch(methodArguments, completionHandler: completionHandler)
    }
    
    // Helper : encoding.
    
    private func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // Make sure that it is a string value.
            let stringValue = "\(value)"
            
            // Escape it.
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it.
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // Helper : handling latitudes and longitudes.
    
    private func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        // Fix added to ensure box is bounded by minimum and maximums.
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    private func validLatitude(latitude: Double) -> Bool {
        return latitude >= LAT_MIN && latitude <= LAT_MAX
    }
    
    private func validLongitude(longitude: Double) -> Bool {
        return longitude >= LON_MIN && longitude <= LON_MAX
    }
    
//    func getLatLonString() -> String {
//        let latitude = (self.latitudeTextField.text! as NSString).doubleValue
//        let longitude = (self.longitudeTextField.text! as NSString).doubleValue
//        
//        return "(\(latitude), \(longitude))"
//    }
    
    // Helper : Flickr API
    
    // Makes first request to get a random page, then it makes a request to get an image with the random page.
    private func getImagesFromFlickrBySearch(methodArguments: [String : AnyObject], completionHandler: (album: [[String:AnyObject]], error: String) -> Void) {
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(album: [], error: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                var msg = ""
                if let response = response as? NSHTTPURLResponse {
                    msg = "Your request returned an invalid response! Status code: \(response.statusCode)!"
                } else if let response = response {
                    msg = "Your request returned an invalid response! Response: \(response)!"
                } else {
                    msg = "Your request returned an invalid response!"
                }
                completionHandler(album: [], error: msg)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(album: [], error: "No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                completionHandler(album: [], error: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                completionHandler(album: [], error: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                completionHandler(album: [], error: "Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                completionHandler(album: [], error: "Cannot find key 'pages' in \(photosDictionary)")
                return
            }

            /* Pick a random page! */
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImagesFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage, completionHandler: completionHandler)
        }
        
        task.resume()
    }
    
    private func getImagesFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int,
        completionHandler: (album: [[String:AnyObject]], error: String) -> Void) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(album: [], error: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                var msg = ""
                if let response = response as? NSHTTPURLResponse {
                    msg = "Your request returned an invalid response! Status code: \(response.statusCode)!"
                } else if let response = response {
                    msg = "Your request returned an invalid response! Response: \(response)!"
                } else {
                    msg = "Your request returned an invalid response!"
                }
                completionHandler(album: [], error: msg)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(album: [], error: "No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                completionHandler(album: [], error: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                completionHandler(album: [], error: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            //////
            
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                completionHandler(album: [], error: "Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                completionHandler(album: [], error: "Cannot find key 'photo' in \(photosDictionary)")
                return
            }
            
            var album = [[String:AnyObject]]()
            for photoDictionary in photosArray {
                /* GUARD: Does our photo have a key for 'id'? */
                guard let id = photoDictionary["id"] as? String else {
                    completionHandler(album: [], error: "Cannot find key 'id' in \(photoDictionary)")
                    return
                }
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let url = photoDictionary["url_m"] as? String else {
                    completionHandler(album: [], error: "Cannot find key 'url_m' in \(photoDictionary)")
                    return
                }
                album.append([Photo.Keys.Id: id, Photo.Keys.URL: url])
            }
            completionHandler(album: album, error: "")
        }
        
        task.resume()
    }
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}
