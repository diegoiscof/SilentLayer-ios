//
//  OpenAIModels.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

// MARK: - Chat Models

public struct OpenAIChatResponse: Codable, Sendable {
    public let id: String
    public let choices: [Choice]
    public let usage: Usage

    public struct Choice: Codable, Sendable {
        public let message: ChatMessage
        public let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    public struct Usage: Codable, Sendable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Embeddings Models

public struct OpenAIEmbeddingsResponse: Codable, Sendable {
    public let data: [Embedding]
    public let usage: Usage

    public struct Embedding: Codable, Sendable {
        public let embedding: [Double]
        public let index: Int
    }

    public struct Usage: Codable, Sendable {
        public let promptTokens: Int
        public let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Image Models

public struct OpenAIImageResponse: Codable, Sendable {
    public let created: Int
    public let data: [ImageData]

    public struct ImageData: Codable, Sendable {
        public let url: String?
        public let b64Json: String?

        enum CodingKeys: String, CodingKey {
            case url
            case b64Json = "b64_json"
        }
    }
}

// MARK: - Audio Models

public struct OpenAITranscriptionResponse: Codable, Sendable {
    public let text: String
}

// MARK: - Moderation Models

public struct OpenAIModerationResponse: Codable, Sendable {
    public let id: String
    public let model: String
    public let results: [Result]

    public struct Result: Codable, Sendable {
        public let flagged: Bool
        public let categories: [String: Bool]
        public let categoryScores: [String: Double]

        enum CodingKeys: String, CodingKey {
            case flagged
            case categories
            case categoryScores = "category_scores"
        }
    }
}
