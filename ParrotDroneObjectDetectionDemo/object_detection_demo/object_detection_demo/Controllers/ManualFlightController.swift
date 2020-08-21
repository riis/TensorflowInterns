import GroundSdk

class ManualFlightController : UIViewController{
    @IBOutlet weak var connectionStatus:UILabel!
    @IBOutlet weak var batteryLevel:UILabel!
    @IBOutlet weak var streamView:StreamView!
    @IBOutlet weak var altitudeLabel:UILabel!
    
    @IBOutlet weak var takeOffBtn: UIButton!
    
    @IBOutlet weak var overlayView:OverlayView!
    
    @IBOutlet weak var remoteConnectionStatus:UILabel!
    
    @IBOutlet weak var objectCountLabel:UILabel!
    
    private var modelDataHandler: ModelDataHandler? =
      ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo)
    
    private let displayFont = UIFont.systemFont(ofSize: 12.0, weight: .medium)
    private let edgeOffset: CGFloat = 2.0
    private let labelOffset: CGFloat = 10.0
    
    private var shouldCaptureImage:Bool = true
    
    enum takeOffState{
        case takeOffEnabled
        case landEnabled
        case buttonDisabled
    }
    
    private var takeOffBtnState = takeOffState.buttonDisabled
    
    private var droneManager:DroneManagerProtocol!
    
    override func viewDidLoad() {
        overlayView.backgroundColor = UIColor(white: 1, alpha: 0.0)
        droneManager = DroneManager(self)
        droneManager.startDrone()
        updateButtonState()
    }
    
    func updateButtonState(){
        switch takeOffBtnState{
            case .buttonDisabled:
                self.takeOffBtn.isEnabled = false
            case .landEnabled:
                self.takeOffBtn.isEnabled = true
                self.takeOffBtn.setTitle("Land", for: .normal)
            case .takeOffEnabled:
                self.takeOffBtn.isEnabled = true
                self.takeOffBtn.setTitle("Take Off", for: .normal)
        }
    }
    
    @IBAction func takeOffBtnAction(_ sender: Any){
        switch takeOffBtnState{
            case .buttonDisabled:
                self.takeOffBtn.isEnabled = false
            case .landEnabled:
                self.droneManager.land()
            case .takeOffEnabled:
                self.droneManager.takeOff()
        }
    }
}

extension ManualFlightController: DroneDelegate{
    func onRemoteConnectionStatusUpdate(_ connectionStatus: String) {
        self.remoteConnectionStatus.text = connectionStatus
    }
    
    func onRemoteBatteryStatusUpdate(_ batteryLevel: Int) {
        print(batteryLevel)
    }
    
    func onTakeOffAvaliable() {
        self.takeOffBtnState = .takeOffEnabled
        updateButtonState()
    }
    
    func onLandAvaliable() {
        self.takeOffBtnState = .landEnabled
        updateButtonState()
    }
    
    func onAltitudeUpdate(_ altitude: Double) {
        self.altitudeLabel.text = "Altitude: \(altitude)m"
    }
    
    func onConnectionStatusUpdate(_ connectionStatus: String) {
        self.connectionStatus.text = connectionStatus
    }
    
    func onBatteryStatusUpdate(_ batteryLevel: Int) {
        self.batteryLevel.text = "\(batteryLevel)%"
    }
    
    func onLiveStreamChange(_ stream: Stream?) {
        self.streamView.setStream(stream: stream)
        if(stream != nil){
            captureImage()
        }
        
    }
}

// Handle Image processing and the overlay
extension ManualFlightController{

    func captureImage(){
        // captures the current frame of the video feed as an imagz
        let fps = 2.0
        let seconds = 1.0 / fps
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.processImage(self.streamView.snapshot)
            self.captureImage()
        }
    }
    
    func processImage(_ image:UIImage){
        let pixelBuffer:CVPixelBuffer = image.pixelBuffer()!
            overlayView.backgroundColor = UIColor(white: 1, alpha: 0.0)
            guard let inferences = self.modelDataHandler?.runModel(onFrame: pixelBuffer) else {
            return
        }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        DispatchQueue.main.async {
            self.objectCountLabel.text = "Object Count: \(inferences.count)"
            // Draws the bounding boxes and displays class names and confidence scores.
            self.drawAfterPerformingCalculations(onInferences: inferences, withImageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
        }
    }
    
    func drawAfterPerformingCalculations(onInferences inferences: [Inference], withImageSize imageSize:CGSize) {
 
       self.overlayView.objectOverlays = []
       self.overlayView.setNeedsDisplay()

       guard !inferences.isEmpty else {
         return
       }

       var objectOverlays: [ObjectOverlay] = []

       for inference in inferences {

         // Translates bounding box rect to current view.
         var convertedRect = inference.rect.applying(CGAffineTransform(scaleX: self.overlayView.bounds.size.width / imageSize.width, y: self.overlayView.bounds.size.height / imageSize.height))

         if convertedRect.origin.x < 0 {
           convertedRect.origin.x = self.edgeOffset
         }

         if convertedRect.origin.y < 0 {
           convertedRect.origin.y = self.edgeOffset
         }

         if convertedRect.maxY > self.overlayView.bounds.maxY {
           convertedRect.size.height = self.overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset
         }

         if convertedRect.maxX > self.overlayView.bounds.maxX {
           convertedRect.size.width = self.overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset
         }

         let confidenceValue = Int(inference.confidence * 100.0)
         let string = "\(inference.className)  (\(confidenceValue)%)"

         let size = string.size(usingFont: self.displayFont)

         let objectOverlay = ObjectOverlay(name: string, borderRect: convertedRect, nameStringSize: size, color: inference.displayColor, font: self.displayFont)

         objectOverlays.append(objectOverlay)
       }

       // Hands off drawing to the OverlayView
       self.draw(objectOverlays: objectOverlays)

     }

     /** Calls methods to update overlay view with detected bounding boxes and class names.
      */
     func draw(objectOverlays: [ObjectOverlay]) {
       self.overlayView.objectOverlays = objectOverlays
       self.overlayView.setNeedsDisplay()
     }
    
}
