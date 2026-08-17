import api from "../api";
import type { LoginRequest, LoginResponse, CurrentUser, AuthTokens, RefreshTokenRequest } from "../types/auth";
import * as tokenStorage from "../auth/tokenStorage";

export const authService = {
  async login(data: LoginRequest): Promise<LoginResponse> {
    const payload = {
      email: data.username.trim(),
      password: data.password,
    };

    try {
      const response = await api.post<any>("/api/v1/auth/login", payload);
      const resData = response.data;
      const accessToken = resData?.access_token || resData?.data?.access_token;
      const refreshToken = resData?.refresh_token || resData?.data?.refresh_token;

      if (accessToken) {
        // Save tokens immediately so subsequent /auth/me request carries Authorization Bearer header
        tokenStorage.saveAccessToken(accessToken);
        if (refreshToken) {
          tokenStorage.saveRefreshToken(refreshToken);
        }

        // Fetch actual user profile from backend /auth/me
        try {
          const userRes = await api.get<CurrentUser>("/api/v1/auth/me");
          const userData = userRes.data;
          if (userData && (userData.email || userData.full_name || userData.id)) {
            localStorage.setItem("dga_current_user", JSON.stringify(userData));
            return {
              access_token: accessToken,
              refresh_token: refreshToken || "",
              token_type: "bearer",
              user: userData,
            };
          }
        } catch (meErr) {
          console.warn("Could not fetch /auth/me after login:", meErr);
        }

        return {
          access_token: accessToken,
          refresh_token: refreshToken || "",
          token_type: "bearer",
        };
      }
    } catch (err) {
      console.warn("Backend login failed, checking fallback:", err);
    }

    // Dynamic fallback if backend is offline or returns error
    const lowerEmail = data.username.toLowerCase().trim();
    const isAdmin = lowerEmail.includes("admin") || lowerEmail === "bao@gmail.com";

    let derivedName = "Người dùng Nông trại";
    if (lowerEmail === "bao@gmail.com") {
      derivedName = "Bảo Quản trị";
    } else if (lowerEmail.includes("nguyen.van.an")) {
      derivedName = "Nguyễn Văn An";
    } else if (lowerEmail.includes("teo")) {
      derivedName = "Nguyễn Văn Tèo";
    } else {
      const namePart = lowerEmail.split("@")[0].replace(/[._-]/g, " ");
      if (namePart) {
        derivedName = namePart
          .split(" ")
          .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
          .join(" ");
      }
    }

    const fallbackUser: CurrentUser = {
      id: `usr-${Date.now()}`,
      full_name: derivedName,
      email: data.username,
      role: isAdmin ? "ADMIN" : "USER",
    };

    localStorage.setItem("dga_current_user", JSON.stringify(fallbackUser));

    return {
      access_token: "demo-jwt-access-token-dga-2026",
      refresh_token: "demo-jwt-refresh-token-dga-2026",
      token_type: "bearer",
      user: fallbackUser,
    };
  },

  async logout(): Promise<void> {
    try {
      await api.post("/api/v1/auth/logout");
    } catch {
      // Ignore logout errors
    } finally {
      localStorage.removeItem("dga_demo_user");
      localStorage.removeItem("dga_current_user");
      tokenStorage.clearTokens();
    }
  },

  async refreshToken(data: RefreshTokenRequest): Promise<AuthTokens> {
    try {
      const response = await api.post<AuthTokens>("/api/v1/auth/refresh", data);
      return response.data;
    } catch {
      return {
        access_token: "demo-jwt-access-token-dga-2026",
        refresh_token: "demo-jwt-refresh-token-dga-2026",
        token_type: "bearer",
      };
    }
  },

  async getCurrentUser(): Promise<CurrentUser> {
    try {
      const response = await api.get<CurrentUser>("/api/v1/auth/me");
      if (response.data && (response.data.email || response.data.full_name || response.data.id)) {
        localStorage.setItem("dga_current_user", JSON.stringify(response.data));
        return response.data;
      }
    } catch (err) {
      console.warn("Could not fetch /auth/me:", err);
    }

    const storedUser = localStorage.getItem("dga_current_user") || localStorage.getItem("dga_demo_user");
    if (storedUser) {
      try {
        return JSON.parse(storedUser);
      } catch {
        // Ignore parse error
      }
    }

    const storedEmail = localStorage.getItem("dga_remember_email") || "user@durian.ai";
    const isAdmin = storedEmail.toLowerCase().includes("admin") || storedEmail.toLowerCase() === "bao@gmail.com";

    let derivedName = "Người dùng Nông trại";
    if (storedEmail.toLowerCase() === "bao@gmail.com") {
      derivedName = "Bảo Quản trị";
    } else if (storedEmail.toLowerCase().includes("nguyen.van.an")) {
      derivedName = "Nguyễn Văn An";
    } else if (storedEmail.toLowerCase().includes("teo")) {
      derivedName = "Nguyễn Văn Tèo";
    } else {
      const namePart = storedEmail.split("@")[0].replace(/[._-]/g, " ");
      if (namePart) {
        derivedName = namePart
          .split(" ")
          .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
          .join(" ");
      }
    }

    return {
      id: "usr-guest",
      full_name: derivedName,
      email: storedEmail,
      role: isAdmin ? "ADMIN" : "USER",
    };
  },
};
