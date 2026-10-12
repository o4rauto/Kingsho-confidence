import { defineConfig } from 'vite';

// Bastion Rush build config.
// `base: './'` keeps asset paths relative so the built bundle works both on the
// web and inside the Capacitor Android WebView (file:// origin).
export default defineConfig({
  base: './',
  server: {
    host: true,
    port: 5173,
  },
  build: {
    target: 'es2021',
    outDir: 'dist',
    assetsInlineLimit: 0,
    chunkSizeWarningLimit: 1600,
    rollupOptions: {
      output: {
        manualChunks: {
          phaser: ['phaser'],
        },
      },
    },
  },
});
