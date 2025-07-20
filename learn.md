# Learn: Gemini Vision Wrapper for SwiftUI

Welcome to the comprehensive learning guide for the Gemini Vision Wrapper project! This guide will help you understand, use, and contribute to this SwiftUI application that integrates Google's Gemini AI for intelligent image analysis and conversational AI.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation & Setup](#installation--setup)
3. [Key Concepts](#key-concepts)
4. [Example Usage Flow](#example-usage-flow)
5. [Useful Resources](#useful-resources)
6. [Contributing Guidelines](#contributing-guidelines)
7. [FAQ](#faq)

## Prerequisites

### Technical Requirements
- **macOS**: macOS 12.0 (Monterey) or later
- **Xcode**: Version 14.0 or later
- **iOS Target**: iOS 16.0 or later
- **Swift**: Swift 5.7 or later

### Knowledge Prerequisites
- **Beginner Level**: Basic familiarity with iOS apps and using Xcode
- **Intermediate Level**: Understanding of SwiftUI fundamentals and iOS development
- **Advanced Level**: Knowledge of API integration, async programming, and iOS architecture patterns

### API Requirements
- **Gemini API Key**: Required from [Google AI Studio](https://makersuite.google.com/app/apikey)
- **Internet Connection**: Required for API calls to Gemini services

## Installation & Setup

### Step 1: Environment Setup
1. **Install Xcode**:
   ```bash
   # Download from Mac App Store or Apple Developer Portal
   # Verify installation:
   xcodebuild -version
   ```

2. **Verify iOS Simulator**:
   - Open Xcode → Window → Devices and Simulators
   - Ensure iOS 16+ simulators are available

### Step 2: Get Gemini API Key
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. **Important**: Keep this key secure and never commit it to version control

### Step 3: Clone and Setup Project
1. **Clone the repository**:
   ```bash
   git clone https://github.com/SohanRaidev/Gemini-Wrapper-SwiftUI.git
   cd Gemini-Wrapper-SwiftUI
   ```

2. **Open in Xcode**:
   ```bash
   open SwiftUI-AI-Wrapper.xcodeproj
   ```

3. **Configure API Key**:
   - Navigate to `SwiftUI-AI-Wrapper/Models/ChatModel.swift`
   - Find the line with `<YOUR_API_KEY>`
   - Replace with your actual Gemini API key:
   ```swift
   private let apiKey = "your_actual_api_key_here"
   ```

4. **Set Target Device**:
   - Select your target device or simulator (iOS 16+)
   - Choose iPhone or iPad for optimal experience

### Step 4: First Run
1. **Build the project**: ⌘+B
2. **Run the app**: ⌘+R
3. **Grant permissions** when prompted:
   - Camera access (for taking photos)
   - Photo Library access (for selecting images)

## Key Concepts

### Architecture Overview
The app follows a clean SwiftUI architecture with these core components:

#### 1. **Models**
- **`ChatModel`**: Manages Gemini API communication and chat state
- **`HistoryModel`**: Handles chat history persistence
- **`ConnectionRequest`**: Manages network requests and error handling

#### 2. **Views**
- **`ContentView`**: Main app container with camera integration
- **`ChatView`**: Chat interface for AI conversations
- **`CameraView`**: Camera capture functionality
- **`PhotoPicker`**: Photo library integration
- **`HistoryView`**: Chat history display

#### 3. **Key Technologies**
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **AVFoundation**: Camera and media handling
- **Vision**: Image processing capabilities

### Core Functionality

#### Image Analysis Flow
1. **Image Capture**: User takes photo or selects from library
2. **Image Processing**: Image is resized and converted to base64
3. **API Request**: Image and prompt sent to Gemini API
4. **AI Response**: Gemini analyzes image and provides description
5. **Chat Interface**: User can ask follow-up questions

#### Chat Management
- **Message History**: Persistent storage of conversations
- **Typing Indicators**: Real-time feedback during API calls
- **Error Handling**: Automatic retry logic for failed requests
- **Image Compression**: Optimized for API performance

## Example Usage Flow

### Basic Usage Scenario
Here's a typical user interaction with the app:

#### 1. **Launch & Setup**
```swift
// App launches to camera view
// User grants camera/photo permissions
```

#### 2. **Capture Image**
```swift
// User taps camera button
// Photo is taken and processed
// ChatModel initializes automatically
```

#### 3. **Initial AI Analysis**
```swift
// App sends "What is this?" with the image
// Gemini analyzes and responds with description
// Chat interface appears with AI response
```

#### 4. **Follow-up Conversation**
```swift
// User types follow-up questions like:
// "What color is it?"
// "How much might this cost?"
// "Where can I buy this?"
```

### Advanced Usage Examples

#### Custom Prompts
Instead of the default "What is this?", you can modify the initial prompt:

```swift
// In ContentView.swift, modify the sendMessage call:
chat!.sendMessage(content: "Describe this image in detail", image: image)
```

#### Multiple Images
Currently supports one image per conversation. To analyze multiple images:
1. Start new conversation for each image
2. Access previous conversations via History button

## Useful Resources

### Official Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Google AI Studio](https://makersuite.google.com/)

### Learning SwiftUI
- [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)
- [SwiftUI Lab](https://swiftui-lab.com/)

### AI & ML Resources
- [Google AI Blog](https://ai.googleblog.com/)
- [Apple's Core ML](https://developer.apple.com/machine-learning/)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)

### Development Tools
- [Xcode User Guide](https://developer.apple.com/library/archive/documentation/ToolsLanguages/Conceptual/Xcode_Overview/)
- [iOS Simulator Guide](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

## Contributing Guidelines

We welcome contributions from developers of all skill levels! Here's how to get involved:

### Getting Started
1. **Fork the repository** on GitHub
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following our coding standards
4. **Test thoroughly** on multiple devices/simulators
5. **Submit a pull request** with clear description

### Coding Standards
- **Swift Style**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **SwiftUI Patterns**: Use declarative, state-driven approaches
- **Comments**: Document complex logic and API integrations
- **Error Handling**: Implement proper error handling for all API calls

### Areas for Contribution

#### Beginner-Friendly Tasks
- UI/UX improvements and animations
- Accessibility enhancements
- Documentation updates
- Bug fixes and error message improvements

#### Intermediate Tasks
- New chat features (export, search, filters)
- Additional image processing options
- Performance optimizations
- iPad-specific UI adaptations

#### Advanced Tasks
- Multiple AI model support
- Offline capabilities
- Advanced image analysis features
- Core Data integration for better persistence

### Submission Guidelines
1. **Clear PR Description**: Explain what changes were made and why
2. **Screenshots**: Include before/after screenshots for UI changes
3. **Testing**: Verify changes work on both simulator and physical device
4. **API Key Security**: Never commit API keys or sensitive data

## FAQ

### General Questions

**Q: Do I need a paid Gemini API account?**
A: Google AI Studio provides free tier access to Gemini API with rate limits. For production use, you may need a paid plan.

**Q: Can I use this on older iOS versions?**
A: The app requires iOS 16+ due to SwiftUI features used. Earlier versions would require significant refactoring.

**Q: Does the app work offline?**
A: No, the app requires internet connection for Gemini API calls. Image analysis happens server-side.

### Technical Questions

**Q: Why do API calls sometimes fail?**
A: Common causes include:
- Network connectivity issues
- API rate limiting
- Large image files (app automatically compresses)
- Invalid API key

**Q: Can I modify the AI model used?**
A: Yes, you can change the model in `ChatModel.swift`:
```swift
private let geminiModel = "gemini-1.5-flash" // or "gemini-1.5-pro"
```

**Q: How do I debug API issues?**
A: Enable debug logging in `ChatModel.swift` and check Xcode console for detailed error messages.

### Development Questions

**Q: How do I add new UI features?**
A: Study the existing SwiftUI views and follow the same patterns. The app uses `@State` and `@ObservedObject` for state management.

**Q: Can I add support for video analysis?**
A: Gemini API supports video, but this would require significant changes to handle video upload and processing.

**Q: How do I test without using API quota?**
A: Implement a mock mode in `ChatModel.swift` that returns predefined responses for testing.

### Troubleshooting

**Q: App crashes on launch**
A: Check:
- API key is properly configured
- Device/simulator is iOS 16+
- Camera permissions are granted

**Q: Images appear blurry or low quality**
A: The app compresses images for API efficiency. Adjust compression settings in `ChatModel.swift` if needed.

**Q: Chat history not persisting**
A: Ensure the app has proper storage permissions and `HistoryModel` is functioning correctly.

---

## Next Steps

Now that you understand the basics:

1. **Try the app** with different types of images
2. **Experiment** with custom prompts and questions
3. **Explore the code** to understand implementation details
4. **Join the community** by contributing improvements
5. **Share your experience** and help others learn

Happy coding! 🚀

---

*For additional help, open an issue on GitHub or check existing discussions.*