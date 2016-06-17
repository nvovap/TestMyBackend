//
//  AppDelegate.swift
//  TestMyBackend
//
//  Created by nvovap on 5/19/16.
//  Copyright © 2016 nvovap. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
   // var delegateUpload = DownloadUpload.sharedInstance

    
    var backgroundSessionCompletionHandler: (() -> Void)?
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
//        print(identifier)
//        
//        print("-- handleEventsForBackgroundURLSession --")
//        let backgroundConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
//        let backgroundSession = NSURLSession(configuration: backgroundConfiguration, delegate: self.delegateUpload, delegateQueue: nil)
//        print("Rejoining session \(backgroundSession)")
//        
//        self.delegateUpload.addCompletionHandler(completionHandler, identifier: identifier)
        
        
        print(identifier)
        
        backgroundSessionCompletionHandler = completionHandler
        
    }

    
    
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        print("Launched in background \(application.applicationState == UIApplicationState.Background)" )
        
        
        // Register for Push Notitications
        let types: UIUserNotificationType = [.Alert, .Badge, .Sound]
        let settings = UIUserNotificationSettings(forTypes: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) { 
        if let tabView = self.window?.rootViewController as? UITabBarController, let navView = tabView.selectedViewController as? UINavigationController
        , let mainTable = navView.viewControllers[0] as? MainTable  {
            
            let fetchStart = NSDate()
            
            
            mainTable.refreshBackGround({ (result) in
                
                let fetchEnd = NSDate()
                
                let timeElapsed = fetchEnd.timeIntervalSinceDate(fetchStart)
                
                print("Background Fetch Duration: \(timeElapsed) seconds")
                
                completionHandler(UIBackgroundFetchResult.NewData)
            })
        } else {
            completionHandler(UIBackgroundFetchResult.NoData)
        }        
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
        var tokenString = ""
        
        for i in 0..<deviceToken.length {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        print(tokenString)
        
        let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
        tokenString = tokenString.stringByAddingPercentEncodingWithAllowedCharacters(expectedCharSet)!
        
        let uri  = NSURL(string: "https://myftp.herokuapp.com/adddevice/\(tokenString)")!
        
        let req = NSMutableURLRequest(URL: uri)
        
        
        NSURLSession.sharedSession().dataTaskWithRequest(req) { (data, res, error) in
            if error != nil {
                print(error)
            }
            
            print("******* response = \(res)")
        }.resume()
    }
    
    
    func deleteAlamofire(id: String){
        let uri  = NSURL(string: "https://alamofire.herokuapp.com/todo/\(id)")!
        //let uri  = NSURL(string: "http://10.10.1.56:3000/todo")!
        
        let req = NSMutableURLRequest(URL: uri)
        
        req.HTTPMethod = "DELETE"
        
        let mySession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        
        //        for stringUrl in data {
        let task = mySession.downloadTaskWithRequest(req) { (url, res, error) in
            
            guard error == nil else {
                print("Error !!! \(error?.localizedDescription)")
                
                return
            }
            
            print("OK!")
            
        }
        
        
        task.resume()
    }
    
    func postAdd(name: String, age: Int){
        
        //https://alamofire.herokuapp.com
        let uri  = NSURL(string: "https://alamofire.herokuapp.com/todo")!
        //let uri  = NSURL(string: "http://10.10.1.56:3000/todo")!
        
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
        let nameData = "Content-Disposition: form-data; name=\"name\"\r\n\r\n\(name)\r\n"
        
        tempData.appendData(nameData.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        tempData.appendData("\(boundaryStart)".dataUsingEncoding(NSUTF8StringEncoding)!)
        let ageData = "Content-Disposition: form-data; name=\"age\"\r\n\r\n\(age)\r\n"
        
        tempData.appendData(ageData.dataUsingEncoding(NSUTF8StringEncoding)!)

        //tempData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData(tempData)
        body.appendData("\(boundaryEnd)".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        print("\(body.length)")
        
        req.setValue("\(body.length)", forHTTPHeaderField: "Content-Length")
        
        req.HTTPBody = body
        
        
        let mySession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        
        //        for stringUrl in data {
        let task = mySession.downloadTaskWithRequest(req) { (url, res, error) in
            
            guard error == nil else {
                print("Error !!! \(error?.localizedDescription)")
                
                return
            }
            
            print("OK!")
            
        }
        
        
        task.resume()
    }
    
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        
        if let id = userInfo["id"] as? String {
            
            switch id {
            case "1":
                if let tabView = self.window?.rootViewController as? UITabBarController, let navView = tabView.selectedViewController as? UINavigationController
                    , let mainTable = navView.viewControllers[0] as? MainTable  {
                    
                    let fetchStart = NSDate()
                    
                    
                    mainTable.refreshBackGround({ (result) in
                        
                        let fetchEnd = NSDate()
                        
                        let timeElapsed = fetchEnd.timeIntervalSinceDate(fetchStart)
                        
                        print("Background Fetch Duration: \(timeElapsed) seconds")
                        
                        completionHandler(UIBackgroundFetchResult.NewData)
                    })
                } else {
                    completionHandler(UIBackgroundFetchResult.NoData)
                }
            case "2":
                if let name = userInfo["message"] as? String {
                     postAdd(name, age: 13)
                }
                completionHandler(UIBackgroundFetchResult.NoData)
            case "3":
                if let id = userInfo["message"] as? String {
                    deleteAlamofire(id)
                }
                completionHandler(UIBackgroundFetchResult.NoData)
            default:
                completionHandler(UIBackgroundFetchResult.NoData)
            }
            
        } else {
            completionHandler(UIBackgroundFetchResult.NoData)
        }
        
        
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

