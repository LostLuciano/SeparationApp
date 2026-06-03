import UIKit

class LyricsKaraokeView: UIView {
    private let tableView = UITableView()
    private var lyrics: [String] = []
    private var currentLineIndex: Int = 0
    
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
        
        // Table view
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LyricCell")
        addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func loadLyrics(_ newLyrics: [String]) {
        lyrics = newLyrics
        tableView.reloadData()
    }
    
    func updateCurrentLine(_ index: Int) {
        currentLineIndex = index
        tableView.reloadData()
        
        if !lyrics.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension LyricsKaraokeView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyrics.isEmpty ? 1 : lyrics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LyricCell", for: indexPath)
        cell.backgroundColor = .clear
        
        if lyrics.isEmpty {
            cell.textLabel?.text = "No lyrics available"
            cell.textLabel?.font = Typography.bodySmall
            cell.textLabel?.textColor = StudioColors.textTertiary
        } else {
            cell.textLabel?.text = lyrics[indexPath.row]
            cell.textLabel?.font = Typography.bodyLarge
            cell.textLabel?.textColor = (indexPath.row == currentLineIndex) ? StudioColors.purpleAccent : StudioColors.textSecondary
            cell.textLabel?.textAlignment = .center
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LyricsKaraokeView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
