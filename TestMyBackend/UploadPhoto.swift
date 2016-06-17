//
//  UploadPhoto.swift
//  TestMyBackend
//
//  Created by nvovap on 5/24/16.
//  Copyright © 2016 nvovap. All rights reserved.
//

import UIKit

class UploadPhoto: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate {
    
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myProgressView: UIProgressView!
    
    
    
  //  var delegateUpload = DownloadUpload.sharedInstance
//    var task: NSURLSessionDataTask? = nil
//    
    
    lazy var backgroundSession: NSURLSession = {

        
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("bgSessionConfiguration")
        
        configuration.HTTPMaximumConnectionsPerHost = 4; //iOS Default is 4
        configuration.timeoutIntervalForRequest = 600.0; //30min allowance; iOS default is 60 seconds.
        configuration.timeoutIntervalForResource = 120.0; //2min; iOS Default is 7 days
        
        configuration.allowsCellularAccess = true
        
        let sesion = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    
        
        return sesion
    }()
    
    
    lazy var backgroundSession2: NSURLSession = {
        
        
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("bgSessionConfigurationUploadBlock")
        
        configuration.HTTPMaximumConnectionsPerHost = 4; //iOS Default is 4
        configuration.timeoutIntervalForRequest = 600.0; //30min allowance; iOS default is 60 seconds.
        configuration.timeoutIntervalForResource = 120.0; //2min; iOS Default is 7 days
        
        configuration.allowsCellularAccess = true
        
        let sesion = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        
        return sesion
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        _ = self.backgroundSession
        
        _ = self.backgroundSession2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //MARK: - Select Image
    @IBAction func selectPhotoButtonTapped(sender: AnyObject) {
        let myPiickerController = UIImagePickerController()
        myPiickerController.delegate = self
        
        myPiickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        
        self.presentViewController(myPiickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        myImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    
    
    //MARK: - Upload to FTP
   
   
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        
        print("session \(session) uploaded \(uploadProgress * 100)%.")
        
        if session.configuration.identifier == "bgSessionConfigurationUploadBlock" {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.myProgressView.progress = uploadProgress;
        }
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)  {
      
        print(location)
        
        print(downloadTask.taskDescription)
        
        
        print(session.configuration.identifier)
        
        
        
        
        
        if downloadTask.taskDescription == "--GetInfoFile--" {
            
            let fileName = "1.jpg"
            
            
            let user = "manager45"
            
            
            let folder = "5B1562F5-F08F-437A-9CF1-38FD7E39F57C"
            
            
            let size = Int(String(data: NSData(contentsOfURL: location)!, encoding: NSUTF8StringEncoding)!)!
            
            
            uploadFileBlock2(user, fileName: fileName, folder: folder, size: size)
            return
        } else if downloadTask.taskDescription == "--GetFile--" {
            
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.myProgressView.progress = 0;
            self.myImageView.image = nil
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.myProgressView.progress = 0;
                    self.myImageView.image = nil
                    
                    print("completionHandler")
                    completionHandler()
                    
                    
                })
            }
        }
    }
    
    
    func uploadFileBlock2(user: String, fileName: String, folder: String, size: Int) {
        
        if let data = UIImageJPEGRepresentation(myImageView.image!, 1) {
        
      //  let filePath = NSBundle.mainBundle().pathForResource("1", ofType:"")!
        
        //if let data = NSData(contentsOfFile:filePath) {
            var lengthData = data.length
            
            
            if lengthData > size {
                
                lengthData -= size
                
                if lengthData > 1_000_000 {
                    lengthData = 1_000_000
                }
                
                
                let blockData = NSMutableData()
            
                
                
                
                blockData.appendData(data.subdataWithRange(NSRange(location: size, length: lengthData)))
                
                
                    
               //     tempData.appendData(data.bytes[point])
                
                
                let uri  = NSURL(string: "http://10.10.1.56:3000/uploadBlock")!
                
                
                let req = NSMutableURLRequest(URL: uri)
                
                
                req.HTTPMethod = "POST"
               
                
                let boundary = "-----Boundary\(arc4random())\(arc4random())"
                let boundaryStart = "--\(boundary)\r\n"
                let boundaryEnd = "--\(boundary)--\r\n"
                
                
                let contentType = "multipart/form-data; boundary=\(boundary)"
                req.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                
                let body = NSMutableData()
                let tempData = NSMutableData()
                
                
//                tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
//                tempData.appendData("Content-Disposition: form-data; name=\"description\"\r\n\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                
                
                
                //USER
                tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
                let nameData = "Content-Disposition: form-data; name=\"user\"\r\n\r\n\(user)\r\n"
                tempData.appendData(nameData.dataUsingEncoding(NSUTF8StringEncoding)!)
                
                
                
                //FOLDER
                tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
                let foolderData = "Content-Disposition: form-data; name=\"folder\"\r\n\r\n\(folder)\r\n"
                tempData.appendData(foolderData.dataUsingEncoding(NSUTF8StringEncoding)!)
                
                
                //FILE NAME
                tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
                let fileNameData = "Content-Disposition: form-data; name=\"fileName\"\r\n\r\n\(fileName)\r\n"
                tempData.appendData(fileNameData.dataUsingEncoding(NSUTF8StringEncoding)!)
                
                
                //File
                let mimeType = "data"
                tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
                let fileNameContentDisposition =  "filename=\"\(user)_\(folder)_\(fileName)\""
                let contentDisposition = "Content-Disposition: form-data; name=\"\(mimeType)\"; \(fileNameContentDisposition)\r\n"
                
                
                tempData.appendData(contentDisposition.dataUsingEncoding(NSUTF8StringEncoding)!)
                tempData.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                tempData.appendData(blockData)
                //tempData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                
                
                body.appendData(tempData)
                
                body.appendData("\r\n\(boundaryEnd)".dataUsingEncoding(NSUTF8StringEncoding)!)
                
                
                
                req.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
                
                
                
                
                req.HTTPBody = body
                
                
                
                
                
                //        for stringUrl in data {
                let task = backgroundSession.downloadTaskWithRequest(req)
                //        }
                
                
                
                //            let task = backgroundSession.dataTaskWithRequest(req, completionHandler: { (data, res, error) in
                //                print(data)
                //            })
                
                task.taskDescription = "--GetFile--"
                
                task.resume()
                
            
            }
            
        }
    }
   
    func uploadFileBlock() {
        
        let fileName = "1.jpg"
        
        
        let user = "manager45"
        
        
        let folder = "5B1562F5-F08F-437A-9CF1-38FD7E39F57C"
        
        
        
        
            
            //let uri  = NSURL(string: "https://myftp.herokuapp.com/igor")!
            
            let uri  = NSURL(string: "http://10.10.1.56:3000/getSizeFile")!
            
            let req = NSMutableURLRequest(URL: uri)
            
        
            req.HTTPMethod = "POST"
            
            let boundary = "Boundary\(arc4random())\(arc4random())"
            let boundaryStart = "--\(boundary)\r\n"
            let boundaryEnd = "--\(boundary)--\r\n"
            
            
            let contentType = "multipart/form-data; boundary=\(boundary)"
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            
            let body = NSMutableData()
            let tempData = NSMutableData()
            
            tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
            let nameData = "Content-Disposition: form-data; name=\"user\"\r\n\r\n\(user)\r\n"
            tempData.appendData(nameData.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
            let foolderData = "Content-Disposition: form-data; name=\"folder\"\r\n\r\n\(folder)\r\n"
            tempData.appendData(foolderData.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            
            tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
            let fileNameData = "Content-Disposition: form-data; name=\"fileName\"\r\n\r\n\(fileName)\r\n"
            tempData.appendData(fileNameData.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            //tempData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            body.appendData(tempData)
            body.appendData("\(boundaryEnd)".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            print("\(body.length)")
            
            req.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
            
            req.HTTPBody = body
            
            
            
            
            //        for stringUrl in data {
            let task = backgroundSession.downloadTaskWithRequest(req)
            
            task.taskDescription = "--GetInfoFile--"
            
    
            //        }
            
            
            
            //            let task = backgroundSession.dataTaskWithRequest(req, completionHandler: { (data, res, error) in
            //                print(data)
            //            })
            
            task.resume()
            
        
    }
    
    
    @IBAction func uploadBlock() {
        uploadFileBlock()
    }
    
    
    @IBAction func uploadFile() {
        
        let fileName = NSUUID().UUIDString+".jpg"
        
        
        if let data = UIImageJPEGRepresentation(myImageView.image!, 1) {
            
            let uri  = NSURL(string: "https://myftp.herokuapp.com/igor")!
            
            //let uri  = NSURL(string: "http://localhost:3000/igor1")!
            
            let req = NSMutableURLRequest(URL: uri)
            
            //let req = NSMutableURLRequest(URL: NSURL(string: "http://10.10.1.51:8080/FileUploadApache/hello")!)
            
            req.HTTPMethod = "POST"
           // req.timeoutInterval = 10.0
            
            
            //   print(generateBoundaryString())
            
            let boundary = "-----Boundary\(arc4random())\(arc4random())"
            let boundaryStart = "--\(boundary)\r\n"
            let boundaryEnd = "--\(boundary)--\r\n"
            
            
            let contentType = "multipart/form-data; boundary=\(boundary)"
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            
            let body = NSMutableData()
            let tempData = NSMutableData()
            let mimeType = "data"
            
            tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
            tempData.appendData("Content-Disposition: form-data; name=\"description\"\r\n\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            //File
            tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
            let fileNameContentDisposition =  "filename=\"\(fileName)\""
            let contentDisposition = "Content-Disposition: form-data; name=\"\(mimeType)\"; \(fileNameContentDisposition)\r\n"
            
            
            tempData.appendData(contentDisposition.dataUsingEncoding(NSUTF8StringEncoding)!)
            tempData.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            tempData.appendData(data)
            //tempData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            body.appendData(tempData)
            
            body.appendData("\r\n\(boundaryEnd)".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            
            req.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
            
            
            
            
            req.HTTPBody = body
            

            
            
            
            //        for stringUrl in data {
            let task = backgroundSession.downloadTaskWithRequest(req)
            //        }
            
            
            
//            let task = backgroundSession.dataTaskWithRequest(req, completionHandler: { (data, res, error) in
//                print(data)
//            })
            
            task.resume()
            
        }
    }
}




