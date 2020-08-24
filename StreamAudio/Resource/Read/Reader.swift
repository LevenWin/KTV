//
//  Reader.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation

public class Reader: Reading {
    public internal(set) var currentPacket: AVAudioPacketCount = 0
    public let parser: Parsing
    public let readFormat: AVAudioFormat
    
    var converter: AudioConverterRef? = nil
    
    private let queue = DispatchQueue(label: "com.fastlearner.streamer")
    
    deinit {
        guard AudioConverterDispose(converter!) == noErr else {
            return
        }
    }
    public required init(parser: Parsing, readFormat: AVAudioFormat) throws {
        self.parser = parser
        guard let dataFormat = parser.dataFormat else { throw  ReaderError.parserMissingDataFormat}
        let sourceFormat = dataFormat.streamDescription
        let commonFormat = readFormat.streamDescription
        let result = AudioConverterNew(sourceFormat, commonFormat, &converter)
        guard result == noErr else {
            throw ReaderError.unableToCreateConverter(result)
        }
        self.readFormat = readFormat
    }
    public func read(_ frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        let framePerPacket = readFormat.streamDescription.pointee.mFramesPerPacket
        var packets = frames / framePerPacket
        guard let buffer = AVAudioPCMBuffer(pcmFormat: readFormat, frameCapacity: frames) else { throw ReaderError.failedToCreatePCMBuffer }
        buffer.frameLength = frames
        
        try queue.sync {
            let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
            let status = AudioConverterFillComplexBuffer(converter!, ReaderConverterCallback, context, &packets, buffer.mutableAudioBufferList, nil)
            guard status == noErr else {
                switch status {
                    case ReaderMissingSourceFormatError:
                        throw ReaderError.parserMissingDataFormat
                    case ReaderReachedEndOfDataError:
                        throw ReaderError.reachedEndOfFile
                    case ReaderNotEnoughDataError:
                        throw ReaderError.notEnoughData
                    default:
                        throw ReaderError.converterFailed(status)
                }
            }
        }
        return buffer
    }
    
    public func seek(_ packet: AVAudioPacketCount) throws {
        queue.sync {
            currentPacket = packet
        }
    }
}

func ReaderConverterCallback(_ converter: AudioConverterRef,
                             _ packetCount: UnsafeMutablePointer<UInt32>,
                             _ ioData: UnsafeMutablePointer<AudioBufferList>,
                             _ outPacketDescriptions: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
                             _ context: UnsafeMutableRawPointer?) -> OSStatus {
    let reader = Unmanaged<Reader>.fromOpaque(context!).takeUnretainedValue()
    
    guard let sourceFormat = reader.parser.dataFormat else { return ReaderMissingSourceFormatError }
    
    let packetIndex = Int(reader.currentPacket)
    let packets = reader.parser.packets
    let isEndOfData = packetIndex >= packets.count - 1
    if isEndOfData {
        if reader.parser.isParsingComplete {
            packetCount.pointee = 0
            return ReaderReachedEndOfDataError
        } else {
            return ReaderNotEnoughDataError
        }
    }
    
    let packet = packets[packetIndex]
    var data = packet.0
    let dataCount = data.count
    ioData.pointee.mNumberBuffers = 1
    ioData.pointee.mBuffers.mData = UnsafeMutableRawPointer.allocate(byteCount: dataCount, alignment: 0)
//    _ = data.withUnsafeBytes({ bytes in
//        memcmp((ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: UInt8.self))!, bytes.baseAddress!, dataCount)
//    })
    _ = data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
        memcpy((ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: UInt8.self))!, bytes, dataCount)
    }
    ioData.pointee.mBuffers.mDataByteSize = UInt32(dataCount)
    
    let sourceFormatDescription = sourceFormat.streamDescription.pointee
    if sourceFormatDescription.mFormatID != kAudioFormatLinearPCM {
        if outPacketDescriptions?.pointee == nil {
            outPacketDescriptions?.pointee = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: 1)
        }
        outPacketDescriptions?.pointee?.pointee.mDataByteSize = UInt32(dataCount)
        outPacketDescriptions?.pointee?.pointee.mStartOffset = 0
        outPacketDescriptions?.pointee?.pointee.mVariableFramesInPacket = 0
    }
    packetCount.pointee = 1
    reader.currentPacket = reader.currentPacket + 1
    
    
    return noErr
}
