import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:wistia_video_player/src/enums/wistia_player_state.dart';
import 'wistia_player_controller.dart';
import 'wistia_meta_data.dart';
import 'wistia_player_value.dart';

class WistiaPlayer extends StatefulWidget {
  final WistiaPlayerController controller;

  final void Function(WistiaMetaData metaData)? onEnded;

  /// Creates a [WistiaPlayer] widget.
  const WistiaPlayer({super.key, this.onEnded, required this.controller});

  /// Converts fully qualified Wistia Url to video id.
  ///
  /// If videoId is passed as url then we will skip conversion.
  /// This will match:
  /// http://home.wistia.com/medias/e4a27b971d
  /// https://home.wistia.com/medias/e4a27b971d
  /// http://home.wi.st/medias/e4a27b971d
  /// http://home.wistia.com/embed/e4a27b971d
  /// https://home.wistia.com/embed/e4a27b971d
  /// https://home.wi.st/embed/e4a27b971d
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    bool isWistiaVideoId =
        !url.contains(RegExp(r'https?:\/\/')) && url.length == 10;

    if (isWistiaVideoId) return url;

    if (trimWhitespaces) url = url.trim();

    var wistiaShareLinkPattern = RegExp(
      r"https?:\/\/(?:www\.)?\w+\.(wistia\.com|wi\.st)\/(medias|embed)\/(\w{10}).*",
    );

    RegExpMatch? match = wistiaShareLinkPattern.firstMatch(url);
    return match?.group(3);
  }

  @override
  State<WistiaPlayer> createState() => _WistiaPlayerState();
}

class _WistiaPlayerState extends State<WistiaPlayer>
    with WidgetsBindingObserver {
  WistiaPlayerController? controller;
  WistiaPlayerState? _cachedPlayerState;
  late final WebViewController _webViewController;

  String? _getUserAgent() => controller!.options.forceHD
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!widget.controller.hasDisposed) {
      controller = widget.controller;
      // Set initial loading state
      controller?.updateValue(
        controller!.value.copyWith(
          playerState: WistiaPlayerState.loading,
          isReady: false,
        ),
      );
    }

    // Initialize platform-specific WebViewController
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params);
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.setUserAgent(_getUserAgent());
    _webViewController.addJavaScriptChannel(
      'WistiaWebView',
      onMessageReceived: (JavaScriptMessage message) {
        Map<String, dynamic> jsonMessage = jsonDecode(message.message);
        switch (jsonMessage['method']) {
          case 'Ready':
            {
              controller?.updateValue(
                controller!.value.copyWith(
                  isReady: true,
                  playerState: WistiaPlayerState.beforeplay,
                ),
              );
              break;
            }
          case 'Ended':
            {
              log('Video has ended');
              if (widget.onEnded != null) {
                widget.onEnded!(WistiaMetaData.fromJson(jsonMessage));
              }
              break;
            }
          case 'Playing':
            {
              controller?.updateValue(
                controller!.value.copyWith(
                  playerState: WistiaPlayerState.playing,
                ),
              );
              break;
            }
          case 'Paused':
            {
              controller?.updateValue(
                controller!.value.copyWith(
                  playerState: WistiaPlayerState.paused,
                ),
              );
              break;
            }
        }
      },
    );
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onWebResourceError: (WebResourceError error) {
          controller?.updateValue(
            controller!.value.copyWith(
              errorCode: error.errorCode,
              errorMessage: error.description,
            ),
          );
          log(error.description);
        },
      ),
    );
    if (_webViewController.platform is AndroidWebViewController) {
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    // Load the HTML content
    if (controller != null) {
      _loadWistiaContent();
    }
  }

  void _loadWistiaContent() {
    final htmlContent = _buildWistiaHTML(controller!);
    _webViewController.loadHtmlString(htmlContent);

    controller?.updateValue(
      controller!.value.copyWith(webViewController: _webViewController),
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cachedPlayerState != null &&
            _cachedPlayerState == WistiaPlayerState.playing) {
          controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _cachedPlayerState = controller?.value.playerState;
        controller?.pause();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3.0,
          ),
        ),
      );
    }

    return ValueListenableBuilder<WistiaPlayerValue>(
      valueListenable: controller!,
      builder: (context, value, child) {
        return Stack(
          children: [
            WebViewWidget(key: widget.key, controller: _webViewController),
            if (!value.isReady)
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3.0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _buildWistiaHTML(WistiaPlayerController controller) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
        <style>
          html,
            body {
                margin: 0;
                padding: 0;
                background-color: #000000;
                overflow: hidden;
                position: fixed;
                height: 100%;
                width: 100%;
            }
            iframe, .player {
              display: block;
              width: 100%;
              height: 100%;
              border: none;
              }
            </style>
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
        </head>
        <body>
          <script src="https://fast.wistia.com/embed/medias/${controller.videoId}.jsonp" async></script>
          <script src="https://fast.wistia.com/assets/external/E-v1.js" async></script>
          <div class="wistia_embed wistia_async_${controller.videoId} ${controller.options.toString()} player">&nbsp;</div>
          <script>
          window._wq = window._wq || [];
          _wq.push({
            id: "${controller.videoId}",
            onReady: function(video) {
                if (video.hasData()) {
                  sendMessageToDart('Ready');
                }
                video.bind("play", function() {
                  sendMessageToDart('Playing');
                });

                video.bind('pause', function() {
                  sendMessageToDart('Paused');
                });

                video.bind("end", function(endTime) {
                  sendMessageToDart('Ended', { endTime: endTime });
                });

                video.bind("percentwatchedchanged", function(percent, lastPercent) {
                  sendMessageToDart('PercentChanged', { percent: percent, lastPercent: lastPercent });
                });

                video.bind("mutechange", function (isMuted) {
                  sendMessageToDart('MuteChange', { isMuted: isMuted });
                });

                video.bind("enterfullscreen", function() {
                  sendMessageToDart('EnterFullscreen');
                });

                video.bind("cancelfullscreen", function() {
                  sendMessageToDart('CancelFullscreen');
                });

                video.bind("beforeremove", function() {
                  return video.unbind;
                });

                window.play = function play() {
                  return video.play();
                };
                window.pause = function pause() {
                  return video.pause();
                };
                window.isMuted = function isMuted() {
                  return video.isMuted();
                };

                window.inFullscreen = function inFullscreen() {
                  return video.inFullscreen();
                };

                window.hasData = function hasData() {
                  return video.hasData();
                };

                window.aspect = function aspect() {
                  return video.aspect();
                };

                window.mute = function mute() {
                  return video.mute();
                };

                window.unmute = function unmute() {
                  return video.unmute();
                };

                window.duration = function duration() {
                  return video.duration();
                };
              }
          });

          function sendMessageToDart(methodName, argsObject = {}) {
            var message = {
              'method': methodName,
              'args': argsObject
            };
            WistiaWebView.postMessage(JSON.stringify(message));
          }
          </script>
        </body>
      </html>
    ''';
  }
}
