import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// In local dev the two APIs run on different ports. Behind a real ingress or reverse
// proxy, the browser only ever talks to one origin and these proxies are not used.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api/products": "http://localhost:8080",
      "/api/calendar": "http://localhost:8080",
      "/api/events": "http://localhost:5000",
      "/api/bids": "http://localhost:5000",
    },
  },
});
