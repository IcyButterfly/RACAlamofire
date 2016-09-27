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
            let ss = self.producer.on(started: {
                    print("producer.on start")
                }, event: { (event) in
                    print(event)
                }, failed: { (err) in
                    print(err)
                }, completed: { 
                    print("producer.on completed")
                }, interrupted: { 
                    print("producer.on interrupted")
                }, terminated: { 
                    print("producer.on terminnated")
                }, disposed: { 
                    print("producer.on dispose")
                }, next: { (next) in
                    print("producer.on nextValue: ")
            })
//            return self.producer
            
            return ss
        }
        
        cocoaAction = CocoaAction(action, input: self.button)
        self.button.addTarget(cocoaAction, action: CocoaAction.selector, forControlEvents: .TouchUpInside)
        
        action.events.observe { (ob) in
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
            .rac_requestJSON()
        
     
        
        signal.observeNext { (ob) in
            print("signal next1:")
        }
        
        signal.observeNext { (ob) in
            print("signal next2")
        }
        
    }
}

