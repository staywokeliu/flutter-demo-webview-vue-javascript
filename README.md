# flutter-demo-webview-vue-javascript

# Flutter + Vue.js 双方向通信デモアプリ - ソースコード詳細解説

Flutter と Vue.js を使った双方向通信のデモアプリケーションのソースコード詳細解説です。環境構築以外の技術的な実装内容を分かりやすく説明します。

## 📋 目次

1. [アーキテクチャ概要](#-アーキテクチャ概要)
2. [Flutter 側実装詳細](#-flutter側実装詳細)
3. [Vue.js 側実装詳細](#-vuejs側実装詳細)
4. [双方向通信の仕組み](#-双方向通信の仕組み)
5. [重要なコード解説](#-重要なコード解説)
6. [エラーハンドリング](#-エラーハンドリング)
7. [パフォーマンス考慮点](#-パフォーマンス考慮点)

## 🏗️ アーキテクチャ概要

```
┌─────────────────┐    JavaScript Bridge    ┌─────────────────┐
│   Flutter App   │ <――――――――――――――――――――>  │   Vue.js SPA    │
├─────────────────┤                         ├─────────────────┤
│ ・WebView表示    │   callHandler()         │ ・ボタンUI       │
│ ・カウント関数    │ <―――――――――――――――――――    │ ・JavaScript    │
│ ・状態管理        │   evaluateJavascript() │ ・リアルタイム     │
│ ・通信制御        │ ―――――――――――――――――――>   │   表示更新        │
└─────────────────┘                         └─────────────────┘
```

### 通信フロー

1. **Vue.js → Flutter**: `window.flutter_inappwebview.callHandler()`
2. **Flutter → Vue.js**: `controller.evaluateJavascript()`
3. **データ形式**: JSON 形式でのメッセージ交換
4. **エラー制御**: 各層で try-catch、null 安全性チェック

---

## 📱 Flutter 側実装詳細

### main.dart の構造解析

#### 1. 依存関係とパッケージ設定

```dart
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
```

**flutter_inappwebview**: WebView 機能と JavaScript 通信を提供するパッケージ

- **利点**: ネイティブ性能、豊富なカスタマイズオプション
- **機能**: JavaScript↔Flutter 双方向通信、詳細設定制御

#### 2. WebViewScreen クラス - 状態管理

```dart
class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;  // WebView制御オブジェクト
  int _count = 0;  // カウント状態（Flutter側で永続化）
}
```

**重要ポイント**:

- `webViewController`: WebView との通信インターフェース
- `_count`: Flutter 側で管理するカウンター状態
- `setState()`: UI 更新のトリガー

#### 3. WebView 初期化と設定

```dart
InAppWebView(
  initialUrlRequest: URLRequest(url: WebUri("http://localhost:5173")),
  onWebViewCreated: (controller) {
    webViewController = controller;

    // JavaScript→Flutter通信ハンドラ登録
    controller.addJavaScriptHandler(
      handlerName: 'incrementCounter',  // JavaScript側から呼び出す関数名
      callback: (args) {
        return _incrementCount();  // 実際に実行される関数
      }
    );
  },
)
```

**解説**:

- `handlerName: 'incrementCounter'`: JavaScript 側が呼び出すエンドポイント名
- `callback`: Flutter 側で実行される関数を指定
- 戻り値は自動的に JavaScript 側に返却される

#### 4. コアロジック - カウント関数

```dart
int _incrementCount() {
  setState(() {
    _count++;  // 状態更新
  });

  print('Flutter: カウント実行 -> $_count');

  // Vue.js側に更新通知
  _notifyWebViewCountUpdate(_count);

  return _count;  // JavaScript側に返却
}
```

**動作フロー**:

1. **状態更新**: `setState()`で Flutter UI を再描画
2. **ログ出力**: デバッグ用コンソール出力
3. **通知送信**: Vue.js 側にリアルタイム通知
4. **値返却**: JavaScript 側に最新カウント値を返却

#### 5. Flutter→JavaScript 通信

```dart
void _notifyWebViewCountUpdate(int count) {
  webViewController?.evaluateJavascript(source: """
    if (window.onFlutterCountUpdate) {
      window.onFlutterCountUpdate($count);
    }
  """);
}
```

**仕組み**:

- `evaluateJavascript()`: WebView 内で JavaScript コードを実行
- 条件チェック: `window.onFlutterCountUpdate`の存在確認
- 安全な呼び出し: 関数が未定義でもエラー回避

---

## 🖥️ Vue.js 側実装詳細

### index.html - JavaScript Bridge 設定

#### 1. Flutter 通信ブリッジ定義

```javascript
window.flutterBridge = {
  callFlutterIncrement: async function () {
    try {
      console.log("Flutter関数呼び出し開始...");

      if (window.flutter_inappwebview) {
        const result = await window.flutter_inappwebview.callHandler(
          "incrementCounter"
        );
        console.log("Flutter関数呼び出し結果:", result);
        return result;
      } else {
        console.warn("Flutter bridge not available");
        return null;
      }
    } catch (error) {
      console.error("Flutter関数呼び出しエラー:", error);
      return null;
    }
  },
};
```

**重要機能**:

- **非同期処理**: `async/await`で Flutter 通信を制御
- **エラーハンドリング**: try-catch でエラーを安全に処理
- **状態確認**: `window.flutter_inappwebview`の存在チェック
- **結果返却**: Flutter 側からの戻り値をそのまま返却

#### 2. Flutter→Vue.js 通信受信

```javascript
window.onFlutterCountUpdate = function (count) {
  console.log("Flutter側からカウント更新通知:", count);

  // カスタムイベントでVue.jsコンポーネントに通知
  window.dispatchEvent(
    new CustomEvent("flutterCountUpdate", {
      detail: { count: count },
    })
  );
};
```

**通信パターン**:

- **コールバック関数**: Flutter 側から直接呼び出される
- **カスタムイベント**: Vue.js コンポーネントとの疎結合通信
- **データ形式**: `detail`プロパティでデータ送信

### CounterComponent.vue - メインロジック

#### 1. Vue.js リアクティブデータ

```javascript
data() {
  return {
    currentCount: 0,           // 表示用カウント値
    isLoading: false,          // ローディング状態
    statusMessage: '待機中',    // ステータス表示
    statusClass: 'status-idle', // CSS class制御
    communicationLogs: []      // 通信履歴ログ
  }
}
```

**データの役割**:

- `currentCount`: UI 表示のリアクティブデータ
- `isLoading`: ボタンの無効化制御
- `statusMessage/statusClass`: 動的スタイル適用
- `communicationLogs`: デバッグと動作確認用

#### 2. Flutter 関数呼び出しメソッド

```javascript
async callFlutterCounter() {
  this.isLoading = true;
  this.statusMessage = 'Flutter関数実行中...';
  this.statusClass = 'status-loading';

  this.addLog('JavaScript→Flutter通信開始');

  try {
    // Flutterブリッジ経由で関数実行
    const result = await window.flutterBridge.callFlutterIncrement();

    if (result !== null) {
      // 成功時の処理
      this.currentCount = result;
      this.statusMessage = `成功 (カウント: ${result})`;
      this.statusClass = 'status-success';
      this.addLog(`Flutter関数実行成功 -> カウント: ${result}`);
    } else {
      // エラー時の処理
      this.statusMessage = 'Flutter通信エラー';
      this.statusClass = 'status-error';
      this.addLog('Flutter関数実行エラー');
    }
  } catch (error) {
    // 例外処理
    console.error('Flutter通信エラー:', error);
    this.statusMessage = '通信例外発生';
    this.statusClass = 'status-error';
    this.addLog(`例外発生: ${error.message}`);
  } finally {
    this.isLoading = false;

    // 3秒後にステータスリセット
    setTimeout(() => {
      this.statusMessage = '待機中';
      this.statusClass = 'status-idle';
    }, 3000);
  }
}
```

**処理の流れ**:

1. **UI 状態更新**: ローディング表示、ボタン無効化
2. **通信実行**: Flutter 関数を非同期呼び出し
3. **結果処理**: 成功・失敗に応じて UI 更新
4. **ログ記録**: 全ての通信を履歴として保存
5. **状態復元**: 一定時間後に初期状態に戻る

#### 3. リアルタイム更新処理

```javascript
mounted() {
  // Flutter側からの通知を監視
  window.addEventListener('flutterCountUpdate', this.handleFlutterCountUpdate);
  this.addLog('Vue.jsコンポーネント初期化完了');
},

beforeUnmount() {
  // メモリリーク防止
  window.removeEventListener('flutterCountUpdate', this.handleFlutterCountUpdate);
},

handleFlutterCountUpdate(event) {
  const newCount = event.detail.count;
  this.currentCount = newCount;
  this.addLog(`Flutter→JavaScript通知受信: カウント${newCount}`);
}
```

**ライフサイクル管理**:

- **mounted**: コンポーネント初期化時にイベントリスナー登録
- **beforeUnmount**: メモリリーク防止のためリスナー削除
- **リアクティブ更新**: Flutter からの通知で即座に UI 更新

---

## 🔄 双方向通信の仕組み

### 通信パターン 1: Vue.js → Flutter

```
[Vue.js] ボタンクリック
    ↓
[JavaScript] window.flutterBridge.callFlutterIncrement()
    ↓
[Bridge] window.flutter_inappwebview.callHandler('incrementCounter')
    ↓
[Flutter] addJavaScriptHandler callback実行
    ↓
[Flutter] _incrementCount() 関数実行
    ↓
[Flutter] return値をJavaScript側に返却
```

### 通信パターン 2: Flutter → Vue.js

```
[Flutter] _notifyWebViewCountUpdate()実行
    ↓
[Flutter] webViewController.evaluateJavascript()
    ↓
[JavaScript] window.onFlutterCountUpdate()呼び出し
    ↓
[JavaScript] CustomEvent 'flutterCountUpdate'発火
    ↓
[Vue.js] handleFlutterCountUpdate()でイベント受信
    ↓
[Vue.js] リアクティブデータ更新 → UI自動再描画
```

---

## 💡 重要なコード解説

### 1. 非同期処理の安全な実装

```javascript
// ❌ 危険な実装例
function badCall() {
  const result = window.flutter_inappwebview.callHandler("incrementCounter");
  console.log(result); // Promiseオブジェクトが出力される
}

// ✅ 正しい実装
async function goodCall() {
  try {
    const result = await window.flutter_inappwebview.callHandler(
      "incrementCounter"
    );
    console.log(result); // 実際のカウント値が出力される
  } catch (error) {
    console.error("エラー:", error);
  }
}
```

### 2. null 安全性の確保

```javascript
// Flutter bridgeの存在確認
if (window.flutter_inappwebview) {
  // 安全に実行
} else {
  // フォールバック処理
}

// コントローラーの存在確認
webViewController?.evaluateJavascript(/* ... */);
```

### 3. メモリリーク防止

```javascript
// Vue.jsコンポーネント
beforeUnmount() {
  // 必ずイベントリスナーを削除
  window.removeEventListener('flutterCountUpdate', this.handleFlutterCountUpdate);
}
```

---

## 🚨 エラーハンドリング

### 1. 通信エラーのパターン

**接続エラー**:

```javascript
if (!window.flutter_inappwebview) {
  console.warn("Flutter bridge未初期化");
  return null;
}
```

**タイムアウトエラー**:

```javascript
const timeout = new Promise((_, reject) =>
  setTimeout(() => reject(new Error("Timeout")), 5000)
);

const result = await Promise.race([
  window.flutter_inappwebview.callHandler("incrementCounter"),
  timeout,
]);
```

**例外エラー**:

```javascript
try {
  const result = await window.flutterBridge.callFlutterIncrement();
} catch (error) {
  console.error("予期しないエラー:", error);
  // ユーザーフレンドリーなメッセージ表示
}
```

### 2. Flutter 側エラー処理

```dart
controller.addJavaScriptHandler(
  handlerName: 'incrementCounter',
  callback: (args) {
    try {
      return _incrementCount();
    } catch (e) {
      print('Flutter関数エラー: $e');
      return -1; // エラー値を返却
    }
  }
);
```

---

## ⚡ パフォーマンス考慮点

### 1. 通信頻度の制御

```javascript
// デバウンス処理で連続呼び出しを防ぐ
let isProcessing = false;

async function throttledCall() {
  if (isProcessing) return;

  isProcessing = true;
  try {
    await window.flutterBridge.callFlutterIncrement();
  } finally {
    setTimeout(() => {
      isProcessing = false;
    }, 100);
  }
}
```

### 2. ログ管理の最適化

```javascript
addLog(message) {
  this.communicationLogs.unshift({
    time: new Date().toLocaleTimeString('ja-JP'),
    message: message
  });

  // 配列サイズを制限（メモリ使用量制御）
  if (this.communicationLogs.length > 10) {
    this.communicationLogs = this.communicationLogs.slice(0, 10);
  }
}
```

### 3. DOM 更新の最適化

```javascript
// リアクティブデータを使用してバッチ更新
this.currentCount = newCount; // 自動的にバッチ処理される
this.statusMessage = newStatus; // 同じ更新サイクルで処理される
```

---

## 🔧 カスタマイズポイント

### 1. 新しい関数の追加

**Flutter 側**:

```dart
// 新しいハンドラー追加
controller.addJavaScriptHandler(
  handlerName: 'resetCounter',
  callback: (args) {
    setState(() { _count = 0; });
    return _count;
  }
);
```

**JavaScript 側**:

```javascript
window.flutterBridge.resetCounter = async function () {
  return await window.flutter_inappwebview.callHandler("resetCounter");
};
```

### 2. データ型の拡張

```dart
// 複雑なデータを返却
controller.addJavaScriptHandler(
  handlerName: 'getCounterData',
  callback: (args) {
    return {
      'count': _count,
      'timestamp': DateTime.now().toString(),
      'maxCount': 100
    };
  }
);
```

### 3. バリデーション追加

```javascript
async function validateAndCall() {
  // 入力値検証
  if (someCondition) {
    throw new Error("無効な操作です");
  }

  return await window.flutterBridge.callFlutterIncrement();
}
```

---

## 📚 学習ポイント

### 1. 非同期プログラミング

- `async/await`の適切な使用法
- Promise チェーンとエラーハンドリング
- 競合状態の回避方法

### 2. Vue.js リアクティビティ

- データの双方向バインディング
- コンポーネントライフサイクル
- イベントベース通信

### 3. Flutter Widget 管理

- StatefulWidget の状態管理
- WebView の詳細制御
- ネイティブ通信パターン

### 4. デバッグテクニック

- ブラウザ開発者ツールの活用
- Flutter Inspector の使用
- ログベースのトラブルシューティング

---

**この実装パターンを理解すれば、Flutter-Web 間の様々な連携アプリケーションが開発可能になります！🚀**
