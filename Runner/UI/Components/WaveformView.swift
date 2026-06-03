import UIKit
import Accelerate

class WaveformView: UIView {
    private var waveformData: [Float] = []
    private var currentPlaybackPosition: CGFloat = 0
    
    var onSeek: ((TimeInterval) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        layer.cornerRadius = StudioTheme.shared.cornerRadius12
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        
        // Tap to seek
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    func loadWaveform(from audioURL: URL, duration: TimeInterval) {
        DispatchQueue.global().async { [weak self] in
            if let waveform = self?.generateWaveform(from: audioURL, duration: duration) {
                DispatchQueue.main.async {
                    self?.waveformData = waveform
                    self?.setNeedsDisplay()
                }
            }
        }
    }
    
    func updatePlaybackPosition(_ position: CGFloat) {
        currentPlaybackPosition = position
        setNeedsDisplay()
    }
    
    private func generateWaveform(from url: URL, duration: TimeInterval) -> [Float]? {
        // Simplified waveform generation - would use AVAudioFile in production
        var samples: [Float] = Array(repeating: 0, count: 200)
        
        // Generate pseudo-waveform for demo (0-1 range)
        for i in 0..<samples.count {
            let phase = Float(i) / Float(samples.count)
            samples[i] = abs(sin(phase * Float.pi * 2)) * 0.7 + 0.1
        }
        
        return samples
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let seekFraction = point.x / bounds.width
        onSeek?(Double(seekFraction))
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !waveformData.isEmpty else { return }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(StudioColors.purpleAccent.cgColor)
        
        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        let barWidth = width / CGFloat(waveformData.count)
        
        for (index, sample) in waveformData.enumerated() {
            let x = CGFloat(index) * barWidth + barWidth / 2
            let barHeight = CGFloat(sample) * (height * 0.4)
            
            let barRect = CGRect(
                x: x - barWidth / 3,
                y: centerY - barHeight / 2,
                width: barWidth * 2 / 3,
                height: barHeight
            )
            
            context?.fillEllipse(in: barRect)
        }
        
        // Draw playback position
        let positionX = currentPlaybackPosition * width
        context?.setStrokeColor(StudioColors.purpleAccent.withAlphaComponent(0.8).cgColor)
        context?.setLineWidth(2)
        context?.move(to: CGPoint(x: positionX, y: 0))
        context?.addLine(to: CGPoint(x: positionX, y: height))
        context?.strokePath()
    }
}
