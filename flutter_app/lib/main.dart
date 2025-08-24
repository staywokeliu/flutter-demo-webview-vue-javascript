import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Vue 双方向通信デモ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  
  // カウント用の変数（Flutter側で保持）
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Vue 双方向通信デモ'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // 現在のカウント値を表示（Flutter側）
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            width: double.infinity,
            child: Text(
              'Flutter側カウント: $_count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // WebViewでVue.jsアプリを表示
          Expanded(
            child: InAppWebView(
              // Vue.jsの開発サーバーURL
              initialUrlRequest: URLRequest(
                url: WebUri("http://localhost:5173")
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
                
                // JavaScript→Flutter通信のハンドラを設定
                controller.addJavaScriptHandler(
                  handlerName: 'incrementCounter',
                  callback: (args) {
                    // カウント関数を実行
                    return _incrementCount();
                  }
                );
              },
              onLoadStart: (controller, url) {
                print('WebView読み込み開始: $url');
              },
              onLoadStop: (controller, url) async {
                print('WebView読み込み完了: $url');
                
                // Vue.jsアプリが読み込まれた後、初期化関数を呼び出し
                await controller.evaluateJavascript(source: """
                  if (window.initFlutterBridge) {
                    window.initFlutterBridge();
                  }
                """);
              },
              onConsoleMessage: (controller, consoleMessage) {
                // JavaScript側のconsole.logをFlutter側で確認
                print('JS Console: ${consoleMessage.message}');
              },
              initialSettings: InAppWebViewSettings(
                // JavaScript有効化
                javaScriptEnabled: true,
                // ドメイン制限を緩和（開発用）
                allowUniversalAccessFromFileURLs: true,
                allowFileAccessFromFileURLs: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// カウント関数（Flutter側で定義）
  /// 呼び出されるたびに内部カウント変数を+1して現在値を返す
  int _incrementCount() {
    setState(() {
      _count++;
    });
    
    print('Flutter: カウント実行 -> $_count');
    
    // Vue.js側にもカウント値を通知
    _notifyWebViewCountUpdate(_count);
    
    return _count;
  }

  /// WebView側にカウント更新を通知
  void _notifyWebViewCountUpdate(int count) {
    webViewController?.evaluateJavascript(source: """
      if (window.onFlutterCountUpdate) {
        window.onFlutterCountUpdate($count);
      }
    """);
  }
}