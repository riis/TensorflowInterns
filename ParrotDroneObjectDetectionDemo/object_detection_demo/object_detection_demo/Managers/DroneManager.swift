import UIKit
import GroundSdk

class DroneManager: DroneManagerProtocol {
    
    private let groundSdk = GroundSdk()
    
    // drone
    private var droneStateRef: Ref<DeviceState>?
    private var drone:Drone?
    
    // connection
    private var autoConnectionRef: Ref<AutoConnection>?
    
    //battery
    private var droneBatteryInfoRef: Ref<BatteryInfo>?
    
    //Altitude
    private var droneAltitudeRef: Ref<Altimeter>?
    
    // video feed
    /// Reference to the current drone stream server Peripheral.
    private var streamServerRef: Ref<StreamServer>?
    /// Reference to the current drone live stream.
    private var liveStreamRef: Ref<CameraLive>?
    
    // remote
    // Remote control:
    /// Current remote control instance.
    private var remote: RemoteControl?
    /// Reference to the current remote control state.
    private var remoteStateRef: Ref<DeviceState>?
    /// Reference to the current remote control battery info instrument.
    private var remoteBatteryInfoRef: Ref<BatteryInfo>?
    
    
    private var takeOffEnabled:Bool
    private var landEnabled:Bool
    
    private var delegate:DroneDelegate

    /// Reference to a current drone piloting interface.
    private var pilotingItfRef: Ref<ManualCopterPilotingItf>?

        
    init(_ droneDelegate:DroneDelegate){
        takeOffEnabled = false
        landEnabled = false
        delegate = droneDelegate
    }

    func startDrone() {
        resetDrone()
        connectToDrone()
    }
    
    private func resetDrone(){
        self.delegate.onConnectionStatusUpdate(
            DeviceState.ConnectionState.disconnected.description
        )
        self.takeOffEnabled = false
        self.landEnabled = false
        self.delegate.onLiveStreamChange(nil)
    }
    
    private func connectToDrone(){
        // Monitor the auto connection facility.
        // Keep the reference to be notified on update.
        autoConnectionRef = groundSdk.getFacility(Facilities.autoConnection) { [weak self] autoConnection in
           // Called when the auto connection facility is available and when it changes.
            if let self = self, let autoConnection = autoConnection {
               // Start auto connection.
               if (autoConnection.state != AutoConnectionState.started) {
                   autoConnection.start()
               }

               // If the drone has changed.
               if (self.drone?.uid != autoConnection.drone?.uid) {
                   if (self.drone != nil) {
                       // Stop to monitor the old drone.
                       self.stopDroneMonitors()

                       // Reset user interface drone part.
                       self.resetDrone()
                   }

                   // Monitor the new drone.
                   self.drone = autoConnection.drone
                   if (self.drone != nil) {
                       self.startDroneMonitors()
                   }
               }

                // If the remote control has changed.
               if (self.remote?.uid != autoConnection.remoteControl?.uid) {
                   if (self.remote != nil) {
                       // Stop to monitor the old remote.
                       self.stopRemoteMonitors()
                   }

                   // Monitor the new remote.
                   self.remote = autoConnection.remoteControl
                   if (self.remote != nil) {
                       self.startRemoteMonitors()
                   }
               }
           }
       }
    }
    
    /// Starts remote control monitors.
    private func startRemoteMonitors() {
        // Monitor remote state
        monitorRemoteState()
        // Monitor remote battery level
        monitorRemoteBatteryLevel()
    }
    
    ////// Stops remote control monitors.
    private func stopRemoteMonitors() {
        // Forget all references linked to the current remote to stop their monitoring.
        remoteStateRef = nil
        remoteBatteryInfoRef = nil
        self.delegate.onRemoteConnectionStatusUpdate(
            DeviceState.ConnectionState.disconnected.description
        )
    }
    
    ////// Monitor current remote control state.
    private func monitorRemoteState() {
        // Monitor current drone state.
        remoteStateRef = remote?.getState { [weak self] state in
            // Called at each remote state update.
            if let self = self, let state = state {
                self.delegate.onRemoteConnectionStatusUpdate(state.connectionState.description)
            }
        }
    }
    /// Monitors current remote control battery level.
    private func monitorRemoteBatteryLevel() {
        // Monitor the battery info instrument.
        remoteBatteryInfoRef = remote?.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
        // Called when the battery info instrument is available and when it changes.
            if let self = self, let batteryInfo = batteryInfo {
                self.delegate.onRemoteBatteryStatusUpdate(batteryInfo.batteryLevel)
            }
        }
    }
    
    func startDroneMonitors(){
        monitorDroneState()
        monitorDroneBatteryLevel()
        startVideoStream()
        monitorPilotingInterface()
        monitorDroneAltitude()
    }
    
    func stopDroneMonitors(){
        self.droneStateRef = nil
        self.droneBatteryInfoRef = nil
        self.pilotingItfRef = nil
        self.streamServerRef = nil
        self.liveStreamRef = nil
        self.droneAltitudeRef = nil
        
    }
    
    /// Monitors current drone piloting interface.
    private func monitorPilotingInterface() {
        pilotingItfRef = drone?.getPilotingItf(PilotingItfs.manualCopter) { [weak self] itf in
            // Called when the manual copter piloting Interface is available and when it changes.
            if let itf = itf {
                self?.managePilotingItfState(itf: itf)
            } else {
                // Disable the button if the piloting interface is not available.
                self?.landEnabled = false
                self?.takeOffEnabled = false
            }
        }
    }
    
    /// Manage piloting interface state
    private func managePilotingItfState(itf: ManualCopterPilotingItf) {
        switch itf.state {
        case ActivablePilotingItfState.unavailable:
            // Piloting interface is unavailable.
            self.landEnabled = false
            self.takeOffEnabled = false
            
        case ActivablePilotingItfState.idle:
            // Piloting interface is idle.
            self.landEnabled = false
            self.takeOffEnabled = false
            // Activate the interface.
            _ = itf.activate()
            
        case ActivablePilotingItfState.active:
            // Piloting interface is active.

            if itf.canTakeOff {
                // Drone can takeOff.
                self.takeOffEnabled = true
                self.delegate.onTakeOffAvaliable()
            } else if itf.canLand {
                // Drone can land.
                self.landEnabled = true
                self.delegate.onLandAvaliable()
            } else {
                // Disable the button.
                self.landEnabled = false
                self.takeOffEnabled = false
            }
        }
    }
    
    /// Monitor current drone state.
    private func monitorDroneState() {
       // Monitor current drone state.
       droneStateRef = drone?.getState { [weak self] state in
           // Called at each drone state update.
            if let self = self, let state = state {
                // update the connection state string
                self.delegate.onConnectionStatusUpdate(
                    state.connectionState.description
                )
            }
       }
    }
    
    private func monitorDroneAltitude(){
        droneAltitudeRef = drone?.getInstrument(Instruments.altimeter){
            [weak self] altimeter in
            if let self = self, let altimeter = altimeter {
                if(altimeter.takeoffRelativeAltitude != nil){
                    self.delegate.onAltitudeUpdate(altimeter.takeoffRelativeAltitude!)
                }
            }
        }
    }
    
    private func monitorDroneBatteryLevel(){
        droneBatteryInfoRef = drone?.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            // Called when the battery info instrument is available and when it changes.
            if let self = self, let batteryInfo = batteryInfo {
                self.delegate.onBatteryStatusUpdate(batteryInfo.batteryLevel)
            }
        }
    }
    

    
    private func startVideoStream() {
        // Monitor the stream server.
        streamServerRef = drone?.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in
            // Called when the stream server is available and when it changes.
            if let self = self, let streamServer = streamServer {
                // Enable Streaming
                streamServer.enabled = true
                self.liveStreamRef = streamServer.live { liveStream in
                    // Called when the live stream is available and when it changes.

                    if let liveStream = liveStream {
                        // Set the live stream as the stream to be render by the stream view.
                        self.delegate.onLiveStreamChange(liveStream)
                        
                        // Play the live stream.
                        _ = liveStream.play()
                    }
                }
            }
        }
    }

    func takeOff() {
        if(self.takeOffEnabled){
            if let itf = pilotingItfRef?.value{
                itf.takeOff()
            }
        }
    }
    
    func isTakeOffEnabled() -> Bool {
        return self.takeOffEnabled
    }
    
    func land() {
        if(self.landEnabled){
            if let itf = pilotingItfRef?.value{
                itf.land()
            }
        }
    }
    
    func isLandEnabled() -> Bool {
        return self.landEnabled
    }

}

