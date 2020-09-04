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

    // 伴奏人声合成
    var audioMixer = AVAudioMixerNode()
    
    // 人声
    lazy var micMixer: AVAudioMixerNode = {
        let node = AVAudioMixerNode()
//        node.outputVolume = 1.0
        return node
    }()

    // 人声立体声混响
    lazy var micReverb:AVAudioUnitReverb = {
        let node = AVAudioUnitReverb()
        node.wetDryMix = 50
        return node
    }()
    // 人声音频延迟，可理解为自动多重奏
    lazy var micdelay: AVAudioUnitDelay = {
        let node = AVAudioUnitDelay()
        node.delayTime = 0
        return node
    }()

    
    var mixerWriter: AVAudioFile?
    var recordWriter: AVAudioFile?
    
    override func attachNodes() {
        super.attachNodes()
        engine.attach(micdelay)
        engine.attach(micMixer)
        engine.attach(micReverb)

        engine.attach(audioMixer)
    }
    override func play() {
        initSoundSave()
        super.play()
    }
    
    func updateVoiceVolume(_ volume: CGFloat) {
        engine.inputNode.volume = Float(volume)
    }
    
    func updateSongVolume(_ volume: CGFloat) {
        playerNode.volume = Float(volume)
    }
    
    override func connectNodes() {
        let recordDesc = engine.inputNode.inputFormat(forBus: 0)
        print(recordDesc, readFormat)
        // 人声录音
        engine.connect(engine.inputNode, to: micReverb, format: engine.inputNode.inputFormat(forBus: 0))
        // 人声延迟
        engine.connect(micReverb, to: micdelay, format: engine.inputNode.inputFormat(forBus: 0))
        // 人声混响
        engine.connect(micdelay, to: micMixer, format: engine.inputNode.inputFormat(forBus: 0))
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
