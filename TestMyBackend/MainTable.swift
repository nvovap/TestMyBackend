//
//  MainTable.swift
//  TestMyBackend
//
//  Created by nvovap on 5/19/16.
//  Copyright © 2016 nvovap. All rights reserved.
//

import UIKit

class MainTable: UITableViewController, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    var data = [String]()
    
    var images = [String: UIImage]()
    
    
    var currentTasks = [NSURL: AnyObject]()
    
    
    func refresh() {
        
        for task in Array(currentTasks.values) {
            task.cancel()
        }
        
      //  currentTasks.removeAll(keepCapacity: false)
        
        
        getData { (data) in
            self.data = data
            
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            })
        }
    }
    
    
    func refreshBackGround(callback: (UIBackgroundFetchResult) -> Void) {
        
        
        getData { (data) in
            
            self.data = data
            
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                
                callback(UIBackgroundFetchResult.NewData)
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Идет обновление...")
        refreshControl!.addTarget(self, action: #selector(MainTable.refresh), forControlEvents: UIControlEvents.ValueChanged)
        
        refresh()
    }
    
    override func didReceiveMemoryWarning() {
        images.removeAll(keepCapacity: false)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! CellMain
        
        
        let name =  data[indexPath.row]
        
        
        cell.title.text =  name
        cell.imageT.image = images[name]
        
        return cell
    }
    
    
    //MARK: - Helper functio
    func  getData(callback: ([String])->Void ) {
        //let url = NSURL(string: "http://localhost:3000/listfiles")!
        
        let url = NSURL(string: "https://myftp.herokuapp.com/listfiles")!
        
        let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let task = defaultSession.dataTaskWithURL(url) { (data, res, error) in
            
            dispatch_async(dispatch_get_main_queue(), { 
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
            var result = [String]()
            
            guard error == nil else {
                print(error?.localizedDescription)
                dispatch_async(dispatch_get_main_queue(), {
                    callback(result)
                })
                
                
                return
            }
            
            if let httpResponse = res as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    self.currentTasks[httpResponse.URL!] = nil
                    
                    do {
                        
                        //let myString = String(data: data!, encoding: NSUTF8StringEncoding)
                        

                        
                        if let data = data, response = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject] {
                            
                            if let array: AnyObject = response["results"] {
                                var imagesForDownload = [String]()
                                
                                for image in array as! [AnyObject] {
                                    
                                    
                                    let name = image["name"] as! String
                                    let ext = image["ext"] as! String
                                    
                                    result.append(name)
                                    
                                    if ext == ".jpg" {
                                        imagesForDownload.append(name)
                                    }
                                }
                                
                                self.downloadImage(imagesForDownload)
                            }
                        }
    
                    } catch let error as NSError {
                       print("Error parsing results: \(error.localizedDescription)")
                    }
                }
            }
            
            
            dispatch_async(dispatch_get_main_queue(), {
                callback(result)
            })

            
        }
        
        
        task.resume()
        
        currentTasks[url] = task
        
    }
    
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.tableView.reloadData()
                    
                    print("completionHandler")
                    completionHandler()
                    
                    
                })
            }
        }
    }
    
    
    
    
    
    // MARK: Download helper methods
    
    // This method generates a permanent local file path to save a track to by appending
    // the lastPathComponent of the URL (i.e. the file name and extension of the file)
    // to the path of the app’s Documents directory.
    func localFilePathForUrl(previewUrl: String) -> NSURL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        if let url = NSURL(string: previewUrl), lastPathComponent = url.lastPathComponent {
            let fullPath = documentsPath.stringByAppendingPathComponent(lastPathComponent)
            return NSURL(fileURLWithPath:fullPath)
        }
        return nil
    }

    
    func trackIndexForDownloadTask(url: String) -> Int? {
       
        for (index, image) in data.enumerate() {
            
            print("image = \(image) index = \(index)")
            
            if url == image {
                return index
            }
        }
        return nil
    }
    
    
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        
        print(progress)
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        // 1
        if let originalURL = downloadTask.originalRequest?.URL?.absoluteString,
            destinationURL = localFilePathForUrl(originalURL) {
            
            //  print(destinationURL)
            
            // 2
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtURL(destinationURL)
            } catch {
                // Non-fatal: file probably doesn't exist
            }
            do {
                try fileManager.copyItemAtURL(location, toURL: destinationURL)
                
                let name = destinationURL.lastPathComponent!
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.images[name] = UIImage(data: NSData(contentsOfURL: destinationURL)!)
                    
                    print("Stop Task \(name)")
                    
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    
                    // 4
                    if let trackIndex = self.trackIndexForDownloadTask(name) {
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: trackIndex, inSection: 0)], withRowAnimation: .None)
                    }
                    
//                    self.tableView.reloadData()
                })
                
                
                
            
            } catch let error as NSError {
                print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }
        
        // 3
        if let url = downloadTask.originalRequest?.URL {
            currentTasks[url] = nil
        }
    }
    
    
    func downloadImage(names: [String])  {
       
        
     //   let queue = NSOperationQueue()
       
        
        for name in names {
            
            if images[name] == nil {
                
                //let url = NSURL(string: "http://localhost:3000/image/\(name)")!
                
                let url = NSURL(string: "https://myftp.herokuapp.com/image/\(name)")!
                
                if let task = currentTasks[url] {
                    print("Resume Task \(name)")
                    task.resume()
                } else {
                
                    print("Start Task \(name)")
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    })
                
                    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(name), delegate: self, delegateQueue: nil)
                
                
                    let task = defaultSession.downloadTaskWithURL(url)
                
                
                    task.resume()
                    currentTasks[url] = task
                }
                
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                })
            }
        }
    }
}














    

