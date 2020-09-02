//
//  AudioFileReader.swift
//  StreamAudio
//
//  Created by leven on 2020/8/29.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioFileReader: AudioReading {
    
    var outputDesc: AudioStreamBasicDescription = AudioStreamBasicDescription()
    
    private(set) var audioFileRef: ExtAudioFileRef?
    
    var fileDesc: AudioStreamBasicDescription = AudioStreamBasicDescription()
    
    var packetSize: UInt32 = 0
    
    var desireFormat: AudioStreamBasicDescription? {
        didSet {
            modifyOutDescByDesireFormat()
            if readerAvailable, let fileRef = audioFileRef {
                let size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
                ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &outputDesc)
            }
        }
    }
    
    var totalFrames: Int64 = 0
    
    var isRepeat: Bool = false
    
    var filePath: String? {
        didSet {
            setupFileReader()
        }
    }
    private(set) var readerAvailable: Bool = false
    
    private func setupFileReader() {
        guard let filePath = filePath else { return }
        let fileURL = URL(fileURLWithPath: filePath)
        
        var status = ExtAudioFileOpenURL(fileURL as CFURL, &audioFileRef)
        guard let fileRef = audioFileRef else { return }
        
        var descSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        
        status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileDataFormat, &descSize, &fileDesc)
        outputDesc.mSampleRate = 444100
        outputDesc.mFormatID = kAudioFormatLinearPCM
        outputDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        outputDesc.mReserved = 0
        outputDesc.mChannelsPerFrame = 1
        outputDesc.mBitsPerChannel = 16
        outputDesc.mFramesPerPacket = 1
        outputDesc.mBytesPerFrame = outputDesc.mChannelsPerFrame / outputDesc.mBitsPerChannel / 8
        outputDesc.mBytesPerPacket = outputDesc.mBytesPerFrame * outputDesc.mFramesPerPacket
        
        // 设置输出的数据格式
        status = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, descSize, &outputDesc)
        var uint32Size: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        // 获取输出的最大包大小
        status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_ClientMaxPacketSize, &uint32Size, &packetSize)
        var numSize = UInt32(MemoryLayout<Int64>.size)
        status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileLengthFrames, &numSize, &totalFrames)
        
        modifyOutDescByDesireFormat()
        
        print(status)

        readerAvailable = true
    }
    
    func modifyOutDescByDesireFormat() {
        guard let desireDesc = desireFormat else { return }
        
        if desireDesc.mSampleRate > 0 {
            outputDesc.mSampleRate = desireDesc.mSampleRate
        }
        
        if desireDesc.mChannelsPerFrame > 0 {
            outputDesc.mChannelsPerFrame = desireDesc.mChannelsPerFrame
        }
        if desireDesc.mBitsPerChannel > 0 {
            outputDesc.mBitsPerChannel = desireDesc.mBitsPerChannel
        }
        
        if desireDesc.mFormatFlags > 0 && desireDesc.mFormatFlags != outputDesc.mFormatFlags {
            outputDesc.mFormatFlags = desireDesc.mFormatFlags
        }
        
        let isNonInterleaved = outputDesc.mFormatFlags & kLinearPCMFormatFlagIsNonInterleaved
        outputDesc.mBytesPerFrame = (isNonInterleaved == kLinearPCMFormatFlagIsNonInterleaved ? UInt32(1) : outputDesc.mChannelsPerFrame) * outputDesc.mBitsPerChannel / 8
        outputDesc.mBytesPerPacket = outputDesc.mChannelsPerFrame
    }
    
    func resetReader() {
        if let fileRef = audioFileRef {
            ExtAudioFileDispose(fileRef)
            audioFileRef = nil
        }
        readerAvailable = false
    }
    
    func read(frames: UnsafeMutablePointer<UInt32>, bufferData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        guard let fileRef = audioFileRef else { return -1 }
        if readerAvailable == false {
            frames.pointee = 0
            return -1
        }
        if isRepeat {
            var curFrameOffset: Int64 = 0
            if ExtAudioFileTell(fileRef, &curFrameOffset) == noErr {
                if curFrameOffset >= totalFrames {
                    if ExtAudioFileSeek(fileRef, 0) != noErr {
                        frames.pointee = 0
                        
                    }
                }
            }
        }
        let status = ExtAudioFileRead(fileRef, frames, bufferData)
        if status != noErr {
            resetReader()
        }
        return status
    }
}
