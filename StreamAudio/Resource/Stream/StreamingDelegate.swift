//
//  StreamingDelegate.swift
//  StreamAudio
//
//  Created by leven on 2020/8/22.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
public protocol StreamingDelegate: class {
    func streamer(_ streamer: Streaming, failedDownloadWithError error: Error, forURL url: URL)
    func streamer(_ streamer: Streaming, updateDownloadProgress progress: Float, forURL url: URL)
    
    func streamer(_ streamer: Streaming, changeState state: StreamingState)
    
    func streamer(_ streamer: Streaming, updateCurrentTime currentTime: TimeInterval)
    
    func streamer(_ streamer: Streaming, updateDuration duration: TimeInterval)
    
}
