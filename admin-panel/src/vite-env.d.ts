/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Base URL of the ADVOK backend API, e.g. http://<ec2-ip>:4000/api */
  readonly VITE_API_BASE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
