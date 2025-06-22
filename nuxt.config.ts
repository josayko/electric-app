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
      tailwindcss(),
      {
        // https://github.com/tailwindlabs/tailwindcss/discussions/16119
        name: 'vite-plugin-ignore-sourcemap-warnings',
        apply: 'build',
        configResolved(config) {
          config.build.rollupOptions.onwarn = (warning, warn) => {
            if (
              warning.code === 'SOURCEMAP_BROKEN'
              && warning.plugin === '@tailwindcss/vite:generate:build'
            ) {
              return;
            }

            warn(warning);
          };
        }
      }
    ]
  },
  eslint: {
    config: {
      stylistic: true
    }
  }
});
