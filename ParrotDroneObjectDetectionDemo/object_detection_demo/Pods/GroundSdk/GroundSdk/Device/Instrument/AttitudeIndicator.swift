// Copyright (C) 2019 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import Foundation

/// Instrument that informs about attitude.
///
/// This instrument can be retrieved by:
/// ```
/// drone.getInstrument(Instruments.attitudeIndicator)
/// ```
@objc(GSAttitudeIndicator)
public protocol AttitudeIndicator: Instrument {

    /// Pitch angle of the drone, in degrees in range ]-90, 90].
    /// Pitch angle is the angle between the horizontal plane parallel to the ground, and the drone longitudinal axis,
    /// which is the axis traversing the drone from tail to head.
    /// Negative values mean the drone is tilted towards ground, positive values mean the drone is tilted towards sky.
    var roll: Double { get }

    /// Roll angle of the drone, in degrees in range ]-180, 180].
    /// Roll angle is the angle between the horizontal plane parallel to the ground, and the drone lateral axis, which
    /// is the axis traversing the drone from left side to right side.
    /// Negative values mean the drone is tilted to the right, positive values mean the drone is tilted to the left.
    var pitch: Double { get }
}

/// :nodoc:
/// Instrument descriptor
@objc(GSAttitudeIndicatorDesc)
public class AttitudeIndicatorDesc: NSObject, InstrumentClassDesc {
    public typealias ApiProtocol = AttitudeIndicator
    public let uid = InstrumentUid.attitudeIndicator.rawValue
    public let parent: ComponentDescriptor? = nil
}
