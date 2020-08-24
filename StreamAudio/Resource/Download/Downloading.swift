//
//  Downloading.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation

public protocol Downloading: class {
    
    var delegate: DownloadingDelegate? { get set}
    
    var completionHandler: ((Error?) -> Void)? { get set }
    
    var progress: Float { get }
    
    var state: DownloadingState { get }
    
    var url: URL? { get set }
    
    func start()
    
    func pause()
    
    func stop()
    
}
