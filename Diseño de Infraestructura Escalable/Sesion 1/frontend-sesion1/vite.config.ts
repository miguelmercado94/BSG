import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const apiProxy = {
  "/api": {
    target: "http://127.0.0.1:8080",
    changeOrigin: true,
    rewrite: (p: string) => p.replace(/^\/api/, ""),
  },
};

export default defineConfig({
  plugins: [react()],
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
