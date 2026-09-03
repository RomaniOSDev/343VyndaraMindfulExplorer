import Foundation

struct ChronicleEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var prompts: [String]
    var icon: String
    var theme: String
}

struct PromptRevision: Codable, Identifiable, Hashable {
    var id: UUID
    var prompt: String
    var savedAt: Date
}

struct PhotoPrompt: Codable, Identifiable, Hashable {
    var id: UUID
    var imageName: String
    var caption: String
    var prompt: String
    var updatedAt: Date
    var history: [PromptRevision]

    enum CodingKeys: String, CodingKey {
        case id, imageName, caption, prompt, updatedAt, history
    }

    init(id: UUID, imageName: String, caption: String, prompt: String, updatedAt: Date, history: [PromptRevision] = []) {
        self.id = id
        self.imageName = imageName
        self.caption = caption
        self.prompt = prompt
        self.updatedAt = updatedAt
        self.history = history
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        imageName = try c.decode(String.self, forKey: .imageName)
        caption = try c.decode(String.self, forKey: .caption)
        prompt = try c.decode(String.self, forKey: .prompt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        history = try c.decodeIfPresent([PromptRevision].self, forKey: .history) ?? []
    }
}

struct SceneCard: Identifiable, Hashable, Codable {
    let id: String
    let imageName: String
    let title: String
    let seedPrompt: String
    let tags: [String]
    var isCustom: Bool

    enum CodingKeys: String, CodingKey {
        case id, imageName, title, seedPrompt, tags, isCustom
    }

    init(id: String, imageName: String, title: String, seedPrompt: String, tags: [String], isCustom: Bool = false) {
        self.id = id
        self.imageName = imageName
        self.title = title
        self.seedPrompt = seedPrompt
        self.tags = tags
        self.isCustom = isCustom
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        imageName = try c.decode(String.self, forKey: .imageName)
        title = try c.decode(String.self, forKey: .title)
        seedPrompt = try c.decode(String.self, forKey: .seedPrompt)
        tags = try c.decode([String].self, forKey: .tags)
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
    }
}
