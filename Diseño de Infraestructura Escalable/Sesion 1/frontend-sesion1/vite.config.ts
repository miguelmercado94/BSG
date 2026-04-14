import react from "@vitejs/plugin-react";
import type { ProxyOptions } from "vite";
import { defineConfig } from "vitest/config";

/**
 * POST /vector/ingest/stream puede tardar muchos minutos (NDJSON).
 * El proxy de Node por defecto corta la conexión y el cliente nunca recibe phase DONE.
 */
const longRunningApiProxy: ProxyOptions = {
  target: "http://127.0.0.1:8080",
  changeOrigin: true,
  rewrite: (p: string) => p.replace(/^\/api/, ""),
  timeout: 86_400_000,
  proxyTimeout: 86_400_000,
  configure(proxy) {
    proxy.on("proxyReq", (proxyReq, req) => {
      proxyReq.setTimeout(0);
      req.socket?.setTimeout(0);
    });
    proxy.on("proxyRes", (proxyRes) => {
      proxyRes.setTimeout(0);
    });
  },
};

const apiProxy = {
  "/api": longRunningApiProxy,
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
