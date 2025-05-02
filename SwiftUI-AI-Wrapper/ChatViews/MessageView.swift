import SwiftUI

struct MessageView: View {
    @State private var confetti = 0
    @Environment(\.colorScheme) var colorScheme

    let message: ChatMessage
    var body: some View {
        HStack (alignment: .top) {
            if message.role == .user {
                Spacer()
            }
            else {
                Image("SystemAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 45, alignment: .center)
                    .clipped()
                    .mask {
                        Circle()
                    }
            }
            VStack (alignment: .leading) {
                VStack (alignment: .leading, spacing: 0) {
                    if let image = message.image {
                        NavigationLink(destination: PhotoView(image: image)) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                // Use separate frame modifiers for height and maxWidth
                                .frame(height: 120)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .clipped()
                        }
                    }
                    // Use message.content instead of message.message
                    if let textContent = message.content {
                        if textContent == "..." && self.message.role == .system {
                            TypingIndicatorView()
                                .padding()
                                .foregroundColor(.white)
                                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        }
                        else {
                            VStack (alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(removeMessageResponses(textContent)) // Use textContent here
                                    if textContent.contains("? location:") { // Use textContent here
                                        Spacer()
                                        Image(systemName: "location.viewfinder")
                                    }
                                }
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        }
                    }
                }
                .contextMenu {
                    Button(action: {
                        // Use message.content instead of message.message
                        if let textContent = message.content {
                            UIPasteboard.general.string = textContent
                        }
                        else if let image = message.image {
                            UIPasteboard.general.image = image
                        }
                    }) {
                        Text("Copy")
                        Image(systemName: "doc.on.doc")
                    }
                    /* Commented out ShareView remains the same
                    if let textContent = message.content { // Use textContent if uncommenting
                        Button(action: {
                            ShareView(data: [textContent]) // Pass textContent if uncommenting
                        }) {
                            Text("Share")
                            Image(systemName: "square.and.arrow.up")
                        }
                    }*/
                }
            }
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .mask {
                RoundedRectangle(cornerRadius: 12)
            }
            .padding(.leading, message.role == .system ? 0 : 40)
            .padding(.trailing, message.role == .user ? 0 : 40)
            if message.role == .system {
                Spacer()
            }
        }
    }


    func removeMessageResponses(_ message: String) -> String {
        var parsedMessage = message

        // Remove <option> tags and their content
        let regex = try! NSRegularExpression(pattern: "<option>.*?</option>", options: [])
        parsedMessage = regex.stringByReplacingMatches(in: parsedMessage, options: [], range: NSRange(location: 0, length: parsedMessage.utf16.count), withTemplate: "What is this?")


        // Remove trailing whitespace and newline characters
        parsedMessage = parsedMessage.trimmingCharacters(in: .whitespacesAndNewlines)


        if let range = parsedMessage.range(of: "location:") {
            return String(parsedMessage[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return parsedMessage
        }


    }

    func speciesName(_ message: String) -> String {
        let speciesPrefix = "Species: "
        if let range = message.range(of: speciesPrefix) {
            let speciesStartIndex = range.upperBound
            var speciesEndIndex = speciesStartIndex

            // Find the end of the species name (either end of the string or next newline)
            if let newlineRange = message[speciesStartIndex...].range(of: "\n") {
                speciesEndIndex = newlineRange.lowerBound
            } else {
                speciesEndIndex = message.endIndex
            }

            // Extract and return the species name
            return String(message[speciesStartIndex..<speciesEndIndex]).trimmingCharacters(in: .whitespaces)
        }

        return "" // Return an empty string if "Species: " is not found
    }
}

