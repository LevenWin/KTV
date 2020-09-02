//
//  KTV.swift
//  StreamAudio
//
//  Created by leven on 2020/8/29.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation
class KTV: Streamer {

    var audioMixer = AVAudioMixerNode()
    
    lazy var micMixer: AVAudioMixerNode = {
        let node = AVAudioMixerNode()
//        node.outputVolume = 1.0
        return node
    }()
    
    // 失真效果器
    lazy var recordRate: AVAudioUnitTimePitch = {
        let node = AVAudioUnitTimePitch()
        node.rate = 1
        return node
    }()
    // 失真效果器
    lazy var distortion: AVAudioUnitDistortion = {
        let node = AVAudioUnitDistortion()
        node.loadFactoryPreset(AVAudioUnitDistortionPreset(rawValue: 0)!)
        return node
    }()
    // 立体声混响
    lazy var micReverb:AVAudioUnitReverb = {
        let node = AVAudioUnitReverb()
        node.wetDryMix = 50
        return node
    }()
    // 音频延迟，可理解为自动多重奏
    lazy var delay: AVAudioUnitDelay = {
        let node = AVAudioUnitDelay()
        node.delayTime = 0
        return node
    }()
    
    var mixerWriter: AVAudioFile?
    var recordWriter: AVAudioFile?
    
    override func attachNodes() {
        super.attachNodes()
        engine.attach(delay)
        engine.attach(micMixer)
        engine.attach(micReverb)
        engine.attach(distortion)
        engine.attach(recordRate)
    }
    override func play() {
        initSoundSave()
        super.play()
    }
//    override func pause() {
//        if engine.isRunning {
//            engine.pause()
//        }
//        state = .paused
//    }
//
//    override func stop() {
//        engine.stop()
//    }

    override func connectNodes() {
        let recordDesc = engine.inputNode.inputFormat(forBus: 0)
        print(recordDesc, readFormat)
        playerNode.volume = 0.7
        // 录音
        engine.connect(engine.inputNode, to: delay, format: engine.inputNode.inputFormat(forBus: 0))
        // 延迟
        engine.connect(delay, to: micReverb, format: engine.inputNode.inputFormat(forBus: 0))
        // 混响
        engine.connect(micReverb, to: micMixer, format: engine.inputNode.inputFormat(forBus: 0))
        // 伴奏播放
        engine.connect(playerNode, to: micMixer, fromBus: 0, toBus: 1, format: readFormat)

        // 混合
        engine.connect(micMixer, to: engine.mainMixerNode, format: engine.inputNode.inputFormat(forBus: 0))
        

        engine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(4800), format: nil) { [weak self](pcmBuffer, audioTime) in
            do {
                // 保存录音到文件
                try? self?.recordWriter?.write(from: pcmBuffer)
            }
        }
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(4800), format: readFormat) { [weak self](pcmBuffer, audioTime) in
            do {
                // 保存合成音频到文件
                try? self?.mixerWriter?.write(from: pcmBuffer)
            }
        }
    }
    
    func initSoundSave() {
        if FileManager.default.fileExists(atPath: mixerAudioSavePath()) {
            do {
                try? FileManager.default.removeItem(atPath: mixerAudioSavePath())
            }
        }
        
        if FileManager.default.fileExists(atPath: recordvVoiceSavePath()) {
            do {
                try? FileManager.default.removeItem(atPath: recordvVoiceSavePath())
            }
        }
        
        var mixerWriteSetting = readFormat.settings
        mixerWriteSetting[AVLinearPCMIsNonInterleaved] = false
        do {
            try? mixerWriter = AVAudioFile(forWriting: URL(fileURLWithPath: mixerAudioSavePath()), settings: mixerWriteSetting, commonFormat: readFormat.commonFormat, interleaved: false)
        }
        
        var recordWriteSetting = engine.inputNode.inputFormat(forBus: 0).settings
        recordWriteSetting[AVLinearPCMIsNonInterleaved] = false
        do {
            try? recordWriter = AVAudioFile(forWriting: URL(fileURLWithPath: recordvVoiceSavePath()), settings: recordWriteSetting)
        }
        

        print(mixerAudioSavePath())
        print(recordvVoiceSavePath())
    }
    
    func mixerAudioSavePath() -> String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "" + "/ktv"
        if FileManager.default.fileExists(atPath: dir) == false {
            do {
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: dir), withIntermediateDirectories: true, attributes: nil)
            }
        }
        // 添加.wav后，无法播放。。手动添加后可以播放
        let path = dir + "/" + "international"
        return path
    }
    
    func recordvVoiceSavePath() -> String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "" + "/record"
        if FileManager.default.fileExists(atPath: dir) == false {
            do {
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: dir), withIntermediateDirectories: true, attributes: nil)
            }
        }
        let path = dir + "/" + "voice"
        return path
    }
    
}
