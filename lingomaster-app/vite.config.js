import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    sourcemap: true, // Bật tính năng sourcemap cho bản build
  },
  server: {
    sourcemapIgnoreList: false,
  }
});