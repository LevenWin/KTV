//
//  Streaming.swift
//  StreamAudio
//
//  Created by leven on 2020/8/22.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation

public protocol Streaming: class {
    
    var currentTime: TimeInterval? { get }
    
    var delegate: StreamingDelegate? { set get }
    
    var duration: TimeInterval? { get }
    
    var downloader: Downloading { get }
    
    var parser: Parsing? { get }
    
    var reader: Reading? { get }
    
    var engine: AVAudioEngine { get }
    
    var playerNode: AVAudioPlayerNode { get }
    
    var readBufferSize: AVAudioFrameCount { get }
    
    var readFormat: AVAudioFormat { get }
    
    var state: StreamingState { get }
    
    var url: URL? { get }
    
    var volume: Float { get set }
    
    func play()
    
    func pause()
    
    func stop()
    
    func seek(to time: TimeInterval) throws
}

extension Streaming {
    
    public var readBufferSize: AVAudioFrameCount {
        return 8192
    }
    
    public var readFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!

    }
}
