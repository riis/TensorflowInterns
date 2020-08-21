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
import GroundSdk

/// FlightPlan uploader that works with http
class HttpFlightPlanUploader: ArsdkFlightplanUploader {

    /// Update REST Api.
    /// Not nil when uploader has been configured. Nil after a reset.
    private var flightPlanApi: FlightPlanRestApi?

    func configure(flightPlanPilotingItfController: FlightPlanPilotingItfController) {
        if let droneServer = flightPlanPilotingItfController.deviceController.droneServer {
            flightPlanApi = FlightPlanRestApi(server: droneServer)
        }
    }

    func reset() {
        flightPlanApi = nil
    }

    func uploadFlightPlan(filepath: String, completion: @escaping (Bool, String?) -> Void) -> CancelableCore? {
        return flightPlanApi?.upload(filepath: filepath, completion: { success, flightPlanUid in
            if success {
                completion (true, flightPlanUid)
            } else {
                completion (false, nil)
                ULog.w(.flightPlanTag, "HTTP - Upload of mavlink file failed")
            }
        })
    }
}
