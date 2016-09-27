//
//  AlamofireSignalProducer.swift
//  RACAlamofire
//
//  Created by ET|冰琳 on 16/7/27.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveCocoa


extension Request{
    
    // MARK: SignalProducer
    func rac_response() -> SignalProducer<(NSURLRequest?, NSHTTPURLResponse?, NSData?), NSError> {
        
        return SignalProducer.init({ (observer, disponse) in
            
            return self.response(completionHandler: { ( request, response, nsData, nsError) in
                
                guard let nsError = nsError else{
                    observer.sendNext((request, response, nsData))
                    return
                }
                
                observer.sendFailed(nsError)
            })
        })
    }
    
    func rac_response<T: ResponseSerializerType>(
        queue queue: dispatch_queue_t? = nil,
              responseSerializer: T)
        -> SignalProducer<T.SerializedObject, T.ErrorObject>{
            
            return SignalProducer.init({ (observer, dispose) in
                
                return self.response(queue: queue, responseSerializer: responseSerializer, completionHandler: { (response) in
                    
                    switch response.result{
                    case .Success(let value):
                        observer.sendNext(value)
                        observer.sendCompleted()
                    case .Failure(let err):
                        observer.sendFailed(err)
                    }
                })
            })
    }
    
    func rac_responseData(queue queue: dispatch_queue_t? = nil) -> SignalProducer<NSData, NSError> {
        
        return self.rac_response(queue: queue, responseSerializer: Request.dataResponseSerializer())
    }
    
    
    func rac_responseString(queue queue: dispatch_queue_t? = nil, encoding: NSStringEncoding? = nil)
        -> SignalProducer<String, NSError>{
            
            return self.rac_response(queue: queue, responseSerializer: Request.stringResponseSerializer(encoding: encoding))
    }
    
    func rac_responseJSON(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments)
        -> SignalProducer<AnyObject, NSError> {
            
            return self.rac_response(queue: queue, responseSerializer: Request.JSONResponseSerializer(options: options))
    }
    
    // MARK: Signal
    func rac_requestJSON() -> Signal<AnyObject, NSError>{
        
        return  Signal.init { (observer) -> Disposable? in
            
            self.responseJSON(queue: nil, options: .AllowFragments, completionHandler: { (response) in
                #if DEBUG
                print("request json send")
                #endif
                
                switch response.result{
                case .Success(let value):
                    observer.sendNext(value)
                    observer.sendCompleted()
                case .Failure(let err):
                    observer.sendFailed(err)
                }
            })
            
            return nil
        }
    }
    
    
    func rac_upload(URLString : String,
                    parameters:[String : AnyObject]? = nil,
                    header: [String: String]? = nil,
                    image: UIImage ,
                    progress: ((NSProgress)->Void)?) -> SignalProducer<AnyObject, NSError>{
        
        return SignalProducer.init { (observer, disposable) in
           
            Alamofire.upload(.POST, URLString, headers: header, multipartFormData: { (formData) in
                let data : NSData = UIImagePNGRepresentation(image)!
                
                formData.appendBodyPart(data: data, name: "file", fileName: "img.png", mimeType: formData.contentType)
                
                parameters?.forEach({ (element) in
                    formData.appendBodyPart(data: element.1.dataUsingEncoding(NSUTF8StringEncoding)!, name: element.0)
                })
                
                }, encodingCompletion:  { encodingResult in
                    switch encodingResult{
                    case .Success(request: let upload, streamingFromDisk: _, streamFileURL: _):
                        
                        upload.responseJSON(completionHandler: { (response) in
                            #if DEBUG
                                debugPrint("upload response", response)
                            #endif
                            
                            switch response.result{
                            case .Success(let value):
                                observer.sendNext(value)
                                observer.sendCompleted()
                            case .Failure(let err):
                                observer.sendFailed(err)
                            }
                            
                        })
                    case .Failure(let err):
                        #if DEBUG
                            debugPrint(err)
                        #endif
                        observer.sendFailed(NSError(domain: "图片encode失败", code: 0, userInfo: [NSLocalizedDescriptionKey:"图片encode失败"]))
                    }
            })
        }
    }
}

