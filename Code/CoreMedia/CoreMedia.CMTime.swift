//
//  File.swift
//  
//
//  Created by Ivan Kh on 02.05.2023.
//

import CoreMedia

public func CMTimeSetSeconds(_ time: inout CMTime, _ seconds: Float64) {
    time.value = CMTimeValue(seconds * Float64(time.timescale))
}


public extension CMTimeScale {
    static let prefferedVideoTimescale: CMTimeScale = 600
}

public extension CMTimeValue {
    static let prefferedVideoTimescale: CMTimeValue = CMTimeValue(CMTimeScale.prefferedVideoTimescale)
}


public extension CMTime {
    static func video(value: CMTimeValue) -> CMTime {
        return CMTime(value: value, timescale: .prefferedVideoTimescale)
    }

    static func video(fps: CMTimeValue) -> CMTime {
        return CMTime(value: .prefferedVideoTimescale / fps, timescale: .prefferedVideoTimescale)
    }
}

extension CMTime: BinaryCodable {
    public init(from data: inout Data) throws {
        self.init(value: try data.pop(CMTimeValue.self),
                  timescale: try data.pop(CMTimeScale.self),
                  flags: CMTimeFlags(rawValue: try data.pop(UInt32.self)),
                  epoch: try data.pop(CMTimeEpoch.self))
    }

    public func encode(to data: inout Data) -> Int {
        data.encode(value)
        + data.encode(timescale)
        + data.encode(flags.rawValue)
        + data.encode(epoch)
    }
}
