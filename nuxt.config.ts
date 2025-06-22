// https://nuxt.com/docs/api/configuration/nuxt-config
import tailwindcss from '@tailwindcss/vite';

export default defineNuxtConfig({
  modules: ['@nuxt/eslint'],
  css: ['./assets/css/main.css'],
  runtimeConfig: {
    authSecretPlaintext: '',
    proxyShapeUrl: ''
  },
  devServer: {
    port: 5173
  },
  future: {
    compatibilityVersion: 4
  },
  compatibilityDate: '2024-11-01',
  vite: {
    plugins: [
      tailwindcss()
    ]
  },
  eslint: {
    config: {
      stylistic: true
    }
  }
});
