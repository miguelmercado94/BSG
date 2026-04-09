import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

const apiProxy = {
  "/api": {
    target: "http://127.0.0.1:8080",
    changeOrigin: true,
    rewrite: (p: string) => p.replace(/^\/api/, ""),
  },
};

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    include: ["src/**/*.test.{ts,tsx}"],
  },
  server: {
    port: 5173,
    proxy: { ...apiProxy },
  },
  // Sin esto, `vite preview` no reenvía /api al backend y las rutas del API dan 404.
  preview: {
    port: 4173,
    proxy: { ...apiProxy },
  },
});
