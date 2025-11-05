import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

// Use relative paths for assets so they work with Traefik stripPath: true
// Browser at /{sessionId}/ loads ./assets/... which becomes /{sessionId}/assets/...
// Traefik strips /{sessionId} and forwards /assets/... to container
export default defineConfig({
  plugins: [react()],
  root: resolve(__dirname, 'src/frontend'),
  base: './', // Relative paths work with stripPath: true routing
  build: {
    outDir: resolve(__dirname, 'dist/client'),
    emptyOutDir: true,
  },
  server: {
    port: 5173,
  },
});
