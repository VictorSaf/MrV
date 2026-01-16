import Foundation

/// Automatic decision detection from conversations
/// Analyzes text to identify and extract decisions
actor DecisionDetector {

    // MARK: - Decision Patterns

    private let decisionKeywords = [
        // Strong indicators
        "let's", "let us", "we should", "we'll", "we will",
        "i choose", "i'll choose", "i decided", "i'll go with",
        "we decided", "decision:", "decided to",

        // Medium indicators
        "going with", "opting for", "selecting", "picked",
        "prefer", "best option", "final decision",

        // Question forms (potential decisions)
        "should we", "shall we", "do you want to"
    ]

    private let alternativeKeywords = [
        "or", "alternatively", "instead", "rather than",
        "option", "choice", "alternative", "vs", "versus"
    ]

    private let rationaleKeywords = [
        "because", "since", "as", "given that",
        "the reason", "this is because", "due to"
    ]

    // MARK: - Detection

    /// Detect if a conversation contains a decision
    func detectDecision(from conversation: ConversationMemory) async -> DecisionLog? {
        let combined = conversation.userInput + " " + conversation.aiResponse
        let lowercased = combined.lowercased()

        // Check for decision keywords
        let hasDecisionKeyword = decisionKeywords.contains { keyword in
            lowercased.contains(keyword)
        }

        guard hasDecisionKeyword else {
            return nil
        }

        // Extract decision components
        let decisionText = extractDecisionText(from: combined, lowercased: lowercased)
        guard !decisionText.isEmpty else {
            return nil
        }

        let rationale = extractRationale(from: combined, lowercased: lowercased)
        let alternatives = extractAlternatives(from: combined, lowercased: lowercased)
        let owner = determineOwner(userInput: conversation.userInput, aiResponse: conversation.aiResponse, decisionText: decisionText)

        // Create decision log
        return DecisionLog(
            projectId: conversation.projectId,
            timestamp: conversation.timestamp,
            decisionText: decisionText,
            rationale: rationale,
            alternatives: alternatives,
            owner: owner,
            tags: extractTags(from: decisionText),
            metadata: DecisionLog.DecisionMetadata(
                importance: calculateImportance(decisionText: decisionText, alternatives: alternatives),
                reversible: true,
                relatedConversationIds: [conversation.id]
            )
        )
    }

    // MARK: - Extraction Methods

    private func extractDecisionText(from text: String, lowercased: String) -> String {
        // Find sentences containing decision keywords
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))

        for sentence in sentences {
            let sentenceLower = sentence.lowercased()
            if decisionKeywords.contains(where: { sentenceLower.contains($0) }) {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 10 && trimmed.count < 300 {
                    return trimmed
                }
            }
        }

        // Fallback: return first sentence with decision keyword
        if let first = sentences.first(where: { sent in
            decisionKeywords.contains { sent.lowercased().contains($0) }
        }) {
            return first.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ""
    }

    private func extractRationale(from text: String, lowercased: String) -> String? {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))

        // Look for sentences with rationale keywords
        for (index, sentence) in sentences.enumerated() {
            let sentenceLower = sentence.lowercased()

            // Check if this sentence explains why
            if rationaleKeywords.contains(where: { sentenceLower.contains($0) }) {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 15 && trimmed.count < 500 {
                    return trimmed
                }
            }

            // Check if previous sentence was a decision and this explains it
            if index > 0 {
                let prevSentence = sentences[index - 1].lowercased()
                if decisionKeywords.contains(where: { prevSentence.contains($0) }) {
                    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.count > 15 && trimmed.count < 500 {
                        return trimmed
                    }
                }
            }
        }

        return nil
    }

    private func extractAlternatives(from text: String, lowercased: String) -> [DecisionLog.Alternative] {
        var alternatives: [DecisionLog.Alternative] = []

        // Look for "X or Y" patterns
        let orPatterns = text.components(separatedBy: " or ")
        if orPatterns.count > 1 {
            for (index, option) in orPatterns.enumerated() {
                let trimmed = option.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: CharacterSet(charactersIn: ".,!?\n"))
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if trimmed.count > 3 && trimmed.count < 100 {
                    alternatives.append(DecisionLog.Alternative(
                        option: trimmed,
                        wasChosen: index == 0  // Assume first option chosen
                    ))
                }
            }
        }

        // Look for numbered options (simple pattern)
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let lineLower = line.lowercased()
            if lineLower.contains("option") && (line.contains(":") || line.contains("-")) {
                // Extract text after "option 1:", "option 2:", etc.
                if let colonIndex = line.firstIndex(of: ":") {
                    let afterColon = String(line[line.index(after: colonIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if afterColon.count > 3 && afterColon.count < 200 {
                        alternatives.append(DecisionLog.Alternative(option: afterColon))
                    }
                } else if let dashIndex = line.firstIndex(of: "-") {
                    let afterDash = String(line[line.index(after: dashIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if afterDash.count > 3 && afterDash.count < 200 {
                        alternatives.append(DecisionLog.Alternative(option: afterDash))
                    }
                }
            }
        }

        return alternatives
    }

    private func determineOwner(userInput: String, aiResponse: String, decisionText: String) -> DecisionLog.DecisionOwner {
        let userLower = userInput.lowercased()
        let aiLower = aiResponse.lowercased()
        let decisionLower = decisionText.lowercased()

        // Check if decision text appears in user input
        if userLower.contains(decisionLower) {
            return .user
        }

        // Check if decision text appears in AI response
        if aiLower.contains(decisionLower) {
            // Check for collaborative phrases
            if decisionLower.contains("we") || decisionLower.contains("let's") || decisionLower.contains("together") {
                return .collaborative
            }
            return .ai
        }

        // Check for collaborative indicators
        if decisionLower.contains("we ") || decisionLower.contains("our ") {
            return .collaborative
        }

        // Check for first-person indicators
        if decisionLower.contains("i ") || decisionLower.contains("my ") {
            return .user
        }

        return .collaborative  // Default
    }

    private func extractTags(from text: String) -> [String] {
        var tags: [String] = []

        // Technical tags
        let technicalTerms = ["architecture", "api", "database", "frontend", "backend", "design", "testing", "deployment", "performance", "security"]
        for term in technicalTerms {
            if text.lowercased().contains(term) {
                tags.append(term)
            }
        }

        // Process tags
        let processTerms = ["planning", "implementation", "review", "refactor", "optimization", "bugfix"]
        for term in processTerms {
            if text.lowercased().contains(term) {
                tags.append(term)
            }
        }

        return Array(Set(tags))  // Remove duplicates
    }

    private func calculateImportance(decisionText: String, alternatives: [DecisionLog.Alternative]) -> Int {
        var score = 3  // Default medium importance

        let text = decisionText.lowercased()

        // Increase importance for critical terms
        let criticalTerms = ["architecture", "database", "api", "security", "production", "breaking", "major"]
        for term in criticalTerms {
            if text.contains(term) {
                score += 1
            }
        }

        // Increase for multiple alternatives (shows careful consideration)
        if alternatives.count >= 2 {
            score += 1
        }

        // Decrease for minor decisions
        let minorTerms = ["typo", "rename", "small", "minor", "trivial"]
        for term in minorTerms {
            if text.contains(term) {
                score -= 1
            }
        }

        return min(5, max(1, score))  // Clamp to 1-5
    }

    // MARK: - Batch Processing

    /// Analyze multiple conversations and extract decisions
    func detectDecisionsFromBatch(_ conversations: [ConversationMemory]) async -> [DecisionLog] {
        var decisions: [DecisionLog] = []

        for conversation in conversations {
            if let decision = await detectDecision(from: conversation) {
                decisions.append(decision)
            }
        }

        return decisions
    }

    // MARK: - Pattern Learning (Future Enhancement)

    /// Learn decision patterns from existing labeled decisions
    func learnFromLabeled(decisions: [DecisionLog], conversations: [ConversationMemory]) async {
        // TODO Phase 3: Implement ML-based pattern learning
        // This would analyze labeled decisions to improve detection accuracy
    }
}
