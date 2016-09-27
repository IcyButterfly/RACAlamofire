//
//  ViewController.swift
//  RACAlamofire
//
//  Created by 郑林琴 on 16/7/23.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

import UIKit
import Alamofire
import ReactiveCocoa

struct Server {
    static var URL = ""
}

extension Request{
    
    
    // MARK: - Convert to SignalProducer
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
                
                print("response json send")
                switch response.result{
                case .Success(let value):
                    print(" rac_response ")
                    observer.sendNext(value)
                    observer.sendCompleted()
                case .Failure(let err):
                    observer.sendFailed(err)
                }
            })
        })
    }
    
    
    // MARK: - response Type
    func rac_responseData(queue queue: dispatch_queue_t? = nil) -> SignalProducer<NSData, NSError> {
        
        return self.rac_response(queue: queue, responseSerializer: Request.dataResponseSerializer())
    }
    
    
    func rac_responseString(
        queue queue: dispatch_queue_t? = nil,
        encoding: NSStringEncoding? = nil)
        -> SignalProducer<String, NSError>{
            
        return self.rac_response(queue: queue, responseSerializer: Request.stringResponseSerializer(encoding: encoding))
    }
    
    func rac_responseJSON(
        queue queue: dispatch_queue_t? = nil,      
        options: NSJSONReadingOptions = .AllowFragments)
        -> SignalProducer<AnyObject, NSError> {
        
        return self.rac_response(queue: queue, responseSerializer: Request.JSONResponseSerializer(options: options))
    }
    
}


class ViewController: UIViewController {

    
    let producer = Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
        .rac_responseJSON().replayLazily(1)
    
    @IBOutlet weak var button: UIButton!
//    var action: Action<UIButton, AnyObject, NSError>!
    var cocoaAction: CocoaAction!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let signal = RACSignal.createSignal { (_) -> RACDisposable! in
            return nil
        }
        
        signal.replay()
        
        
//        self.button.rac_signalForControlEvents(UIControlEvents.TouchUpInside).subscribeNext { (_) in
//            self.signalProducer()
//        }
        
        
        
        let action = Action<UIButton, AnyObject, NSError> { value -> SignalProducer<AnyObject, NSError> in
            
            print("btn actioned")
            
            let ss = Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
                .rac_responseJSON().replayLazily(1).logEvents()

            
            return ss
        }
        
        cocoaAction = CocoaAction(action, input: self.button)
        self.button.addTarget(cocoaAction, action: CocoaAction.selector, forControlEvents: .TouchUpInside)
        
        action.events.logEvents().observe { (ob) in
            switch ob{
            case .Next(let value):
                print("event next \("event")")
            case .Completed:
                print("event complete")
            case .Interrupted:
                print("event interrupted")
            case .Failed(_):
                print("event failed")
            }
        }
        
    }

    func signalProducer(){
        
        
        var _signal: Signal<AnyObject, NSError>!
        
        producer.startWithSignal({ (signal, dispose) in
            
            _signal = signal
            
            
        })
        
        _signal.observeNext({ (next) in
            print("next: ")
        })
        
        _signal.observeFailed({ (err) in
            print("error:")
        })
        
        _signal.observeCompleted({
            print("completed")
        })

        
        producer.startWithNext { (ob) in
            print("producer next1")
        }
        
        producer.startWithNext { (ob) in
            print("producer next2")
        }
    }
    
    func signal(){
        
        let signal = Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
            .rac_responseJSON()
        
        signal.startWithSignal { (signal, dispose) in
            
            signal.observeNext({ (_) in
                
            })
        }
        
        
    }
}

