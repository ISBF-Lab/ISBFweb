import { defineConfig } from "vite";

export default defineConfig({
  base: "/join/",
  server: {
    fs: {
      deny: [
        ".env",
        ".env.*",
        "**/.git/**",
        "**/.private/**",
        "**/*.{crt,pem}",
      ],
    },
  },
  build: {
    copyPublicDir: false,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("/node_modules/three/")) {
            return "three";
          }
        },
      },
    },
    // The Three.js engine loads only with the scene module; its gzip size is
    // ~145 kB. The initial interface remains a separate small entry point.
    chunkSizeWarningLimit: 600,
  },
});
