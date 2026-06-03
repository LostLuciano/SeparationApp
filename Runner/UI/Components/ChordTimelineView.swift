import UIKit

class ChordTimelineView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var chordButtons: [UIButton] = []
    
    var onChordSelected: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Background
        backgroundColor = UIColor(white: 1.0, alpha: 0.03)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        layer.cornerRadius = StudioTheme.shared.cornerRadius12
        
        // Scroll view
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // Stack view
        stackView.axis = .horizontal
        stackView.spacing = StudioTheme.shared.spacing8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Layout
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            
            heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func addChord(_ chord: String, index: Int) {
        let button = UIButton(type: .system)
        button.setTitle(chord, for: .normal)
        button.titleLabel?.font = Typography.labelMedium
        button.tag = index
        
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(white: 1.0, alpha: 0.15).cgColor
        button.layer.cornerRadius = StudioTheme.shared.cornerRadius12
        
        button.setTitleColor(StudioColors.textSecondary, for: .normal)
        button.setTitleColor(StudioColors.purpleAccent, for: .selected)
        
        button.addTarget(self, action: #selector(chordTapped(_:)), for: .touchUpInside)
        
        button.widthAnchor.constraint(equalToConstant: 60).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        stackView.addArrangedSubview(button)
        chordButtons.append(button)
    }
    
    @objc private func chordTapped(_ sender: UIButton) {
        // Deselect all
        for button in chordButtons {
            button.isSelected = false
            button.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        }
        
        // Select tapped
        sender.isSelected = true
        sender.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        
        onChordSelected?(sender.tag)
    }
    
    func setSelectedChord(at index: Int) {
        guard index < chordButtons.count else { return }
        chordTapped(chordButtons[index])
    }
}
