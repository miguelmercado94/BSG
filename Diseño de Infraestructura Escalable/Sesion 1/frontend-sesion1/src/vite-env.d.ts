/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
}

interface Window {
  /** Inyectado por public/runtime-config.js; en Docker se genera al arrancar desde BACKEND_URL. */
  __DOCVIZ_API_BASE__?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
