import Foundation
import Combine
import Network

class ConnectionRequest: ObservableObject {
    @Published var isLoading: Bool = false
    var cancellable: AnyCancellable?
    
    // Improved fetch with retry mechanism
    func fetchData(_ url: String?, parameters: [String: String], completion: @escaping (Data?,String?) -> Void) {
        guard let urlString = url, let requestUrl = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }

        // Check network connectivity first
        guard isNetworkAvailable() else {
            completion(nil, "No internet connection. Please check your network and try again.")
            return
        }

        //Setup connection
        var request = URLRequest(url: requestUrl)
        request.timeoutInterval = 60
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("SwiftUI-AIWrapper/1.0", forHTTPHeaderField: "User-Agent")

        // Prepare a POST request
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let postString = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = postString.data(using: .utf8)
        
        isLoading = true
        
        print("==> fetching \(requestUrl.absoluteString)")
        
        let customQueue = DispatchQueue(label: "com.ai.vision.wrapper.ConnectionRequest")
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .retry(3) // Add retry for transient network issues
            .timeout(60, scheduler: customQueue)
            .receive(on: customQueue)
            .sink { completionStatus in
                self.isLoading = false
                switch completionStatus {
                case .failure(let error):
                    print("Connection error: \(error.localizedDescription)")
                    
                    // Provide more specific error messages based on error type
                    let errorMessage: String
                    // The error is already a URLError after retry() so no need for conditional cast
                    let urlError = error
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "Not connected to the internet"
                    case .timedOut:
                        errorMessage = "Request timed out"
                    case .cannotFindHost:
                        errorMessage = "Unable to find host server"
                    case .cannotConnectToHost:
                        errorMessage = "Cannot connect to server"
                    default:
                        errorMessage = error.localizedDescription
                    }
                    
                    completion(nil, errorMessage)
                case .finished:
                    break
                }
            } receiveValue: { data, response in
                DispatchQueue.global().async {
                    if let httpResponse = response as? HTTPURLResponse {
                        if (200...299).contains(httpResponse.statusCode) {
                            completion(data, nil)
                        } else {
                            let errorMsg = "Server returned status code \(httpResponse.statusCode)"
                            completion(nil, errorMsg)
                        }
                    } else {
                        completion(data, nil)
                    }
                }
            }
    }
    
    // Modern network availability check (iOS 17.4+ compatible)
    private func isNetworkAvailable() -> Bool {
        // Use NWPathMonitor with a semaphore to make it synchronous
        let semaphore = DispatchSemaphore(value: 0)
        let monitor = NWPathMonitor()
        var isAvailable = false
        
        monitor.pathUpdateHandler = { path in
            isAvailable = path.status == .satisfied
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        monitor.start(queue: queue)
        
        // Wait up to 1 second for a result
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return isAvailable
    }

    deinit {
        cancellable?.cancel()
    }
}
