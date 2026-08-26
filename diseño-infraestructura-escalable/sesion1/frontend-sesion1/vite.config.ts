import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import type { ProxyOptions } from "vite";
import { defineConfig } from "vitest/config";

/**
 * Ambos proxies apuntan al API Gateway (puerto 8080).
 * El gateway enruta:
 *   /docviz/**        → soporte-rag-mt (backend principal)
 *   /security-auth/** → back-security
 */
const longRunningApiProxy: ProxyOptions = {
  target: "http://127.0.0.1:8080",
  changeOrigin: true,
  rewrite: (p: string) => {
    const rest = p.replace(/^\/api/, "");
    return "/docviz" + (rest.startsWith("/") ? rest : `/${rest}`);
  },
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

const securityProxy: ProxyOptions = {
  target: "http://127.0.0.1:8080",
  changeOrigin: true,
  rewrite: (p) => p.replace(/^\/security-api/, "/security-auth"),
};

const apiProxy = {
  "/api": longRunningApiProxy,
  "/security-api": securityProxy,
  "/s3-proxy": {
    target: "http://127.0.0.1:4566",
    changeOrigin: true,
    rewrite: (p: string) => p.replace(/^\/s3-proxy/, ""),
  },
};

export default defineConfig({
  plugins: [react(), tailwindcss()],
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
