<template>
  <div class="counter-container">
    <!-- カウント表示エリア -->
    <div class="count-display">
      <h2>現在のカウント</h2>
      <div class="count-value">{{ currentCount }}</div>
      <p class="count-description">
        {{ currentCount === 0 ? 'まだカウントされていません' : `${currentCount}回カウントされました` }}
      </p>
    </div>

    <!-- Flutter関数呼び出しボタン -->
    <div class="button-area">
      <button 
        @click="callFlutterCounter" 
        :disabled="isLoading"
        class="increment-button"
      >
        <span v-if="!isLoading">Flutter関数呼出しTest</span>
        <span v-else>実行中...</span>
      </button>
    </div>

    <!-- 通信ステータス表示 -->
    <div class="status-area">
      <div :class="['status-indicator', statusClass]">
        {{ statusMessage }}
      </div>
    </div>

    <!-- 通信ログ -->
    <div class="log-area">
      <h3>通信ログ</h3>
      <div class="log-container">
        <div 
          v-for="(log, index) in communicationLogs" 
          :key="index"
          class="log-item"
        >
          <span class="log-time">{{ log.time }}</span>
          <span class="log-message">{{ log.message }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CounterComponent',
  data() {
    return {
      currentCount: 0,           // 現在のカウント値
      isLoading: false,          // ローディング状態
      statusMessage: '待機中',    // ステータスメッセージ  
      statusClass: 'status-idle', // ステータスCSS class
      communicationLogs: []      // 通信ログ
    }
  },
  mounted() {
    // Flutter側からのカウント更新通知を監視
    window.addEventListener('flutterCountUpdate', this.handleFlutterCountUpdate);
    
    this.addLog('Vue.jsコンポーネント初期化完了');
  },
  beforeUnmount() {
    // イベントリスナーを削除
    window.removeEventListener('flutterCountUpdate', this.handleFlutterCountUpdate);
  },
  methods: {
    /**
     * Flutter側のカウント関数を呼び出す
     */
    async callFlutterCounter() {
      this.isLoading = true;
      this.statusMessage = 'Flutter関数実行中...';
      this.statusClass = 'status-loading';
      
      this.addLog('JavaScript→Flutter通信開始');

      try {
        // Flutterブリッジ経由でカウント関数を呼び出し
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
        
        // 3秒後にステータスを待機中に戻す
        setTimeout(() => {
          this.statusMessage = '待機中';
          this.statusClass = 'status-idle';
        }, 3000);
      }
    },

    /**
     * Flutter側からのカウント更新通知を処理
     */
    handleFlutterCountUpdate(event) {
      const newCount = event.detail.count;
      this.currentCount = newCount;
      this.addLog(`Flutter→JavaScript通知受信: カウント${newCount}`);
    },

    /**
     * 通信ログに新しいエントリを追加
     */
    addLog(message) {
      const now = new Date();
      const timeString = now.toLocaleTimeString('ja-JP');
      
      this.communicationLogs.unshift({
        time: timeString,
        message: message
      });

      // ログの数を制限（最新10件のみ保持）
      if (this.communicationLogs.length > 10) {
        this.communicationLogs = this.communicationLogs.slice(0, 10);
      }
    }
  }
}
</script>

<style scoped>
.counter-container {
  background: rgba(255, 255, 255, 0.9);
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  max-width: 90%;
  width: 100%;
  backdrop-filter: blur(10px);
  margin: 0 auto;
}

/* カウント表示エリア */
.count-display {
  margin-bottom: 25px;
}

.count-display h2 {
  color: #333;
  margin-bottom: 12px;
  font-size: 18px;
}

.count-value {
  font-size: 42px;
  font-weight: bold;
  color: #667eea;
  margin: 12px 0;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
}

.count-description {
  color: #666;
  font-size: 13px;
  margin: 0;
}

/* ボタンエリア */
.button-area {
  margin-bottom: 20px;
}

.increment-button {
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: white;
  border: none;
  padding: 12px 24px;
  font-size: 16px;
  font-weight: bold;
  border-radius: 50px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
  min-width: 200px;
}

.increment-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(102, 126, 234, 0.6);
}

.increment-button:active:not(:disabled) {
  transform: translateY(0);
}

.increment-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

/* ステータスエリア */
.status-area {
  margin-bottom: 18px;
}

.status-indicator {
  padding: 6px 12px;
  border-radius: 15px;
  font-size: 12px;
  font-weight: 500;
  display: inline-block;
  min-width: 100px;
}

.status-idle {
  background-color: #f0f0f0;
  color: #666;
}

.status-loading {
  background-color: #ffeaa7;
  color: #d63031;
}

.status-success {
  background-color: #d4edda;
  color: #155724;
}

.status-error {
  background-color: #f8d7da;
  color: #721c24;
}

/* ログエリア */
.log-area {
  margin-top: 15px;
}

.log-area h3 {
  color: #333;
  margin-bottom: 8px;
  font-size: 14px;
}

.log-container {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 12px;
  max-height: 150px;
  overflow-y: auto;
  text-align: left;
}

.log-item {
  display: block;
  margin-bottom: 6px;
  font-size: 11px;
  line-height: 1.3;
}

.log-item:last-child {
  margin-bottom: 0;
}

.log-time {
  color: #666;
  font-weight: 500;
  margin-right: 8px;
}

.log-message {
  color: #333;
}

/* iPhone 16対応レスポンシブ (393×852px) */
@media (max-width: 430px) {
  .counter-container {
    padding: 15px;
    margin: 5px;
    border-radius: 15px;
    max-width: 95%;
  }
  
  .count-display h2 {
    font-size: 16px;
    margin-bottom: 10px;
  }
  
  .count-value {
    font-size: 36px;
    margin: 10px 0;
  }
  
  .count-description {
    font-size: 12px;
  }
  
  .increment-button {
    padding: 10px 20px;
    font-size: 15px;
    min-width: 180px;
  }
  
  .log-container {
    max-height: 120px;
    padding: 10px;
  }
  
  .log-item {
    font-size: 10px;
    margin-bottom: 4px;
  }
  
  .log-time {
    margin-right: 6px;
  }
}

/* 小型スマートフォン対応 */
@media (max-width: 375px) {
  .counter-container {
    padding: 12px;
    margin: 3px;
  }
  
  .count-value {
    font-size: 32px;
  }
  
  .increment-button {
    font-size: 14px;
    padding: 8px 16px;
    min-width: 160px;
  }
  
  .log-area h3 {
    font-size: 13px;
  }
}
</style>