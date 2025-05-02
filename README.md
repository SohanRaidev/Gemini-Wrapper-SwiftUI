# Gemini Vision Wrapper for SwiftUI

A modern SwiftUI application that leverages Google's Gemini AI to analyze images and engage in natural conversations.

## Screenshots

<p align="center">
  <img src="./Screenshot%20-%20iPhone%2016%20Pro.png" width="300" />
  <img src="./Screenshot%20-%20iPhone%2016%20Pro2.png" width="300" />
</p>

## Overview

This app creates an interactive AI assistant that can analyze images and respond to text inputs. Simply take a photo or select an image from your photo library, and ask Gemini questions about what it sees.

## Features

* 📱 Clean, modern SwiftUI interface
* 📸 Integrated camera for taking photos
* 🖼️ Photo library integration for selecting images
* 🧠 Gemini AI for intelligent image analysis
* 💬 Persistent chat history
* 🔄 Robust error handling with automatic retries

## Getting Started

### Prerequisites
- Xcode 14 or later
- iOS 16 or later
- A Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/SohanRaidev/Gemini-Vision-SwiftUI.git
cd Gemini-Vision-SwiftUI
```

2. Open the project in Xcode:
```bash
open SwiftUI-AI-Wrapper.xcodeproj
```

3. Add your Gemini API key:
   - Open `SwiftUI-AI-Wrapper/Models/ChatModel.swift`
   - Replace `<YOUR_API_KEY>` with your actual Gemini API key

4. Build and run the app on your device or simulator

## How to Use

1. Launch the app
2. Take a photo with the camera or select an image from your photo library
3. Gemini will automatically analyze what's in the image
4. Continue the conversation by asking follow-up questions
5. Access your chat history through the history button

## Requirements

The app requires the following permissions:
- Camera access (for taking photos)
- Photo Library access (for selecting images)

## Customization

You can customize various aspects of the application:
- Adjust the `geminiModel` property in `ChatModel.swift` to use different Gemini models
- Modify UI appearance in the view files
- Adjust image compression settings for different performance profiles

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
