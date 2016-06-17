//
//  DownloadUpload.swift
//  TestMyBackend
//
//  Created by nvovap on 5/25/16.
//  Copyright © 2016 nvovap. All rights reserved.
//

import Foundation


typealias CompleteHandlerBlock = () -> ()

class DownloadUpload : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
    
    var handlerQueue: [String : CompleteHandlerBlock]!
    
    class var sharedInstance: DownloadUpload {
        struct Static {
            static var instance : DownloadUpload?
            static var token : dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = DownloadUpload()
            Static.instance!.handlerQueue = [String : CompleteHandlerBlock]()
        }
        
        return Static.instance!
    }
    
    
    //MARK: session delegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if error != nil {
            print("session \(session) occurred error \(error?.localizedDescription)")
        } else {
            //            print("session \(session), response: \(NSString(data: responseData, encoding: NSUTF8StringEncoding))")
        }
    }
    
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        
        print("session \(session) uploaded \(uploadProgress * 100)%.")
        
//        dispatch_async(dispatch_get_main_queue()) {
//            self.myProgressView.progress = uploadProgress;
//        }
        
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        print("session \(session)")
        print("received response \(response)")
        
        
        
//        dispatch_async(dispatch_get_main_queue()) {
//            self.myProgressView.progress = 0;
//            self.myImageView.image = nil
//        }
        
        
        
        completionHandler(NSURLSessionResponseDisposition.Allow)
        
    }

    
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        //        responseData.appendData(data)
    }
    
    
    
    
    //=================================
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("session error: \(error?.localizedDescription).")
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("session \(session) download task \(downloadTask) resumed at offset \(fileOffset) bytes out of an expected \(expectedTotalBytes) bytes.")
    }
    
    
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("background session \(session) finished events.")
        
        if !session.configuration.identifier!.isEmpty {
            callCompletionHandlerForSession(session.configuration.identifier)
        }
    }
    
    //MARK: completion handler
    func addCompletionHandler(handler: CompleteHandlerBlock, identifier: String) {
        handlerQueue[identifier] = handler
    }
    
    func callCompletionHandlerForSession(identifier: String!) {
        let handler : CompleteHandlerBlock = handlerQueue[identifier]!
        handlerQueue!.removeValueForKey(identifier)
        dispatch_async(dispatch_get_main_queue(), {
            
            print("completionHandler")
            handler()
            
            
        })

    }
}