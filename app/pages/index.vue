<script setup lang="ts">
import { Shape, ShapeStream, type Row } from '@electric-sql/client';
import type { UserShape } from '../../server/utils/types';

// Define row type
interface Todos extends Row<unknown> {
  id: number;
  description: string;
  completed: boolean;
  created_at: Date; // We want this to be a Date object
}

const todos = ref<Todos[]>([]);
const getTokenFromShape = async (shape: UserShape) => {
  const token = await $fetch('/api/gatekeeper/token', {
    method: 'POST',
    body: shape
  });
  return token;
};

try {
  const { data: shapeConfig } = await useFetch('/api/gatekeeper/todo');
  if (shapeConfig.value?.status === 'success') {
    const userShape = shapeConfig.value.userShape;
    const stream = new ShapeStream<Todos>({
      url: shapeConfig.value.url,
      params: {
        table: shapeConfig.value.table
      },
      headers: {
        Authorization: async () => `Bearer ${await getTokenFromShape(userShape)}`
      },
      parser: {
        // Parse timestamp columns into JavaScript Date objects
        timestamptz: (date: string) => new Date(date)
      }
    });

    const shape = new Shape(stream);

    shape.subscribe((data) => {
      todos.value = data.rows;
    });
  }
}
catch (error) {
  console.error(error);
  todos.value = [];
}
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
