# Wistia Video Player

A simple Flutter widget for embedding Wistia videos with full customization support. This package provides an easy-to-use player with comprehensive controls and options for Wistia video integration.

## Features

* **Easy Integration**: Simple widget that can be embedded anywhere in your Flutter app
* **Full Customization**: Comprehensive player options including autoplay, controls visibility, quality settings
* **Player State Management**: Real-time player state tracking (playing, paused, ended)
* **Event Handling**: Callbacks for video events like play, pause, end
* **Cross-Platform**: Works on both iOS and Android
* **WebView Integration**: Uses WebView with JavaScript for seamless Wistia API integration
* **Responsive Design**: Adapts to different screen sizes and orientations
* **Quality Control**: Support for video quality selection and bandwidth optimization
* **Accessibility**: Built-in support for captions and accessibility features

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  wistia_video_player: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## Usage

Here's a simple example of how to use the Wistia Video Player:

```dart
import 'package:flutter/material.dart';
import 'package:wistia_video_player/wistia_video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  
  const VideoPlayerPage({Key? key, required this.videoId}) : super(key: key);
  
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late WistiaPlayerController wistiaController;

  @override
  void initState() {
    super.initState();
    wistiaController = WistiaPlayerController(videoId: widget.videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: WistiaPlayer(
        controller: wistiaController,
      ),
    );
  }

  @override
  void dispose() {
    wistiaController.dispose();
    super.dispose();
  }
}
```

For more advanced usage with custom options:

```dart
final controller = WistiaPlayerController(
  videoId: 'your_video_id',
  options: const WistiaPlayerOptions(
    autoPlay: false,
    controlsVisibleOnLoad: true,
    playbar: true,
    fullscreenButton: true,
    qualityControl: true,
  ),
);
```

## Additional information

### Getting Video ID

You can extract the video ID from a Wistia URL using the built-in converter:

```dart
String? videoId = WistiaPlayer.convertUrlToId('https://home.wistia.com/medias/e4a27b971d');
```

### Player Controls

The controller provides methods for programmatic control:

```dart
controller.play();
controller.pause();
controller.mute();
controller.unmute();
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request at [GitHub repository](https://github.com/booooohdan/wistia_video_player).

### Issues

If you encounter any issues or have feature requests, please file them in the [GitHub Issues](https://github.com/booooohdan/wistia_video_player/issues) section.

### License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
