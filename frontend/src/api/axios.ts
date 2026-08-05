import axios from "axios";

const baseURL = import.meta.env.VITE_API_BASE_URL || "https://durian-guardian-ai.onrender.com/api/v1";

const apiClient = axios.create({
  baseURL,
  timeout: 30000,
  headers: {
    "Content-Type": "application/json",
    "ngrok-skip-browser-warning": "69420",
  },
});

export default apiClient;
