import Foundation

struct WhisperResponse: Codable {
    let text: String
    let language: String?
}

enum WhisperService {
    static func transcribe(fileURL: URL, apiKey: String) async throws -> WhisperResponse {
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Don't push the multipart audio upload over HTTP/3 (QUIC/UDP): large
        // bodies hit the datagram size limit and fail with EMSGSIZE
        // ("The operation couldn't be completed. Message too long").
        // assumesHTTP3Capable=false only suppresses HTTP/3 on the *first* request
        // to a host; URLSession.shared persists the server's HTTP/3 Alt-Svc hint
        // to disk and upgrades later requests anyway. A fresh ephemeral session
        // (no persisted hint) making a single request can never select HTTP/3.
        request.assumesHTTP3Capable = false
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let audioData = try Data(contentsOf: fileURL)
        var body = Data()

        // model field
        body.appendMultipart(boundary: boundary, name: "model", value: "whisper-1")

        // response_format field
        body.appendMultipart(boundary: boundary, name: "response_format", value: "verbose_json")

        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!
        )
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Use an upload task (streams the body) on a fresh ephemeral session so
        // HTTP/3 can never be selected for this large upload (see note above).
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.upload(for: request, from: body)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WhisperError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        return try JSONDecoder().decode(WhisperResponse.self, from: data)
    }

    enum WhisperError: LocalizedError {
        case invalidResponse
        case apiError(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from Whisper API"
            case .apiError(let statusCode, let message):
                return "API error (\(statusCode)): \(message)"
            }
        }
    }
}

private extension Data {
    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }
}
