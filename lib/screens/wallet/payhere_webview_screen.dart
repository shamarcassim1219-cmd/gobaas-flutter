import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_theme.dart';

/// Loads PayHere's JS Checkout SDK in a WebView and starts a
/// payment with the fields the backend generated - the same
/// payhere.startPayment() pattern the web apps use, just hosted
/// inside a WebView instead of the browser. A JavaScript channel
/// relays PayHere's onCompleted/onDismissed/onError callbacks back
/// to Dart so this screen can pop with a result.
class PayHereWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> paymentParams;

  const PayHereWebViewScreen({super.key, required this.paymentParams});

  @override
  State<PayHereWebViewScreen> createState() => _PayHereWebViewScreenState();
}

class _PayHereWebViewScreenState extends State<PayHereWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PayHereChannel',
        onMessageReceived: _onChannelMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_buildHtml());
  }

  void _onChannelMessage(JavaScriptMessage message) {
    if (_finished) return;
    _finished = true;

    final parts = message.message.split(':');
    final status = parts.first;

    // A short delay lets PayHere's own success/dismiss UI finish
    // its own transition before this screen pops out from under it.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.of(context).pop(status == 'completed');
    });
  }

  String _buildHtml() {
    // jsonEncode safely handles quoting/escaping for every field
    // the backend returned, whatever those fields turn out to be -
    // this line is passed straight through as a JS object literal.
    final paymentJson = jsonEncode(widget.paymentParams);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.payhere.lk/lib/payhere.js"></script>
</head>
<body style="margin:0;padding:0;">
<script>
  payhere.onCompleted = function(orderId) {
    PayHereChannel.postMessage('completed:' + orderId);
  };
  payhere.onDismissed = function() {
    PayHereChannel.postMessage('dismissed');
  };
  payhere.onError = function(error) {
    PayHereChannel.postMessage('error:' + error);
  };

  var payment = $paymentJson;
  payhere.startPayment(payment);
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
