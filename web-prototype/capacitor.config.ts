import type { CapacitorConfig } from '@capacitor/cli';

/**
 * Capacitor configuration — wraps the built web game into a native Android app
 * for the Google Play Store.
 *
 * Build flow:
 *   1. npm run build          → compiles the game into dist/
 *   2. npx cap add android    → scaffolds the native android/ project (once)
 *   3. npm run cap:sync       → copies dist/ into the native shell
 *   4. npm run android:open   → opens Android Studio to run / build an AAB
 *
 * The applicationId below is a placeholder — change it to your own reverse-DNS
 * identifier before publishing (it is permanent once live on Play).
 */
const config: CapacitorConfig = {
  appId: 'com.aethelgard.bastionrush',
  appName: 'Bastion Rush',
  webDir: 'dist',
  backgroundColor: '#060810',
  android: {
    backgroundColor: '#060810',
    // Keep the WebView opaque for best performance.
    webContentsDebuggingEnabled: false,
    allowMixedContent: false,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 800,
      backgroundColor: '#060810',
      showSpinner: false,
    },
  },
};

export default config;
