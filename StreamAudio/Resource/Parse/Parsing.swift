//
//  Parsing.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation
public protocol Parsing: class {
    
    var dataFormat: AVAudioFormat? { get }
    
    var duration: TimeInterval? { get }
    
    var isParsingComplete: Bool { get }
    
    var packets: [(Data, AudioStreamPacketDescription?)] { get }
    
    var totalFrameCount: AVAudioFrameCount? { get }
    
    var totalPacketCount: AVAudioPacketCount? { get }
    
    func parse(data: Data) throws
    
    func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition?
    
    func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount?
    
    func timeOffset(forFrame frame: AVAudioFramePosition) -> TimeInterval?
}

extension Parsing {
    public var duration: TimeInterval? {
        guard let sampleRate = dataFormat?.sampleRate else { return nil }
        guard let totalFrameCount = totalFrameCount else { return nil }
        return TimeInterval(totalFrameCount) / TimeInterval(sampleRate)
    }
    
    public var totalFrameCount: AVAudioFrameCount? {
        guard let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else { return nil }
        guard let totalPacketCount = totalPacketCount else { return nil }
        return AVAudioFrameCount(framesPerPacket) * AVAudioFrameCount(totalPacketCount)
    }
    public var isParsingComplete: Bool {
        guard let totalPacketCount = totalPacketCount else { return false }
        return packets.count == totalPacketCount
    }
    
    public func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition? {
        guard let _ = dataFormat?.streamDescription.pointee, let frameCount = totalFrameCount, let duration = duration else { return nil }
        let ratio = time / duration
        return AVAudioFramePosition(Double(frameCount) * ratio)
    }
    
    public func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount? {
        guard let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else { return nil }
        return AVAudioPacketCount(frame) / AVAudioPacketCount(framesPerPacket)
    }
    public func timeOffset(forFrame frame: AVAudioFramePosition) -> TimeInterval? {
        guard let _ = dataFormat?.streamDescription.pointee, let frameCount = totalFrameCount, let duration = duration else { return nil }
        return TimeInterval(frame) / TimeInterval(frameCount) * duration
    }
}
