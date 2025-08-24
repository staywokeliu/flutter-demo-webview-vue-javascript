import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0', // 外部からのアクセスを許可（Flutter WebViewからアクセス可能）
    port: 5173,
    cors: true, // CORS有効化
  }
})