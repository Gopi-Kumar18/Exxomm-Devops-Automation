// vite.config.js
import {defineConfig} from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],

  server: {
    proxy: {
      // Any request starting with /api will be sent to localhost:3000
      '/api': {
        target: 'localhost:3000',
        changeOrigin: true,
      },
    },
  },

})
