import { fileURLToPath, URL } from 'node:url'
import inertia from '@inertiajs/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [RubyPlugin(), inertia(), react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./app/javascript', import.meta.url)),
      '~': fileURLToPath(new URL('./app/javascript', import.meta.url)),
    },
  },
})
