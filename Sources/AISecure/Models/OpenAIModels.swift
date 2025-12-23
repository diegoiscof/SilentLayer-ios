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
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [OpenAIChatChoice]
    public let usage: OpenAIUsage?

    public struct OpenAIChatChoice: Codable, Sendable {
        public let index: Int
        public let message: OpenAIChatMessage
        public let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    public struct OpenAIChatMessage: Codable, Sendable {
        public let role: String
        public let content: String
    }
}

public struct OpenAIUsage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Embeddings

public struct OpenAIEmbeddingsResponse: Codable, Sendable {
    public let object: String
    public let data: [OpenAIEmbedding]
    public let model: String
    public let usage: OpenAIUsage

    public struct OpenAIEmbedding: Codable, Sendable {
        public let object: String
        public let embedding: [Double]
        public let index: Int
    }
}
