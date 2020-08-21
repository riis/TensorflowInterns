import GroundSdk

protocol DroneDelegate{
    // called when there is an update to the connetion status string
    func onConnectionStatusUpdate(_ connectionStatus:String) -> Void
    
    //sends in the battery level of the drone from 0 to 100
    func onBatteryStatusUpdate(_ batteryLevel:Int) -> Void
    
    // called when the live feed changes
    func onLiveStreamChange(_ stream: Stream?) -> Void
    
    // called when the altitude of the drone changes.
    func onAltitudeUpdate(_ altitude: Double) -> Void
    
    func onTakeOffAvaliable() -> Void
    
    func onLandAvaliable() -> Void
    
    func onRemoteConnectionStatusUpdate(_ connectionStatus: String) -> Void
    
    func onRemoteBatteryStatusUpdate(_ batteryLevel:Int) -> Void
}
