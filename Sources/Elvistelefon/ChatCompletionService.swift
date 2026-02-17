import Foundation

enum ChatCompletionService {
    private struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [RequestMessage]
        let temperature: Double
        let max_tokens: Int
    }

    private struct RequestMessage: Encodable {
        let role: String
        let content: String
    }

    private struct ChatCompletionResponse: Decodable {
        let choices: [Choice]
    }

    private struct Choice: Decodable {
        let message: ResponseMessage
    }

    private struct ResponseMessage: Decodable {
        let content: String
    }

    static func transform(
        text: String,
        systemPrompt: String,
        apiKey: String,
        model: String = "gpt-4.1-mini"
    ) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                RequestMessage(role: "system", content: systemPrompt),
                RequestMessage(role: "user", content: text),
            ],
            temperature: 0.7,
            max_tokens: 1024
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatCompletionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChatCompletionError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatCompletionError.emptyResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum ChatCompletionError: LocalizedError {
        case invalidResponse
        case apiError(statusCode: Int, message: String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from Chat API"
            case .apiError(let statusCode, let message):
                return "Chat API error (\(statusCode)): \(message)"
            case .emptyResponse:
                return "Empty response from Chat API"
            }
        }
    }
}
