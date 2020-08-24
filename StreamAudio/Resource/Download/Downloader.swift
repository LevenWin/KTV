//
//  Downloader.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation

public class Downloader: NSObject, Downloading {

    public static let shared: Downloader = Downloader()
    
    public var useCache = true {
        didSet {
            session.configuration.urlCache = useCache ? URLCache.shared : nil
        }
    }
    
    fileprivate lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    fileprivate var task: URLSessionDataTask?
    
    var totalByteReceived: Int64 = 0
    
    var totalBytesCount: Int64 = 0
    
    public var delegate: DownloadingDelegate?
    
    public var completionHandler: ((Error?) -> Void)?
    
    public var progressHandler: ((Data, Float) -> Void)?
    
    public var progress: Float = 0
    
    public var state: DownloadingState = .noStarted {
        didSet {
            delegate?.download(self, changeState: state)
        }
    }
    public var url: URL? {
        didSet {
            if state == .started {
                stop()
            }
            if let url = url {
                progress = 0
                state = .noStarted
                totalBytesCount = 0
                totalByteReceived = 0
                task = session.dataTask(with: url)
            } else {
                task = nil
            }
        }
    }
    
    public func start() {
        guard let task = task else { return }
        switch state {
        case .completed, .started:
            return
        default:
            state = .started
            task.resume()
        }
        
    }
    public func pause() {
        guard let task = task else { return }
        guard state == .started else { return }
        
        state = .paused
        task.suspend()
    }
    public func stop() {
        guard let task = task else { return }
        guard state == .started else { return }
        state = .stopped
        task.cancel()
    }
}
