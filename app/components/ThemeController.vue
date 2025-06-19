<script setup lang="ts">
import { useStorage } from '@vueuse/core';

// Tell useStorage to wait until the component is mounted before reading the value.
const theme = useStorage('theme', 'light', undefined, {
  initOnMounted: true
});

const toggleTheme = () => {
  theme.value = theme.value === 'dark' ? 'light' : 'dark';
};

// watcher to apply the data-theme attribute.
watch(theme, (newTheme) => {
  if (import.meta.client) {
    document.documentElement.setAttribute('data-theme', newTheme);
  }
}, { immediate: true });
</script>

<template>
  <label class="swap swap-rotate">
    <input
      type="checkbox"
      :checked="theme === 'dark'"
      @click="toggleTheme"
    >
    <div class="swap-on">DARKMODE</div>
    <div class="swap-off">LIGHTMODE</div>
  </label>
</template>
