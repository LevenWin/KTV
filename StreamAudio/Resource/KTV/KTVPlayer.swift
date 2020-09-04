//
//  KTVPlayer.swift
//  StreamAudio
//
//  Created by leven on 2020/9/4.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation

class KTVPlayer {
    
    var playNode: AVAudioPlayerNode = {
        let node = AVAudioPlayerNode()
        return node
    }()
    
    var engine = AVAudioEngine()
        // 成品立体声混响
    lazy var songReverb:AVAudioUnitReverb = {
        let node = AVAudioUnitReverb()
        return node
    }()
    
    // 成品延迟，可理解为自动多重奏
    lazy var songDelay: AVAudioUnitDelay = {
        let node = AVAudioUnitDelay()
        node.delayTime = 0
        return node
    }()
    
    // 成品速度
    lazy var songRate: AVAudioUnitTimePitch = {
        let node = AVAudioUnitTimePitch()
        return node
    }()
    
    var localURL: URL? {
        didSet {
            guard localURL != nil else {
                return
            }
            do {
               let fileRef = try? AVAudioFile(forReading: localURL!)
                playNode.scheduleFile(fileRef!, at: nil, completionHandler: nil)
            }
        }
    }
    init() {
        attachNode()
        connectNode()
    }
    
    func attachNode() {
        engine.attach(playNode)
        engine.attach(songReverb)
        engine.attach(songDelay)
        engine.attach(songRate)
    }
    
    func connectNode() {
        engine.connect(playNode, to: songRate, format: readFormat)
        engine.connect(songRate, to: songDelay, format: readFormat)
        engine.connect(songDelay, to: songReverb, format: readFormat)
        engine.connect(songReverb, to: engine.mainMixerNode, format: readFormat)
        engine.prepare()
    }
    
    func playOrStop() {
        if engine.isRunning {
            playNode.stop()
            engine.stop()
        } else if let _ = localURL {
            do {
                try? engine.start()
            }
            playNode.play()
        }
    }
    
    public var readBufferSize: AVAudioFrameCount {
        return 8192
    }
    
    public var readFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!

    }
}
