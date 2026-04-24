/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_SECURITY_URL: string;
}

interface Window {
  /** Inyectado por public/runtime-config.js; en contenedor Nginx se genera al arrancar desde BACKEND_URL / SECURITY_URL. */
  __DOCVIZ_API_BASE__?: string;
  __DOCVIZ_SECURITY_BASE__?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
