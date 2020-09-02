//
//  Reading.swift
//  StreamAudio
//
//  Created by leven on 2020/8/29.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AudioToolbox
public protocol AudioReading {
    
    var readerAvailable: Bool { get }
    
    var outputDesc: AudioStreamBasicDescription { get }
    
    var audioFileRef: ExtAudioFileRef? { get }
    
    var fileDesc: AudioStreamBasicDescription { get }
    
    var packetSize: UInt32 { get }
    
    var desireFormat: AudioStreamBasicDescription? { get set }
    
    var totalFrames: Int64 { get }
    
    var filePath: String? { get set }
    
    func read(frames: UnsafeMutablePointer<UInt32>, bufferData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus
    
}

