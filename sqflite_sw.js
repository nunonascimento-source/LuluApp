// Service worker for sqflite on web
importScripts('https://unpkg.com/sql.js@1.10.0/dist/sql-wasm.js');

let dbInstance = null;

self.onmessage = async (event) => {
  const { method, args } = event.data;
  try {
    if (method === 'init') {
      if (!dbInstance) {
        const SQL = await initSqlJs();
        dbInstance = new SQL.Database();
      }
      self.postMessage({ result: 'initialized' });
    }
  } catch (error) {
    self.postMessage({ error: error.message });
  }
};
