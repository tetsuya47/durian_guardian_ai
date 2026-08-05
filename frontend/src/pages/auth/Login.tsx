import { useState } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  Loader2,
  Brain,
  CloudSun,
  Layers,
  ShieldAlert,
  ArrowRight,
  Sprout,
} from "lucide-react";
import { useAuth } from "../../hooks/useAuth";

const FEATURES = [
  {
    icon: Brain,
    title: "AI Disease Detection",
    desc: "Phát hiện bệnh sớm bằng trí tuệ nhân tạo",
  },
  {
    icon: CloudSun,
    title: "Weather Intelligence",
    desc: "Dự báo thời tiết chính xác cho từng khu vực",
  },
  {
    icon: Layers,
    title: "Farm Digital Twin",
    desc: "Mô phỏng và quản lý trang trại số 3D",
  },
  {
    icon: ShieldAlert,
    title: "Early Warning System",
    desc: "Cảnh báo rủi ro sớm giúp giảm thiểu thiệt hại",
  },
];

export default function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login, isAuthenticated } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const from = (location.state as { from?: { pathname: string } })?.from?.pathname || "/";

  if (isAuthenticated) {
    navigate(from, { replace: true });
    return null;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (!email.trim() || !password.trim()) {
      setError("Vui lòng nhập email và mật khẩu.");
      return;
    }

    setLoading(true);
    try {
      await login({ username: email.trim(), password });
      if (rememberMe) {
        localStorage.setItem("dga_remember_email", email.trim());
      } else {
        localStorage.removeItem("dga_remember_email");
      }
      navigate(from, { replace: true });
    } catch (err: unknown) {
      const msg =
        err instanceof Error
          ? err.message
          : "Đăng nhập thất bại. Vui lòng kiểm tra lại email và mật khẩu.";
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-screen w-screen overflow-hidden flex bg-[#F8FAF8] select-none font-sans">
      {/* ── 1. HERO SECTION (BÊN TRÁI - Desktop 60%, Laptop 55%, Tablet 50%, Mobile Hidden) ── */}
      <div className="hidden md:flex md:w-[50%] lg:w-[55%] xl:w-[60%] relative overflow-hidden flex-col justify-between p-8 lg:p-12 xl:p-14 text-white">
        {/* Background Image: /images/login/hero-durian.jpg */}
        <div
          className="absolute inset-0 bg-cover bg-center pointer-events-none"
          style={{
            backgroundImage: "url('/images/login/hero-durian.jpg')",
          }}
        />

        {/* Overlay: linear-gradient(90deg, rgba(0, 50, 20, 0.25) 0%, rgba(0, 50, 20, 0.15) 100%) */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "linear-gradient(90deg, rgba(0, 50, 20, 0.25) 0%, rgba(0, 50, 20, 0.15) 100%)",
          }}
        />

        {/* Top Left Logo Pill Badge */}
        <div className="relative z-10 flex items-center">
          <div className="bg-white/95 backdrop-blur-md px-4 py-2 rounded-full shadow-md flex items-center gap-2.5 border border-white/30">
            <div className="w-6 h-6 rounded-full bg-[#E8F5E9] text-[#2E7D32] flex items-center justify-center font-bold">
              <Sprout className="w-4 h-4" />
            </div>
            <div className="text-xs font-black tracking-tight leading-none">
              <span className="text-[#1B5E20]">Vie-farm</span>{" "}
              <span className="text-gray-500 font-medium">Portal</span>
            </div>
          </div>
        </div>

        {/* Center Main Headline & Description & 4 Feature Cards */}
        <div className="relative z-10 my-auto space-y-6 max-w-2xl">
          <div className="space-y-1">
            <h1 className="text-3xl lg:text-4xl xl:text-5xl font-black tracking-tight leading-none text-white drop-shadow-md">
              Vie-farm{" "}
              <span className="text-[#4ADE80]">
                AI
              </span>{" "}
              Operating System
            </h1>
            <p className="text-sm xl:text-base font-bold text-emerald-200 pt-1 drop-shadow-sm">
              for Smart Durian Farms
            </p>
          </div>

          <p className="text-xs lg:text-sm text-white/95 leading-relaxed max-w-xl font-medium drop-shadow-xs bg-emerald-950/40 p-3.5 rounded-2xl backdrop-blur-xs border border-white/15">
            Nền tảng AI giúp doanh nghiệp quản lý trang trại sầu riêng, phát hiện bệnh sớm, phân tích rủi ro, theo dõi sức khỏe cây theo thời gian thực.
          </p>

          {/* 4 Feature Cards (2x2 Grid) */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 pt-1">
            {FEATURES.map((item, idx) => (
              <div
                key={idx}
                className="bg-[#1B5E20]/85 backdrop-blur-md rounded-[20px] p-3.5 border border-emerald-400/30 shadow-md flex items-start gap-3 transition-all hover:bg-[#1B5E20]/95 hover:border-emerald-300/60"
              >
                <div className="w-9 h-9 rounded-xl bg-[#2E7D32] text-[#E8F5E9] flex items-center justify-center flex-shrink-0 border border-emerald-400/40 shadow-xs">
                  <item.icon className="w-4.5 h-4.5" />
                </div>
                <div className="space-y-0.5 min-w-0">
                  <h3 className="text-xs font-black text-white leading-snug">{item.title}</h3>
                  <p className="text-[11px] text-emerald-100/90 font-medium leading-tight">
                    {item.desc}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Decorative Bottom Leaf Accent */}
        <div className="relative z-10 text-[11px] font-bold text-emerald-200 flex items-center gap-2 drop-shadow-xs">
          <div className="w-6 h-[2px] bg-emerald-400 rounded-full" />
          <span>Hệ thống Quản trị Trang trại Sầu Riêng Thông Minh</span>
        </div>
      </div>

      {/* ── 2. LOGIN PANEL (BÊN PHẢI - Desktop 40%, Laptop 45%, Tablet 50%, Mobile 100%) ── */}
      <div className="flex-1 flex flex-col justify-between items-center p-6 sm:p-8 lg:p-10 min-h-screen overflow-y-auto bg-[#F8FAF8]">
        <div className="w-full flex-1 flex flex-col items-center justify-center my-auto">
          {/* Centered Login Card (bo 28px, shadow 0 12px 40px rgba(0,0,0,0.08)) */}
          <div className="bg-white rounded-[28px] p-7 sm:p-9 shadow-[0_12px_40px_rgba(0,0,0,0.08)] max-w-[420px] w-full border border-[#E8F5E9] space-y-5">
            {/* Circular Durian Sprout Emblem */}
            <div className="flex justify-center">
              <div className="w-14 h-14 rounded-full bg-[#E8F5E9] border border-[#2E7D32]/25 flex items-center justify-center text-[#2E7D32] shadow-inner">
                <Sprout className="w-7 h-7 text-[#2E7D32]" />
              </div>
            </div>

            {/* Form Title & Subtitle */}
            <div className="text-center space-y-1">
              <h2 className="text-2xl font-black text-[#1B5E20] tracking-tight">
                Chào mừng trở lại!
              </h2>
              <p className="text-xs text-gray-500 font-medium">
                Đăng nhập để truy cập hệ thống Vie-farm Portal
              </p>
            </div>

            {/* Error Banner */}
            {error && (
              <div className="px-3.5 py-2.5 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700 font-bold flex items-center gap-2 animate-[shake_0.3s_ease-in-out]">
                <span className="w-1.5 h-1.5 rounded-full bg-rose-600 flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {/* Login Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Email Input (h-14, bo 16px, bg-[#F8FAF8]) */}
              <div className="space-y-1.5">
                <label className="block text-xs font-extrabold text-gray-700">Email</label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="bao@gmail.com"
                    className="w-full pl-10 pr-4 h-14 text-xs bg-[#F8FAF8] border border-[#2E7D32] rounded-[16px] focus:outline-none focus:ring-2 focus:ring-[#2E7D32] font-semibold text-gray-900 placeholder-gray-400 transition-all"
                  />
                </div>
              </div>

              {/* Password Input (h-14, bo 16px, bg-[#F8FAF8]) */}
              <div className="space-y-1.5">
                <label className="block text-xs font-extrabold text-gray-700">Mật khẩu</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type={showPassword ? "text" : "password"}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full pl-10 pr-10 h-14 text-xs bg-[#F8FAF8] border border-gray-200 focus:border-[#2E7D32] rounded-[16px] focus:outline-none focus:ring-2 focus:ring-[#2E7D32] font-semibold text-gray-900 placeholder-gray-400 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors cursor-pointer"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Checkbox & Forgot Password Same Row */}
              <div className="flex items-center justify-between text-xs font-medium text-gray-600 pt-0.5">
                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="w-4 h-4 rounded border-gray-300 text-[#2E7D32] focus:ring-[#2E7D32] cursor-pointer"
                  />
                  <span>Ghi nhớ đăng nhập</span>
                </label>
                <button
                  type="button"
                  onClick={() => alert("Vui lòng liên hệ Quản trị viên hệ thống để khôi phục mật khẩu.")}
                  className="font-bold text-[#2E7D32] hover:underline cursor-pointer"
                >
                  Quên mật khẩu?
                </button>
              </div>

              {/* Primary Submit Button (h-14, bo 16px or pill, #2E7D32) */}
              <button
                type="submit"
                disabled={loading}
                className="w-full h-14 px-6 rounded-full bg-[#2E7D32] hover:bg-[#1B5E20] text-white font-extrabold text-xs shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer group active:scale-[0.99] disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Đang xử lý...</span>
                  </>
                ) : (
                  <>
                    <span>Đăng nhập</span>
                    <div className="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center group-hover:translate-x-0.5 transition-transform">
                      <ArrowRight className="w-3.5 h-3.5 text-white" />
                    </div>
                  </>
                )}
              </button>
            </form>

            {/* Divider with text "hoặc" */}
            <div className="relative my-4">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-100" />
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="bg-white px-3 text-gray-400 font-medium">hoặc</span>
              </div>
            </div>

            {/* Button Google (bo 16px) */}
            <button
              type="button"
              onClick={() => alert("Tính năng Đăng nhập với Google đang được bảo trì.")}
              className="w-full h-12 px-4 rounded-[16px] border border-gray-200 bg-white hover:bg-gray-50 text-gray-700 font-bold text-xs flex items-center justify-center gap-2.5 shadow-2xs transition-all cursor-pointer"
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                />
              </svg>
              <span>Đăng nhập với Google</span>
            </button>

            {/* Link "Chưa có tài khoản? Đăng ký ngay" */}
            <p className="text-center text-xs text-gray-600 font-medium pt-1">
              Chưa có tài khoản?{" "}
              <Link to="/register" className="text-[#2E7D32] font-extrabold hover:underline">
                Đăng ký ngay
              </Link>
            </p>
          </div>

          {/* Footer slogan bên dưới card */}
          <div className="mt-6 text-center text-xs font-bold text-[#1B5E20] flex items-center justify-center gap-1.5">
            <span>🌿</span>
            <span>Bảo vệ từng cây – Kiến tạo tương lai xanh</span>
            <span>🍃</span>
          </div>
        </div>
      </div>
    </div>
  );
}
