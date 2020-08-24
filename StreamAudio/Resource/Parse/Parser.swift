//
//  Parser.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AVFoundation
public class Parser: Parsing {
    
    public var dataFormat: AVAudioFormat?
    public var packets: [(Data, AudioStreamPacketDescription?)] = [(Data, AudioStreamPacketDescription?)]()
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormat else { return nil }
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
    }
    public var frameCount: UInt64 = 0
    
    public var packetCount: UInt64 = 0
    
    var streamID: AudioFileStreamID?
    
    public init() throws {
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &streamID) == noErr else { throw ParserError.streamCouldNotOpen }
    }
    
    public func parse(data: Data) throws {
        let streamID = self.streamID!
        let count = data.count
        var data = data
        _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
            guard result == noErr else {
                throw ParserError.failedToParseByte(result)
            }
        }
//        _ = try data.withUnsafeBytes({ (bytes) in
//            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes.baseAddress, [])
//            guard result == noErr else {
//                throw ParserError.failedToParseByte(result)
//            }
//        })
    }
}

func ParserPacketCallback(_ context: UnsafeMutableRawPointer,
                          _ byteCount: UInt32,
                          _ packetCount: UInt32,
                          _ data: UnsafeRawPointer,
                          _ packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>) {
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    let packetDescriptionOrNil: UnsafeMutablePointer<AudioStreamPacketDescription>? = packetDescriptions
    let isCompressed = packetDescriptionOrNil != nil
    guard let dataFormat = parser.dataFormat else { return  }
    
    if isCompressed {
        // MP3 or AAC
        for i in 0 ..< Int(packetCount) {
            let packetDescription = packetDescriptions[i]
            let packetStart = Int(packetDescription.mStartOffset)
            let packetSize = Int(packetDescription.mDataByteSize)
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, packetDescription))
        }
        
    } else {
        let format = dataFormat.streamDescription.pointee
        let bytesPerPacket = Int(format.mBytesPerPacket)
        for i in 0 ..< Int(packetCount) {
            let packetStart = i * bytesPerPacket
            let packetSize = bytesPerPacket
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, nil))
        }
    }
}

func ParserPropertyChangeCallback(_ context: UnsafeMutableRawPointer, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID, _ flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    switch propertyID {
    case kAudioFileStreamProperty_DataFormat:
        var format = AudioStreamBasicDescription()
        GetPropertyValue(&format, streamID, propertyID)
        parser.dataFormat = AVAudioFormat(streamDescription: &format)
        print("Parser get data format: ", parser.dataFormat as Any)
    case kAudioFileStreamProperty_AudioDataPacketCount:
        GetPropertyValue(&parser.packetCount, streamID, propertyID)
        print("Parser get packetCount: ", parser.packetCount)

    default:
        print(propertyID)
    }
    
}

func GetPropertyValue<T>(_  value: inout T, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID) {
    var propSize: UInt32 = 0
    // 先获取size
    guard AudioFileStreamGetPropertyInfo(streamID, propertyID, &propSize, nil) == noErr else {
        return
    }
    // 再获取value
    guard AudioFileStreamGetProperty(streamID, propertyID, &propSize, &value) == noErr else {
        return
    }
}
