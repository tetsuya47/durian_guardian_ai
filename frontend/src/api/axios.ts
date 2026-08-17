import axios from "axios";

const isLocalhost =
  typeof window !== "undefined" &&
  (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1");

const rawBaseURL =
  import.meta.env.VITE_API_BASE_URL ||
  (isLocalhost ? "http://localhost:8000" : "https://durian-guardian-ai.onrender.com");

// Strip trailing /api/v1 to prevent double /api/v1/api/v1 404 errors
const baseURL = rawBaseURL.replace(/\/api\/v1\/?$/, "");

const apiClient = axios.create({
  baseURL,
  timeout: 30000,
  headers: {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "69420",
  },
});

export default apiClient;


