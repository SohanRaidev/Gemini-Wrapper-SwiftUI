// Replace "<YOUR_API_KEY>" with your actual Gemini API key.

import Foundation
import SwiftUI
import UIKit
import Combine
import Network

// MARK: - Legacy API Structures

// API request structure to handle both text and images
struct LegacyRequest: Codable {
    let model: String
    let messages: [LegacyMessage]
    let max_tokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case max_tokens
        case temperature
    }
    
    init(model: String, messages: [LegacyMessage], max_tokens: Int = 1000, temperature: Double = 0.7) {
        self.model = model
        self.messages = messages
        self.max_tokens = max_tokens
        self.temperature = temperature
    }
}

// Structure for messages in API requests
struct LegacyMessage: Codable {
    let role: String
    var content: MessageContent // Can be String or array of ContentItem objects
    
    init(from chatMessage: ChatMessage) {
        self.role = chatMessage.role.rawValue
        
        if let image = chatMessage.image {
            // For messages with images, create a content array with both text and image
            let textContent = ContentItem(type: "text", text: chatMessage.content ?? "What is this?")
            
            // Convert the image to base64
            // More aggressive resizing to ensure successful API calls
            var resizedImage = image
            
            // Check if image is very large and resize more aggressively
            let maxDimension: CGFloat = 1200 // Keep images under 1200px for more reliable API calls
            if image.size.width > maxDimension || image.size.height > maxDimension {
                if image.size.width > image.size.height {
                    resizedImage = image.resized(toWidth: maxDimension) ?? image
                } else {
                    resizedImage = image.resized(toHeight: maxDimension) ?? image
                }
                print("Resized large image to \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height))")
            }
            
            // Try to get JPEG data with progressively decreasing quality if needed
            func getImageData() -> Data? {
                // Try different compression levels, starting with 0.7
                let compressionLevels: [CGFloat] = [0.7, 0.5, 0.3, 0.2]
                
                for level in compressionLevels {
                    if let data = resizedImage.jpegData(compressionQuality: level) {
                        let sizeInKB = data.count / 1024
                        // If the data is less than 1MB, it's good enough
                        if sizeInKB < 1024 {
                            print("Image compressed to \(sizeInKB) KB at quality \(level)")
                            return data
                        } else {
                            print("Image at quality \(level) is still \(sizeInKB) KB, trying lower quality...")
                        }
                    }
                }
                
                // If we get here, none of the compression levels produced small enough data
                // Try one last attempt with tiny size and lowest quality
                if resizedImage.size.width > 800 || resizedImage.size.height > 800 {
                    if let smallerImage = resizedImage.resized(toWidth: 800) {
                        return smallerImage.jpegData(compressionQuality: 0.2)
                    }
                }
                
                // Last resort - use whatever we can get
                return resizedImage.jpegData(compressionQuality: 0.2)
            }
            
            if let imageData = getImageData() {
                let base64String = imageData.base64EncodedString()
                let imageURL = "data:image/jpeg;base64,\(base64String)"
                let imageContent = ContentItem(type: "image_url", imageUrl: ImageUrl(url: imageURL))
                
                print("Final image data size: \(imageData.count / 1024) KB")
                
                // Always include both text and image content
                self.content = .array([textContent, imageContent])
            } else {
                // Fallback to text-only if image encoding fails
                print("Failed to encode image to JPEG")
                self.content = .string(chatMessage.content ?? "(Image processing failed)")
            }
        } else {
            // For text-only messages
            self.content = .string(chatMessage.content ?? "")
        }
    }
}

// Enum to handle either a string or array of content items
enum MessageContent: Codable {
    case string(String)
    case array([ContentItem])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([ContentItem].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, 
                debugDescription: "Cannot decode MessageContent"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        }
    }
}

// Content item for text or image URL
struct ContentItem: Codable {
    let type: String
    let text: String?
    let imageUrl: ImageUrl?
    
    init(type: String, text: String? = nil) {
        self.type = type
        self.text = text
        self.imageUrl = nil
    }
    
    init(type: String, imageUrl: ImageUrl) {
        self.type = type
        self.text = nil
        self.imageUrl = imageUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageUrl = "image_url"
    }
}

// Image URL structure for Vision API
struct ImageUrl: Codable {
    let url: String
}

// MARK: - Legacy Response Structure
struct LegacyResponse: Codable {
    let choices: [LegacyChoice]
    let usage: Usage?
}

struct LegacyChoice: Codable {
    let index: Int
    let message: LegacyResponseMessage
    let finish_reason: String?
}

struct LegacyResponseMessage: Codable {
    let role: String
    let content: String?
}

struct Usage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

// MARK: - Gemini API Structures

// Gemini API request structure
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig
    
    enum CodingKeys: String, CodingKey {
        case contents
        case generationConfig = "generation_config"
    }
}

struct GenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "max_output_tokens"
        case topP = "top_p"
    }
    
    init(temperature: Double = 0.7, maxOutputTokens: Int = 1024, topP: Double = 0.95) {
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
        self.topP = topP
    }
}

struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: InlineData?
    
    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
    
    init(text: String) {
        self.text = text
        self.inlineData = nil
    }
    
    init(imageData: Data, mimeType: String = "image/jpeg") {
        self.text = nil
        self.inlineData = InlineData(mimeType: mimeType, data: imageData.base64EncodedString())
    }
}

struct InlineData: Codable {
    let mimeType: String
    let data: String
    
    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

// Gemini API response structure
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: PromptFeedback?
    
    enum CodingKeys: String, CodingKey {
        case candidates
        case promptFeedback = "promptFeedback"
    }
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case finishReason = "finish_reason"
    }
}

struct PromptFeedback: Codable {
    let blockReason: String?
    
    enum CodingKeys: String, CodingKey {
        case blockReason = "block_reason"
    }
}

// MARK: - Chat Model

class ChatModel: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var messages: [ChatMessage] = []
    @Published var isSending: Bool = false
    @Published var title: String? = nil
    @Published var date: Date

    // --- Gemini API Configuration ---
    private let geminiAPIKey = "<YOUR_API_KEY>" 
    private let geminiModel = "gemini-2.0-flash" // Using stable model
    private let maxRetries = 5  // Increased retries for better reliability
    
    // API request tracking moved from static to instance properties
    private var consecutiveEmptyResponses = 0
    private var consecutiveSuccessfulResponses = 0
    private var lastRequestTime: Date?
    
    // Replace session rotation with a stable session configuration
    private lazy var sessionManager: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        // Force HTTP/2 instead of QUIC/HTTP/3 which is having issues
        config.httpMaximumConnectionsPerHost = 1
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        // Add request headers that could help with connectivity
        config.httpAdditionalHeaders = [
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive"
        ]
        return URLSession(configuration: config)
    }()
    
    // Base URL for Gemini API with fallback system
    private var geminiEndpointURL: URL {
        // Fall back to pro model for reliability
        let modelToUse = self.consecutiveEmptyResponses >= 1 ? "gemini-2.0-flash" : geminiModel
        
        if let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelToUse):generateContent?key=\(geminiAPIKey)") {
            return url
        } else {
            return URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(geminiAPIKey)")!
        }
    }
    
    // Prevent duplicate error messages
    private var errorDisplayed = false

    private var cancellables = Set<AnyCancellable>() // For managing network requests

    enum CodingKeys: String, CodingKey {
        case id
        case messages
        // isSending is transient state, usually not saved
        case title
        case date
    }

    init(id: UUID = UUID(), messages: [ChatMessage] = [], isSending: Bool = false, title: String? = nil, date: Date = Date()) {
        self.id = id
        self.messages = messages
        self.isSending = isSending
        self.title = title
        self.date = date
    }

    // MARK: - Codable Conformance

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        // isSending is initialized to false by default
        title = try container.decodeIfPresent(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        // Do not encode isSending
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
    }

    // MARK: - Sending Message

    func sendMessage(role: MessageRole = .user, content: String? = nil, image: UIImage? = nil) {
        // Reset error state
        self.errorDisplayed = false
        
        // Reset consecutive errors to reduce backoff pressure
        if self.consecutiveEmptyResponses > 1 {
            self.consecutiveEmptyResponses = 1
        }
        
        // Append the user's message immediately
        appendMessage(role: role, content: content, image: image)
        self.isSending = true
        
        // Add a more robust delay based on connection history
        let timeSinceLastRequest = self.lastRequestTime != nil ? 
            Date().timeIntervalSince(self.lastRequestTime!) : 10.0
        
        // If we've had recent issues, add more delay
        let requestDelay = (self.consecutiveEmptyResponses > 0 || timeSinceLastRequest < 3.0) ? 3.0 : 1.0
        
        if requestDelay > 1.0 {
            print("Adding delay of \(requestDelay) seconds before API request")
        }
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + requestDelay) { [weak self] in
            guard let self = self else { return }
            
            // Create a gemini contents array for the API call
            var contents: [GeminiContent] = []
            
            // Improved filtering logic for including relevant messages
            var relevantMessages: [ChatMessage] = []

            // First check if we have any user message with an image
            let imageMessages = self.messages.filter { $0.role == .user && $0.image != nil }

            if !imageMessages.isEmpty {
                // We have at least one image message - prioritize the most recent one
                if let mostRecentImageMessage = imageMessages.last {
                    print("Found user message with image - using this as primary input")
                    relevantMessages.append(mostRecentImageMessage)
                    
                    // Add a few recent text messages for context if they exist
                    let textMessagesForContext = self.messages.filter { 
                        $0.id != mostRecentImageMessage.id && // Not the image message
                        $0.role != .system && // Not a system message
                        $0.content != nil && !$0.content!.isEmpty // Has content
                    }.suffix(4) // Get up to 4 most recent (reduced from 5)
                    
                    relevantMessages.append(contentsOf: textMessagesForContext)
                }
            } else {
                // No image messages - just use recent conversation history
                // Include fewer messages for more reliable completion
                relevantMessages = self.messages.filter {
                    ($0.role == .user || $0.role == .assistant) && // User or assistant messages only
                    $0.content != nil && !$0.content!.isEmpty // Has content
                }.suffix(8).map { $0 } // Get last 8 messages (reduced from 10)
            }
            
            // If we still don't have any relevant messages, display an error
            if relevantMessages.isEmpty {
                print("Error: No valid messages to send after filtering.")
                DispatchQueue.main.async {
                    self.isSending = false
                    self.appendMessage(role: .system, content: "Error: Nothing to send. Please provide a message or image.")
                }
                return
            }
            
            print("Sending \(relevantMessages.count) relevant messages to API")
            
            // Convert relevant messages to Gemini format
            for message in relevantMessages {
                contents.append(convertToGeminiContent(from: message))
            }
            
            // Add model instructions as a regular user message (Gemini doesn't support system role)
            // Add this as the first message in the conversation
            let hasImage = relevantMessages.contains { $0.image != nil }
            let instructionPrompt = hasImage 
                ? "You are a helpful AI assistant that can have natural conversations. If there's an image in the conversation: 1) First briefly describe what you see in the image, 2) Then respond to any text query naturally as you would in a normal conversation. Don't fixate on the image unless specifically asked about it. Focus on having a balanced, natural conversation that addresses the user's actual query."
                : "You are a helpful AI assistant that can answer questions and have natural conversations."
            
            let instructionContent = GeminiContent(
                role: "user", 
                parts: [GeminiPart(text: instructionPrompt)]
            )
            contents.insert(instructionContent, at: 0)

            // Send to Gemini API
            sendGeminiRequest(with: contents, retryCount: 0)
        }
    }
    
    // Convert ChatMessage to Gemini's content format
    private func convertToGeminiContent(from message: ChatMessage) -> GeminiContent {
        // Map role from our enum to Gemini's expected format
        let geminiRole: String
        switch message.role {
        case .user:
            geminiRole = "user"
        case .assistant:
            geminiRole = "model"
        case .system:
            // Gemini doesn't support system role, map to user
            geminiRole = "user"
        }
        
        var parts: [GeminiPart] = []
        
        // Add text part if it exists
        if let text = message.content, !text.isEmpty {
            parts.append(GeminiPart(text: text))
        } else if message.image == nil {
            // Add a default message if neither text nor image
            parts.append(GeminiPart(text: "What's this?"))
        }
        
        // Add image part if it exists
        if let image = message.image {
            var resizedImage = image
            
            // Resize large images
            let maxDimension: CGFloat = 1200
            if image.size.width > maxDimension || image.size.height > maxDimension {
                if image.size.width > image.size.height {
                    resizedImage = image.resized(toWidth: maxDimension) ?? image
                } else {
                    resizedImage = image.resized(toHeight: maxDimension) ?? image
                }
                print("Resized large image to \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height))")
            }
            
            // Compress image with multiple quality levels if needed
            func getImageData() -> Data? {
                let compressionLevels: [CGFloat] = [0.8, 0.6, 0.4, 0.2]
                
                for level in compressionLevels {
                    if let data = resizedImage.jpegData(compressionQuality: level) {
                        let sizeInKB = data.count / 1024
                        if sizeInKB < 1024 {
                            print("Image compressed to \(sizeInKB) KB at quality \(level)")
                            return data
                        } else {
                            print("Image at quality \(level) is still \(sizeInKB) KB, trying lower quality...")
                        }
                    }
                }
                
                // Final fallback to very small image
                if let smallerImage = resizedImage.resized(toWidth: 800) {
                    return smallerImage.jpegData(compressionQuality: 0.2)
                }
                
                return resizedImage.jpegData(compressionQuality: 0.2)
            }
            
            if let imageData = getImageData() {
                print("Final image data size: \(imageData.count / 1024) KB")
                parts.append(GeminiPart(imageData: imageData, mimeType: "image/jpeg"))
            } else {
                print("Failed to encode image to JPEG")
            }
        }
        
        return GeminiContent(role: geminiRole, parts: parts)
    }
    
    // MARK: - Gemini API Request
    
    private func sendGeminiRequest(with contents: [GeminiContent], retryCount: Int) {
        // Ensure sufficient time between requests
        if let lastTime = self.lastRequestTime, Date().timeIntervalSince(lastTime) < 2.5 {
            print("Enforcing minimum request spacing (2.5 seconds)")
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.sendGeminiRequest(with: contents, retryCount: retryCount)
            }
            return
        }
        
        // Update last request time
        self.lastRequestTime = Date()
        
        // Use a more reliable configuration
        let temperature = 0.5 // Lower temperature for more reliable responses 
        let requestBody = GeminiRequest(
            contents: contents,
            generationConfig: GenerationConfig(temperature: temperature, maxOutputTokens: 800, topP: 0.9)
        )
        
        // Send the request
        performGeminiRequest(requestBody: requestBody, retryCount: retryCount)
    }
    
    // Perform the actual network request
    private func performGeminiRequest(requestBody: GeminiRequest, retryCount: Int) {
        // Handle on a background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            print("Starting Gemini API request (attempt \(retryCount + 1))")
            
            // More thorough network check
            if !self.isNetworkReliable() {
                DispatchQueue.main.async {
                    self.isSending = false
                    if !self.errorDisplayed {
                        self.appendMessage(role: .system, content: "Network connection appears unstable. Please check your connection and try again.")
                        self.errorDisplayed = true
                    }
                }
                return
            }
            
            // Add delay based on retry count - exponential backoff
            if retryCount > 0 {
                let backoffDelay = min(pow(2.0, Double(retryCount)) + Double.random(in: 0...1), 15.0)
                Thread.sleep(forTimeInterval: backoffDelay)
                print("Applied backoff delay of \(backoffDelay) seconds")
            }
            
            // Create request
            var request = URLRequest(url: self.geminiEndpointURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("SwiftUI-AIWrapper/1.5", forHTTPHeaderField: "User-Agent")
            // Add cache control to prevent any caching issues
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            // Add unique request ID
            request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
            
            do {
                // Encode request body
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(requestBody)
                request.httpBody = jsonData
                
                print("Request prepared, size: \(jsonData.count / 1024) KB")
                
                // Set up a synchronous request using semaphore
                let semaphore = DispatchSemaphore(value: 0)
                var responseData: Data?
                var responseError: Error?
                var responseStatusCode: Int?
                
                // Create and start the task
                let task = self.sessionManager.dataTask(with: request) { data, response, error in
                    responseData = data
                    responseError = error
                    responseStatusCode = (response as? HTTPURLResponse)?.statusCode
                    semaphore.signal()
                }
                task.resume()
                
                // Wait for completion with timeout
                let result = semaphore.wait(timeout: .now() + 60)
                
                // Handle timeout
                if result == .timedOut {
                    print("Gemini API request timed out")
                    task.cancel()
                    
                    // Try again if we haven't exceeded max retries
                    if retryCount < self.maxRetries {
                        DispatchQueue.main.async {
                            // Only show timeout message on first attempt
                            if retryCount == 0 && !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "Request is taking longer than expected. Still trying...")
                                self.errorDisplayed = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.performGeminiRequest(requestBody: requestBody, retryCount: retryCount + 1)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isSending = false
                            if !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "Connection timed out. Please try again with a smaller image or text.")
                                self.errorDisplayed = true
                            }
                        }
                    }
                    return
                }
                
                // Process the response on the main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Handle errors
                    if let error = responseError {
                        print("Gemini API error: \(error.localizedDescription)")
                        
                        if retryCount < self.maxRetries {
                            if retryCount == 0 && !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "Network issue detected. Trying again...")
                                self.errorDisplayed = true
                            }
                            
                            // Create new session for next attempt if we have network errors
                            self.consecutiveEmptyResponses += 1
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self.performGeminiRequest(requestBody: requestBody, retryCount: retryCount + 1)
                            }
                            return
                        } else {
                            self.isSending = false
                            if !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "Network issues prevented connecting to the AI service. Please check your connection and try again.")
                                self.errorDisplayed = true
                            }
                        }
                        return
                    }
                    
                    // Check status code
                    if let statusCode = responseStatusCode, !(200...299).contains(statusCode) {
                        print("Gemini API returned status code \(statusCode)")
                        
                        // Handle status codes appropriately
                        if statusCode == 429 && retryCount < self.maxRetries {
                            // Rate limiting - try again with longer delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount + 3)) {
                                self.performGeminiRequest(requestBody: requestBody, retryCount: retryCount + 1)
                            }
                            return
                        }
                        
                        var errorMessage = "Server returned status \(statusCode)"
                        if statusCode == 429 {
                            errorMessage = "Service is busy. Please try again in a minute."
                        } else if statusCode == 400 {
                            errorMessage = "The request couldn't be processed. Try with a smaller image or shorter message."
                        } else if statusCode == 403 {
                            errorMessage = "Access denied. There might be an issue with the API key."
                        }
                        
                        self.isSending = false
                        if !self.errorDisplayed {
                            self.appendMessage(role: .system, content: "AI service error: \(errorMessage)")
                            self.errorDisplayed = true
                        }
                        return
                    }
                    
                    // Decode response data
                    guard let data = responseData else {
                        self.isSending = false
                        if !self.errorDisplayed {
                            self.appendMessage(role: .system, content: "Received empty response. Please try again.")
                            self.errorDisplayed = true
                        }
                        return
                    }
                    
                    do {
                        // Parse the response JSON
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(GeminiResponse.self, from: data)
                        
                        // Process successful response
                        guard let candidates = response.candidates, !candidates.isEmpty else {
                            self.isSending = false
                            self.consecutiveEmptyResponses += 1
                            
                            if !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "The AI couldn't generate a response for this input. Please try again with different wording or image.")
                                self.errorDisplayed = true
                            }
                            return
                        }
                        
                        guard let firstCandidate = candidates.first,
                              let textPart = firstCandidate.content.parts.first(where: { $0.text != nil }),
                              let text = textPart.text, !text.isEmpty else {
                            self.isSending = false
                            
                            if !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "Received an incomplete response. Please try again.")
                                self.errorDisplayed = true
                            }
                            return
                        }
                        
                        print("Gemini API request successful!")
                        // Reset error counters on success
                        self.consecutiveEmptyResponses = 0
                        self.errorDisplayed = false
                        self.appendMessage(role: .assistant, content: text)
                        self.isSending = false
                    } catch {
                        print("Error decoding Gemini response: \(error)")
                        
                        // Check if we can retry parse errors
                        if retryCount < self.maxRetries {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self.performGeminiRequest(requestBody: requestBody, retryCount: retryCount + 1)
                            }
                        } else {
                            self.isSending = false
                            if !self.errorDisplayed {
                                self.appendMessage(role: .system, content: "Error processing the AI response. Please try again.")
                                self.errorDisplayed = true
                            }
                        }
                    }
                }
            } catch {
                // Handle encoding errors
                DispatchQueue.main.async {
                    self.isSending = false
                    if !self.errorDisplayed {
                        self.appendMessage(role: .system, content: "Failed to prepare request: \(error.localizedDescription)")
                        self.errorDisplayed = true
                    }
                }
            }
        }
    }
    
    // Enhanced network reliability check
    private func isNetworkReliable() -> Bool {
        // Basic connectivity check
        let semaphore = DispatchSemaphore(value: 0)
        let monitor = NWPathMonitor()
        var isAvailable = false
        
        monitor.pathUpdateHandler = { path in
            isAvailable = path.status == .satisfied && 
                         !path.isExpensive // Not using expensive cellular
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        // Wait up to 2 seconds for a result
        _ = semaphore.wait(timeout: .now() + 2.0)
        monitor.cancel()
        
        print("Network check result: \(isAvailable ? "Connected" : "Not connected or unreliable")") 
        return isAvailable
    }

    // MARK: - Appending Message

    func appendMessage(role: MessageRole, content: String? = nil, image: UIImage? = nil) {
        DispatchQueue.main.async { // Ensure UI updates happen on the main thread
            self.date = Date()
            let newMessage = ChatMessage(
                role: role,
                content: content, // Use content
                image: image
            )
            self.messages.append(newMessage)

            // Auto-generate title from the first user message if needed
            if self.title == nil && role == .user && content != nil {
                self.title = String(content!.prefix(30)) + (content!.count > 30 ? "..." : "")
            }
        }
    }
}

// MARK: - Message Role Enum

enum MessageRole: String, Codable {
    case user
    case system
    case assistant // Added for compatibility with various AI models
}

// MARK: - Chat Message Struct

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var content: String? // Message content text
    var image: UIImage? // Image data, not serialized

    enum CodingKeys: String, CodingKey {
        case id // Keep id for local identification
        case role
        case content
    }

    init(id: UUID = UUID(), role: MessageRole, content: String?, image: UIImage? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        role = try container.decode(MessageRole.self, forKey: .role)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        image = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(content, forKey: .content)
    }

    private func resizedImage(_ image: UIImage) -> UIImage? {
        if image.size.height > 1000 {
            return image.resized(toHeight: 1000)
        } else {
            return image
        }
    }

    private func encodeToPercentEncodedString(_ data: Data) -> String {
        return data.map { String(format: "%%%02hhX", $0) }.joined()
    }
}

// MARK: - UIImage Extension (Placeholder - Removed Duplicate)
// Ensure you have the UIImage extension with `resized(toHeight:)` defined elsewhere in your project.



