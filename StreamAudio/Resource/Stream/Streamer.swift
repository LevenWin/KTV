//
//  Streamer.swift
//  StreamAudio
//
//  Created by leven on 2020/8/22.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation

open class Streamer: Streaming {
    public var currentTime: TimeInterval? {
        guard let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else { return  currenTimeOffSet}
        let currentTime = TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
        return currentTime + currenTimeOffSet
    }
    
    public var delegate: StreamingDelegate?
    public internal(set) var duration: TimeInterval?
    public lazy var downloader: Downloading = {
        let downloader = Downloader()
        downloader.delegate = self
        return downloader
    }()
    public internal(set) var parser: Parsing?
    public internal(set) var reader: Reading?
    
    public let engine = AVAudioEngine()
    public let playerNode = AVAudioPlayerNode()
    public internal(set) var state: StreamingState = .stopped {
        didSet {
            delegate?.streamer(self, changeState: state)
        }
    }
    public var url: URL? {
        didSet {
            reset()
            if let url = url {
                downloader.url = url
                downloader.start()
            }
        }
    }
    
    public var volume: Float {
        get {
            return engine.mainMixerNode.outputVolume
        }
        set {
            engine.mainMixerNode.outputVolume = newValue
        }
    }
    
    var volumeRampTimer: Timer?
    var volumeRampTargetValue: Float?
    
    var currenTimeOffSet: TimeInterval = 0
    
    var isFileSchedulingComplete = false
    
    public init() {
        setupAudioEngine()
    }
    
    func setupAudioEngine() {
        attachNodes()
        
        connectNodes()
        
        engine.prepare()
        
        let interval = 1 / (readFormat.sampleRate / Double(readBufferSize))
        
        let timer = Timer(timeInterval: interval / 2, repeats: true) { [weak self](_) in
            guard self?.state != .stopped else { return }
            self?.scheduleNextBuffer()
            self?.handleTimeUpdate()
            self?.notifyTimeUpdate()
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    func handleTimeUpdate() {
        guard let currentTime = currentTime, let duration = duration else { return }
        if currentTime >= duration {
            try? seek(to: 0)
            pause()
        }
    }
    
    func notifyTimeUpdate() {
        guard engine.isRunning, playerNode.isPlaying else {
            return
        }
        guard let currentTime = currentTime else { return }
        delegate?.streamer(self, updateCurrentTime: currentTime)
    }
    
    func attachNodes() {
        engine.attach(playerNode)
    }
    
    func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: readFormat)
    }
    public func stop() {
        downloader.stop()
        playerNode.stop()
        engine.stop()
        state = .stopped
    }
    public func pause() {
        guard playerNode.isPlaying else {
            return
        }
        playerNode.pause()
        state = .paused
    }
    
    public func play() {
        guard playerNode.isPlaying == false else {
            return
        }
        
        if engine.isRunning == false {
            do {
                try engine.start()
            } catch {
                print("Failed to start engine")
            }
        }
        
        let lastVolume = volumeRampTargetValue ?? volume
        volume = 0
        playerNode.play()
        
        swellVolume(to: lastVolume)
        state = .playing
    }
    func scheduleNextBuffer() {
        guard let reader = reader else {
            return
        }
        guard isFileSchedulingComplete == false else {
            return
        }
        do {
            let nextScheduleBuffer = try reader.read(readBufferSize)
            playerNode.scheduleBuffer(nextScheduleBuffer, completionHandler: nil)
        } catch ReaderError.reachedEndOfFile {
            isFileSchedulingComplete = true
        } catch {
            
        }
    }
    
    public func seek(to time: TimeInterval) throws {
        guard let parser = parser, let reader = reader else {
            return
        }
        
        guard let frameOffset = parser.frameOffset(forTime: time), let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
            return
        }
        currenTimeOffSet = time
        isFileSchedulingComplete = false
        
        let isPlaying = playerNode.isPlaying
        let lastVolume = volumeRampTargetValue ?? volume
        playerNode.stop()
        volume = 0
        
        do {
            try reader.seek(packetOffset)
        } catch {
            
        }
        if isPlaying {
            playerNode.play()
        }
        delegate?.streamer(self, updateCurrentTime: time)
        swellVolume(to: lastVolume)
    }
    
    func reset() {
        stop()
        duration = nil
        reader = nil
        isFileSchedulingComplete = false
        
        do {
            parser = try? Parser()
        } catch {
            print("generate parser filed：")
        }
    }
    
    func swellVolume(to newVolume: Float, duration: TimeInterval = 0.5) {
        volumeRampTargetValue = newVolume
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(duration * 1000 / 2))) { [unowned self] in
            self.volumeRampTimer?.invalidate()
            let timer = Timer(timeInterval: Double(Float((duration/2.0)) / (newVolume*10)), repeats: true, block: { (timer) in
                if self.volume != newVolume {
                    self.volume = min(newVolume, self.volume + 0.1)
                } else {
                    self.volumeRampTimer = nil
                    self.volumeRampTargetValue = nil
                    timer.invalidate()
                }
            })
            RunLoop.current.add(timer, forMode: .common)
            self.volumeRampTimer = timer
            
        }
    }
    func notifiyDownloadProgress(_ progress: Float) {
        guard let url = url else { return }
        delegate?.streamer(self, updateDownloadProgress: progress, forURL: url)
    }
    
    func notifyDurationUpdate(_ duration: TimeInterval) {
        guard let _ = url else { return }
        delegate?.streamer(self, updateDuration: duration)
    }
    
    func handleDurationUpdate() {
        if let newDuration = parser?.duration {
            var shouldUpdate = false
            if duration == nil {
                shouldUpdate = true
            } else if let oldDuration = duration, oldDuration < newDuration {
                shouldUpdate = true
            }
            if shouldUpdate {
                self.duration = newDuration
                notifyDurationUpdate(newDuration)
            }
        }
    }
    
}

extension Streamer: DownloadingDelegate {
    public func download(_ download: Downloading, changeState state: DownloadingState) {
        print("Downloader State: ",state)
    }
    
    public func download(_ download: Downloading, completedWithError error: Error?) {
        if let error = error, let url = download.url {
            DispatchQueue.main.sync { [unowned self]in
                self.delegate?.streamer(self, failedDownloadWithError: error, forURL: url)
            }
        }
    }
    
    public func download(_ download: Downloading, didReceivedData data: Data, progress: Float) {
        guard let parser = parser else { return }
        
        print("Downloader Progress: ", progress)

        do {
            try parser.parse(data: data)
        } catch {
            
        }
        
        if reader == nil, let _ = parser.dataFormat {
            do {
                reader = try Reader(parser: parser, readFormat: readFormat)
            } catch {
                
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.notifiyDownloadProgress(progress)
            self?.handleDurationUpdate()
        }
    }
}


