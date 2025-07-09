import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final String gameUrl;
  final String screenMode; // 'full', 'hd', 'half'

  const CustomWebView({
    super.key,
    required this.gameUrl,
    required this.screenMode,
  });

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'pay',
            onMessageReceived: (message) {
              debugPrint('pay callback: ${message.message}');
              // 实际支付处理逻辑
            },
          )
          ..addJavaScriptChannel(
            'closeGame',
            onMessageReceived: (message) {
              debugPrint('closeGame callback');
              Navigator.pop(context);
            },
          )
          ..addJavaScriptChannel(
            'loadComplete',
            onMessageReceived: (message) {
              debugPrint('game load complete');
              setState(() {
                _isLoading = false;
              });
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (error) {
                // debugPrint('page error: ${error.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.gameUrl));
  }

  /// call updateCoin
  /// https://docs.leadercc.com/web/#/663362701/135425855
  void updateCoin() {
    _controller.runJavaScript('updateCoin();');
  }

  double _getHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    switch (widget.screenMode) {
      case 'full':
        return size.height;
      case 'hd':
        return size.width * 1044.0 / 750.0; // width : height = 750:1044
      case 'half':
      default:
        return size.width; // width : height = 1:1
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = _getHeight(context);
    final isFullScreen = widget.screenMode == 'full';

    return Scaffold(
      appBar:
          isFullScreen
              ? null
              : AppBar(
                title: const Text('WebView'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
      body: Stack(
        children: [
          SizedBox(
            height: isFullScreen ? null : height,
            child: WebViewWidget(controller: _controller),
          ),

          // test update Coin js
          Positioned(
            bottom: 0,
            child:
            TextButton(onPressed: ()=>{
              _controller.runJavaScript("updateCoin();"),
            }, child: const Icon(Icons.payment_rounded),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
