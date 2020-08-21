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

/// An interpolator applied on an axis.
///
/// An interpolator transforms the physical axis position (which varies in a linear scale from -100 when the axis is
/// at start of its course, to 100 when the axis is at end of its course) by applying a predefined formula.
/// The transformed value still varies in a [-100, 100] range, but the scale might not be linear, depending on the
/// applied interpolator.
///
/// The interpolation formula applies before any axis event is sent either to the connected drone (in case the axis is
/// not grabbed by the application) or to the application (when the axis is grabbed).
@objc(GSAxisInterpolator)
public enum AxisInterpolator: Int {

    /// Physical linear axis position is not modified.
    case linear

    /// A light exponential transform is applied to the axis physical position.
    ///
    /// Formula (where x is the physical axis position in linear [-100, 100] range):
    /// ```
    ///    for x in [-100, 0[ : -100 * e^((x + 100) / x)
    ///    for x = 0 : 0
    ///    for x in ]0, 100] : 100 * e^((x - 100) / x)
    /// ```
    case lightExponential

    /// A medium exponential transform is applied to the axis physical position.
    ///
    /// Formula (where x is the physical axis position in linear [-100, 100] range):
    /// ```
    ///    for x in [-100, 0[ : x * e^((x + 100) / x)
    ///    for x = 0 : 0
    ///    for x in ]0, 100] : x * e^((x - 100) / x)
    /// ```
    case mediumExponential

    /// A strong exponential transform is applied to the axis physical position.
    ///
    /// Formula (where x is the physical axis position in linear [-100, 100] range):
    /// ```
    ///    for x in [-100, 0[ : -(x^2 / 100) * e^((x + 100) / x)
    ///    for x = 0 : 0
    ///    for x in ]0, 100] : (x^2 / 100) * e^((x - 100) / x)
    /// ```
    case strongExponential

    /// A very strong exponential transform is applied to the axis physical position.
    ///
    /// Formula (where x is the physical axis position in linear [-100, 100] range):
    /// ```
    ///    for x in [-100, 0[ : -(x^3 / 10000) * e^((x + 100) / x)
    ///    for x = 0 : 0
    ///    for x in ]0, 100] : (x^3 / 10000) * e^((x - 100) / x)
    /// ```
    case strongestExponential
}
