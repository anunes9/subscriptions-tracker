import { fileURLToPath, URL } from 'node:url'
import inertia from '@inertiajs/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    inertia(),
    react(),
    VitePWA({
      // Rails serves index.html-equivalent pages itself, so the plugin can't
      // inject the registration <script> into a template — we call
      // `virtual:pwa-register` from app/javascript/entrypoints/application.js
      // instead.
      injectRegister: false,
      registerType: 'autoUpdate',
      manifestFilename: 'manifest.webmanifest',
      manifest: {
        name: 'Renewly',
        short_name: 'Renewly',
        description: 'Track every subscription and one-time expense in one place.',
        start_url: '/',
        scope: '/',
        display: 'standalone',
        theme_color: '#0f172a',
        background_color: '#0f172a',
        icons: [
          { src: '/icon.png', sizes: '512x512', type: 'image/png' },
          { src: '/icon.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        // Only precache this build's own JS/CSS app shell (under `assets/`,
        // Vite's default assetsDir) — everything else (Rails views, API
        // responses) is dynamic and handled by runtimeCaching. Scoping the
        // glob to `assets/` matters because production is configured with
        // an empty `publicOutputDir` (see config/vite.json), so Vite's
        // build outDir is `public/` itself — an unscoped glob would also
        // sweep up unrelated files sitting in `public/` (dev/test build
        // output, error pages, etc).
        globPatterns: ['assets/**/*.{js,css}'],
        navigateFallback: null,
        runtimeCaching: [
          {
            // Rails-rendered/Inertia pages: prefer the network so users
            // always see fresh data, but fall back to the cache when offline.
            urlPattern: ({ request }) => request.mode === 'navigate',
            handler: 'NetworkFirst',
            options: {
              cacheName: 'pages',
              networkTimeoutSeconds: 5,
            },
          },
          {
            // Fonts/images rarely change, so serve from cache first.
            urlPattern: ({ request }) => ['image', 'font'].includes(request.destination),
            handler: 'CacheFirst',
            options: {
              cacheName: 'assets',
              expiration: { maxEntries: 100, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
    }),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./app/javascript', import.meta.url)),
      '~': fileURLToPath(new URL('./app/javascript', import.meta.url)),
    },
  },
})
