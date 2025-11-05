import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

// Note: SESSION_ID is not available at build time in Docker, only at runtime
// We build with base: '/' and handle path routing in Express at runtime
export default defineConfig({
  plugins: [react()],
  root: resolve(__dirname, 'src/frontend'),
  base: '/', // Always use root - Express will handle path prefix at runtime
  build: {
    outDir: resolve(__dirname, 'dist/client'),
    emptyOutDir: true,
  },
  server: {
    port: 5173,
  },
});
