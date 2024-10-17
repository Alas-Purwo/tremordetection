import SwiftUI
import CoreMotion

class TremorDetectionViewModel: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var isTremorDetected: Bool = false
    @Published var tremorLevel: Double = 0.0
    private var previousAcceleration: CMAcceleration?
    private var tremorStartTime: Date?

    init() {
        motionManager.accelerometerUpdateInterval = 0.05 // 20 Hz update interval for higher frequency data
    }

    func startTremorDetection() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available")
            return
        }

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self else { return }
            if let error = error {
                print("Accelerometer error: \(error.localizedDescription)")
                return
            }

            if let accelerometerData = data {
                let currentAcceleration = accelerometerData.acceleration
                if let previousAcceleration = self.previousAcceleration {
                    // Calculate the difference between the current and previous accelerations
                    let deltaX = currentAcceleration.x - previousAcceleration.x
                    let deltaY = currentAcceleration.y - previousAcceleration.y
                    let deltaZ = currentAcceleration.z - previousAcceleration.z
                    let tremorMagnitude = sqrt(pow(deltaX, 2) + pow(deltaY, 2) + pow(deltaZ, 2))

                    // Lower threshold to detect smaller tremors
                    let tremorThreshold = 0.1

                    if tremorMagnitude > tremorThreshold {
                        if self.tremorStartTime == nil {
                            self.tremorStartTime = Date()
                        } else if let startTime = self.tremorStartTime, Date().timeIntervalSince(startTime) > 1 {
                            self.isTremorDetected = true
                        }
                    } else {
                        self.tremorStartTime = nil
                        self.isTremorDetected = false
                    }

                    self.tremorLevel = tremorMagnitude
                }
                // Update the previous acceleration
                self.previousAcceleration = currentAcceleration
            }
        }
    }

    func stopTremorDetection() {
        motionManager.stopAccelerometerUpdates()
        tremorStartTime = nil
        isTremorDetected = false
    }
}

struct TremorDetectionView: View {
    @StateObject private var viewModel = TremorDetectionViewModel()
    @State private var isDetecting: Bool = false

    var body: some View {
        VStack {
            Text("Tremor Detection")
                .font(.headline)
                .padding()

            if viewModel.isTremorDetected {
                Text("Tremor Detected")
                    .foregroundColor(.red)
                    .font(.title)
                    .padding()
            } else {
                Text("No Tremor Detected")
                    .foregroundColor(.green)
                    .font(.title)
                    .padding()
            }

            Text("Tremor Level: \(viewModel.tremorLevel, specifier: "%.4f")")
                .padding()

            Button(action: {
                isDetecting.toggle()
                if isDetecting {
                    viewModel.startTremorDetection()
                } else {
                    viewModel.stopTremorDetection()
                }
            }) {
                Text(isDetecting ? "Stop Detection" : "Start Detection")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isDetecting ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// Preview
struct TremorDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        TremorDetectionView()
    }
}
