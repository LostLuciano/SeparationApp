import Foundation

extension Notification.Name {
    static let projectStoreDidUpdate = Notification.Name("MusicXNAProjectStoreDidUpdate")
}

/// JSON-based project persistence using FileManager.
public class ProjectStore {
    
    public static let shared = ProjectStore()
    
    private let projectDirectory: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let lock = NSLock()
    
    public init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        projectDirectory = paths[0].appendingPathComponent("MusicXNA_Projects")
        try? FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
    }
    
    /// Save a project to JSON file
    public func save(_ project: StemProject) throws {
        lock.lock()
        let projectDir = projectDirectory.appendingPathComponent(project.id.uuidString)
        let jsonURL = projectDir.appendingPathComponent("project.json")

        do {
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
            let data = try encoder.encode(project)
            try data.write(to: jsonURL)
            lock.unlock()
        } catch {
            lock.unlock()
            throw error
        }

        NotificationCenter.default.post(
            name: .projectStoreDidUpdate,
            object: nil,
            userInfo: ["projectID": project.id]
        )
        
        print("ProjectStore: Saved project \(project.name) to \(jsonURL.path)")
    }
    
    /// Load a project by ID
    public func load(_ id: UUID) throws -> StemProject {
        lock.lock()
        defer { lock.unlock() }

        let projectDir = projectDirectory.appendingPathComponent(id.uuidString)
        let jsonURL = projectDir.appendingPathComponent("project.json")
        
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw NSError(domain: "ProjectStore", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Project not found"])
        }
        
        let data = try Data(contentsOf: jsonURL)
        let project = try decoder.decode(StemProject.self, from: data)
        return project
    }
    
    /// List all projects
    public func listProjects() -> [StemProject] {
        lock.lock()
        defer { lock.unlock() }

        var projects: [StemProject] = []
        
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: projectDirectory, includingPropertiesForKeys: nil) {
            
            for projectDir in contents {
                let jsonURL = projectDir.appendingPathComponent("project.json")
                if FileManager.default.fileExists(atPath: jsonURL.path),
                   let data = try? Data(contentsOf: jsonURL),
                   let project = try? decoder.decode(StemProject.self, from: data) {
                    projects.append(project)
                }
            }
        }
        
        // Sort by creation date (newest first)
        projects.sort { $0.createdDate > $1.createdDate }
        return projects
    }

    public func findReusableProject(sourceHash: String, requiredStems: [String]) -> StemProject? {
        listProjects().first { project in
            project.sourceHash == sourceHash &&
            project.status == .separated &&
            project.hasStems(requiredStems)
        }
    }
    
    /// Delete a project
    public func delete(_ id: UUID) throws {
        lock.lock()
        let projectDir = projectDirectory.appendingPathComponent(id.uuidString)

        do {
            try FileManager.default.removeItem(at: projectDir)
            lock.unlock()
        } catch {
            lock.unlock()
            throw error
        }

        NotificationCenter.default.post(
            name: .projectStoreDidUpdate,
            object: nil,
            userInfo: ["projectID": id]
        )
        print("ProjectStore: Deleted project \(id.uuidString)")
    }
    
    /// Get project count
    public func getProjectCount() -> Int {
        return listProjects().count
    }
}
