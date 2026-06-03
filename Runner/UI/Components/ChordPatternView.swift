import UIKit

class ChordPatternView: UIView {
    private let chordLabel = UILabel()
    private let notesLabel = UILabel()
    private let qualityLabel = UILabel()
    
    init(chord: String, notes: String, quality: String) {
        super.init(frame: .zero)
        setup(chord: chord, notes: notes, quality: quality)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(chord: "C", notes: "C E G", quality: "Major")
    }
    
    private func setup(chord: String, notes: String, quality: String) {
        // Background
        backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius16
        
        // Chord name (large)
        chordLabel.text = chord
        chordLabel.font = Typography.displayMedium
        chordLabel.textColor = StudioColors.purpleAccent
        chordLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chordLabel)
        
        // Notes (medium)
        notesLabel.text = notes
        notesLabel.font = Typography.bodyMedium
        notesLabel.textColor = StudioColors.textPrimary
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(notesLabel)
        
        // Quality (small)
        qualityLabel.text = quality
        qualityLabel.font = Typography.labelSmall
        qualityLabel.textColor = StudioColors.textSecondary
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(qualityLabel)
        
        // Layout
        let padding = StudioTheme.shared.spacing12
        
        NSLayoutConstraint.activate([
            chordLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            chordLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            
            notesLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            notesLabel.topAnchor.constraint(equalTo: chordLabel.bottomAnchor, constant: 4),
            
            qualityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            qualityLabel.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 4),
            qualityLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
}
