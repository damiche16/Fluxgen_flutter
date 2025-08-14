# Fluxgen AI Image Generator 🎨✨

A beautiful, modern Flutter application that transforms your imagination into stunning visuals using AI. Create amazing artwork with just a text description!

![FluxGen Screenshot](assets/app_icon/Fluxgen.png)

## 🌟 Features

- **🎨 AI-Powered Image Generation**: Generate high-quality images from text prompts using Pollinations AI
- **🔮 Multiple AI Models**: Choose from 6 different AI models including Flux Pro, Realism, Anime Style, 3D Render, and more
- **📐 Flexible Image Sizes**: Support for various resolutions from 512×512 to 1920×1080
- **💡 Smart Suggestions**: Quick prompt ideas with beautiful categorized suggestions
- **📱 Cross-Platform**: Works seamlessly on Android, iOS, and Desktop
- **⬇️ Easy Downloads**: Save generated images directly to your device with proper permissions handling
- **🎭 Modern UI**: Gorgeous glass-morphism design with smooth animations
- **📱 Responsive Design**: Optimized layouts for both mobile and tablet screens
- **⚡ Fast Generation**: Efficient image generation with fallback options for reliability

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart (>=3.0.0)
- Android Studio or VS Code with Flutter extensions
- An Android device/emulator or iOS device/simulator for mobile testing

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YatharthSanghavi/Fluxgen_flutter.git
   cd Fluxgen_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  cached_network_image: ^3.3.0
  flutter_spinkit: ^5.2.0
  share_plus: ^7.2.1
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  device_info_plus: ^10.1.0
```

## 🎯 Usage

1. **Enter Your Vision**: Type a descriptive prompt in the text field
2. **Choose Settings**: Select your preferred AI model and image size
3. **Generate**: Tap the "Generate Image" button and watch the magic happen
4. **Download**: Save your masterpiece to your device
5. **Create More**: Generate new variations or try different prompts

### Example Prompts

- "A futuristic cityscape with neon lights and flying cars"
- "A majestic dragon soaring through storm clouds"
- "A serene Japanese garden with cherry blossoms at sunset"
- "A cyberpunk warrior with glowing armor in a dark alley"

## 🎨 Available AI Models

- **Flux Pro**: High-quality general-purpose image generation
- **Realism**: Photorealistic images with incredible detail
- **CablyAI**: Unique artistic style with vibrant colors
- **Anime Style**: Perfect for anime and manga-inspired artwork
- **3D Render**: Professional 3D-rendered images
- **Turbo Fast**: Quick generation for rapid prototyping

## 📱 Supported Platforms

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 18.04+)

## 🔐 Permissions

The app requests the following permissions:

- **Storage Permission** (Android): To save generated images to your device
- **Photos Permission** (iOS): To save images to your photo library

## 🎭 UI/UX Highlights

- **Glass Morphism Design**: Modern frosted glass effect throughout the interface
- **Smooth Animations**: Engaging transitions and loading states
- **Responsive Layout**: Adapts beautifully to different screen sizes
- **Color-Coded Elements**: Intuitive color system for different features
- **Haptic Feedback**: Tactile responses for better user experience

## 🔧 Configuration

The app uses the Pollinations AI API, which is free and doesn't require an API key. However, you can modify the API endpoint in the `_generateImage()` method if needed.

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                 # Main application entry point
```

### Key Features Implementation

- **Image Generation**: Uses HTTP requests to Pollinations AI API
- **File Management**: Handles downloads across different platforms
- **Permission Handling**: Manages storage permissions for Android/iOS
- **Responsive Design**: Adapts UI based on screen size
- **Error Handling**: Graceful fallbacks and user-friendly error messages

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is not for commercial use.

## 🙏 Acknowledgments

- [Pollinations AI](https://pollinations.ai/) for providing free AI image generation API
- Flutter team for the amazing framework
- The open-source community for the wonderful packages used

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/YatharthSanghavi/Fluxgen_flutter/issues) section
2. Create a new issue if your problem isn't already reported
3. Provide as much detail as possible including device info and error messages

---
## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=YatharthSanghavi/Fluxgen_flutter&type=Date)](https://star-history.com/#YatharthSanghavi/Fluxgen_flutter&Date)

---

<div align="center">
  <strong>Made with ❤️ by Yatharth</strong>
  <br>
  <br>
  <a href="https://github.com/YatharthSanghavi/Fluxgen_flutter/">⭐ Star this repo if you found it helpful!</a>
</div>
