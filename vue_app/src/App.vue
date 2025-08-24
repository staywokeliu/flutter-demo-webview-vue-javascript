<template>
  <div id="app">
    <!-- メインヘッダー -->
    <header class="app-header">
      <h1>Vue.js ↔ Flutter 双方向通信デモ</h1>
    </header>

    <!-- カウンターコンポーネント -->
    <main class="app-main">
      <CounterComponent />
    </main>

    <!-- フッター -->
    <footer class="app-footer">
      <p>Vue.js側で表示中</p>
    </footer>
  </div>
</template>

<script>
import CounterComponent from './components/CounterComponent.vue'

export default {
  name: 'App',
  components: {
    CounterComponent
  }
}
</script>

<style scoped>
#app {
  font-family: 'Arial', sans-serif;
  text-align: center;
  color: #2c3e50;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.app-header {
  background-color: rgba(255, 255, 255, 0.1);
  padding: 15px;
  backdrop-filter: blur(10px);
}

.app-header h1 {
  margin: 0;
  color: white;
  font-size: 20px;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
  line-height: 1.2;
}

.app-main {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px 10px;
  min-height: 0; /* Flexboxの高さ制約を解除 */
}

.app-footer {
  background-color: rgba(0, 0, 0, 0.1);
  padding: 10px;
  color: white;
  font-size: 12px;
}

.app-footer p {
  margin: 0;
}
</style>