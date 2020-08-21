import Foundation

protocol DroneManagerProtocol {
    // connects to the drone and starts the monitors
    func startDrone() -> Void
    
    // Launches the drone if takeoff is enabled
    func takeOff() -> Void
    
    func isTakeOffEnabled() -> Bool
    
    // lands the drone if land is enabled
    func land() -> Void
    
    func isLandEnabled() -> Bool
}
