//
//  Reading.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation
public protocol Reading {
    var currentPacket: AVAudioPacketCount { get }
    
    var parser: Parsing { get }
    
    var readFormat: AVAudioFormat { get }
    
    init(parser: Parsing, readFormat: AVAudioFormat) throws
    
    func read(_ frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer
    
    func seek(_ packet: AVAudioPacketCount) throws
}
