export default defineEventHandler((event) => {
  console.log('/api/shapes/todo');
  return {
    shape: 'todo'
  };
});
