//
//  ParseError.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation

import AudioToolbox

public enum ParserError: LocalizedError {
    case streamCouldNotOpen
    case failedToParseByte(OSStatus)
    public var errorDescription: String? {
        switch self {
        case .streamCouldNotOpen:
            return "could not open stream for parsing"
        case .failedToParseByte(let status):
            return localizedDescriptionFromParseError(status)
        }
    }
    func localizedDescriptionFromParseError(_ status: OSStatus) -> String {
        switch status {
        case kAudioFileStreamError_UnsupportedFileType:
            return "the file type is not supported"
        case kAudioFileStreamError_UnsupportedDataFormat:
            return "the file data format is not supported by thie fie type"
        case kAudioFileStreamError_UnsupportedProperty:
            return "the property is not supported"
        case kAudioFileStreamError_BadPropertySize:
            return "the size of the property data was not correct"
        case kAudioFileStreamError_NotOptimized:
            return " it is not possible to produce output packets because the file's packet table or other defining"
        case kAudioFileStreamError_InvalidPacketOffset:
            return "a packet offset was less than zero, or past the end of the file"
        case kAudioUnitErr_InvalidFile:
            return "the file is malformed, or otherwise not a valid instance of an audio file fo ite type, or is not recogined as an audio file"
        case kAudioFileStreamError_ValueUnknown:
            return "the property value is not present in this file before the audio data"
        case kAudioFileStreamError_DataUnavailable:
            return "this amount of data provided to the parser was insufficient to produce an result"
        case kAudioFileStreamError_IllegalOperation:
            return "an illegal operation was attempted"
        default:
            return "an unspecified error occurred"
        }
    }
}
