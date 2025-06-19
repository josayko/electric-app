<script setup lang="ts">
import { Shape, ShapeStream, type Row } from '@electric-sql/client';

const config = useRuntimeConfig();

// Define row type
interface Todos extends Row<unknown> {
  id: number;
  description: string;
  completed: boolean;
  created_at: Date; // We want this to be a Date object
}

const todos = ref<Todos[]>([]);

const stream = new ShapeStream<Todos>({
  url: config.public.electricUrl,
  params: {
    table: 'todo',
    secret: config.public.electricSecret
  },
  parser: {
    // Parse timestamp columns into JavaScript Date objects
    timestamptz: (date: string) => new Date(date)
  }
});
const shape = new Shape(stream);

onMounted(() => {
  // The callback runs every time the Shape data changes.
  shape.subscribe((data) => {
    todos.value = data.rows;
    console.log(data);
  });
});
</script>

<template>
  <div class="flex flex-col items-center h-screen">
    <div class="flex justify-between items-center gap-8">
      <h1 class="text-3xl font-bold">
        Electric App
      </h1>
      <ThemeController />
    </div>
    <ul>
      <li
        v-for="todo in todos"
        :key="todo.id"
        class="mb-2"
      >
        <div class="card bg-base-100 w-96 shadow-sm">
          <div class="card-body">
            <h2 class="card-title">
              {{ todo.description }}
            </h2>
            <p>
              {{ todo.completed }}
            </p>
            <p>
              {{ todo.created_at }}
            </p>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
