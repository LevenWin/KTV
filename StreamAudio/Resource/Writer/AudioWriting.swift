//
//  AudioWriting.swift
//  StreamAudio
//
//  Created by leven on 2020/8/29.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AudioToolbox

public struct AudioBufferData {
    var bufferList: AudioBufferList?
    
    var numFrames: UInt32 = 0
}

public protocol AudioWriting {
    
    var fileType: AudioFileTypeID { get set }
    
    var filePath: String? { get set }
    
    var fileRef: ExtAudioFileRef? { get }
        
    func close()
    
    func write(_ bufferData: UnsafePointer<AudioBufferData>) -> OSStatus
}
