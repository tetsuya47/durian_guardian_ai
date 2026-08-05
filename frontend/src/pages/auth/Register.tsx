import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  User,
  Mail,
  Lock,
  Eye,
  EyeOff,
  Loader2,
  Brain,
  CloudSun,
  Layers,
  ShieldAlert,
  Sprout,
  CheckCircle2,
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

export default function RegisterPage() {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();

  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  if (isAuthenticated) {
    navigate("/", { replace: true });
    return null;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess("");

    if (!fullName.trim() || !email.trim() || !password) {
      setError("Vui lòng nhập đầy đủ thông tin.");
      return;
    }
    if (password.length < 8) {
      setError("Mật khẩu phải có ít nhất 8 ký tự.");
      return;
    }
    if (password !== confirmPassword) {
      setError("Mật khẩu xác nhận không khớp.");
      return;
    }

    setLoading(true);
    try {
      const api = (await import("../../api")).default;
      await api.post("/auth/register", {
        full_name: fullName.trim(),
        email: email.trim(),
        password,
      });
      setSuccess("Đăng ký thành công! Đang chuyển đến trang đăng nhập...");
      setTimeout(() => navigate("/login", { replace: true }), 1500);
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } };
      const msg =
        axiosErr?.response?.data?.message ||
        (err instanceof Error ? err.message : "Đăng ký thất bại. Email có thể đã được sử dụng.");
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const hasLength = password.length >= 8;
  const hasNumber = /\d/.test(password);
  const hasUpperLower = /[a-z]/.test(password) && /[A-Z]/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  return (
    <div className="h-screen w-screen overflow-hidden flex bg-[#FAFBF8] select-none font-sans">
      {/* ── 1. LEFT HERO SECTION (Desktop 60%, Laptop 55%, Tablet Hidden, Mobile Hidden) ── */}
      <div className="hidden lg:flex lg:w-[55%] xl:w-[60%] relative overflow-hidden flex-col justify-between p-8 lg:p-12 xl:p-14 text-white">
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
              <span className="text-[#184D2F]">Vie-farm</span>{" "}
              <span className="text-gray-500 font-medium">Portal</span>
            </div>
          </div>
        </div>

        {/* Center Main Headline & Description & 4 Feature Cards */}
        <div className="relative z-10 my-auto space-y-6 max-w-2xl">
          <div className="space-y-1">
            <h1 className="text-3xl lg:text-4xl xl:text-5xl font-black tracking-tight leading-none text-white drop-shadow-md">
              Tham gia cùng{" "}
              <span className="text-[#A8F13C]">
                Vie-farm AI
              </span>
            </h1>
            <p className="text-xs lg:text-sm text-white/95 leading-relaxed max-w-xl font-medium pt-2 drop-shadow-xs bg-[#184D2F]/40 p-3.5 rounded-2xl backdrop-blur-xs border border-white/15">
              Tạo tài khoản để bắt đầu quản lý trang trại sầu riêng với hỗ trợ trí tuệ nhân tạo.
            </p>
          </div>

          {/* 4 Feature Cards (2x2 Grid) */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 pt-1">
            {FEATURES.map((item, idx) => (
              <div
                key={idx}
                className="bg-[#184D2F]/85 backdrop-blur-md rounded-[20px] p-3.5 border border-emerald-400/30 shadow-md flex items-start gap-3 transition-all hover:bg-[#184D2F]/95 hover:border-emerald-300/60"
              >
                <div className="w-9 h-9 rounded-xl bg-[#2E7D32] text-[#E8F5E9] flex items-center justify-center flex-shrink-0 border border-emerald-400/40 shadow-xs">
                  <item.icon className="w-4.5 h-4.5 text-[#A8F13C]" />
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

        {/* Bottom Left Copyright Text */}
        <div className="relative z-10 text-[11px] font-bold text-white/80 flex items-center gap-2 drop-shadow-xs">
          <span>&copy; 2026 Vie-farm AI. All rights reserved.</span>
        </div>
      </div>

      {/* ── 2. RIGHT REGISTER PANEL (Desktop 40%, Laptop 45%, Tablet 100%, Mobile 100%) ── */}
      <div className="flex-1 flex flex-col justify-between items-center p-4 sm:p-6 lg:p-8 min-h-screen overflow-y-auto bg-[#FAFBF8]">
        <div className="w-full flex-1 flex flex-col items-center justify-center my-auto">
          {/* Centered Register Card */}
          <div className="bg-white rounded-[28px] p-6 sm:p-8 shadow-[0_12px_40px_rgba(0,0,0,0.08)] max-w-[440px] w-full border border-[#E8F5E9] space-y-4">
            {/* Circular Leaf Emblem */}
            <div className="flex justify-center">
              <div className="w-12 h-12 rounded-full bg-[#E8F5E9] border border-[#2E7D32]/25 flex items-center justify-center text-[#184D2F] shadow-inner">
                <Sprout className="w-6 h-6 text-[#184D2F]" />
              </div>
            </div>

            {/* Form Title & Subtitle */}
            <div className="text-center space-y-0.5">
              <h2 className="text-2xl font-black text-[#184D2F] tracking-tight">
                Đăng ký tài khoản
              </h2>
              <p className="text-xs text-gray-500 font-medium">
                Nhập thông tin để tạo tài khoản mới.
              </p>
            </div>

            {/* Error / Success Banners */}
            {error && (
              <div className="px-3.5 py-2 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700 font-bold flex items-center gap-2 animate-[shake_0.3s_ease-in-out]">
                <span className="w-1.5 h-1.5 rounded-full bg-rose-600 flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}
            {success && (
              <div className="px-3.5 py-2 rounded-xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 font-bold flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" />
                <span>{success}</span>
              </div>
            )}

            {/* Register Form */}
            <form onSubmit={handleSubmit} className="space-y-3">
              {/* Họ và tên (h-14, bo 16px, bg-[#FAFBF8]) */}
              <div className="space-y-1">
                <label className="block text-xs font-extrabold text-gray-700">Họ và tên</label>
                <div className="relative">
                  <User className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Nguyễn Văn A"
                    className="w-full pl-10 pr-4 h-[52px] text-xs bg-[#FAFBF8] border border-[#2E7D32] rounded-[16px] focus:outline-none focus:ring-2 focus:ring-[#184D2F] font-semibold text-gray-900 placeholder-gray-400 transition-all"
                  />
                </div>
              </div>

              {/* Email (h-14, bo 16px, bg-[#FAFBF8]) */}
              <div className="space-y-1">
                <label className="block text-xs font-extrabold text-gray-700">Email</label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="bao@gmail.com"
                    className="w-full pl-10 pr-4 h-[52px] text-xs bg-[#FAFBF8] border border-gray-200 focus:border-[#2E7D32] rounded-[16px] focus:outline-none focus:ring-2 focus:ring-[#184D2F] font-semibold text-gray-900 placeholder-gray-400 transition-all"
                  />
                </div>
              </div>

              {/* Mật khẩu (h-14, bo 16px, bg-[#FAFBF8]) */}
              <div className="space-y-1">
                <label className="block text-xs font-extrabold text-gray-700">Mật khẩu</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type={showPassword ? "text" : "password"}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full pl-10 pr-10 h-[52px] text-xs bg-[#FAFBF8] border border-gray-200 focus:border-[#2E7D32] rounded-[16px] focus:outline-none focus:ring-2 focus:ring-[#184D2F] font-semibold text-gray-900 placeholder-gray-400 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors cursor-pointer"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>

                {/* Password Strength Indicator */}
                {password.length > 0 && (
                  <div className="pt-1 space-y-1">
                    <div className="w-full h-1.5 bg-gray-200 rounded-full overflow-hidden">
                      <div
                        className={`h-full transition-all duration-300 ${
                          hasLength && hasNumber && hasUpperLower && hasSpecial
                            ? "w-full bg-[#184D2F]"
                            : hasLength && hasNumber
                            ? "w-2/3 bg-amber-500"
                            : "w-1/3 bg-rose-500"
                        }`}
                      />
                    </div>
                    <span className="text-[11px] font-extrabold text-[#184D2F] block">
                      {hasLength && hasNumber && hasUpperLower && hasSpecial
                        ? "Mật khẩu mạnh"
                        : hasLength && hasNumber
                        ? "Mật khẩu trung bình"
                        : "Mật khẩu yếu"}
                    </span>
                  </div>
                )}
              </div>

              {/* Xác nhận mật khẩu (h-14, bo 16px, bg-[#FAFBF8]) */}
              <div className="space-y-1">
                <label className="block text-xs font-extrabold text-gray-700">Xác nhận mật khẩu</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    required
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full pl-10 pr-10 h-[52px] text-xs bg-[#FAFBF8] border border-gray-200 focus:border-[#2E7D32] rounded-[16px] focus:outline-none focus:ring-2 focus:ring-[#184D2F] font-semibold text-gray-900 placeholder-gray-400 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors cursor-pointer"
                  >
                    {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Validation Checklist Badges (2x2 Grid) */}
              <div className="grid grid-cols-2 gap-1.5 pt-1 text-[10px] font-bold text-gray-600">
                <div className={`flex items-center gap-1 ${hasLength ? "text-emerald-700" : "text-gray-400"}`}>
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Ít nhất 8 ký tự</span>
                </div>
                <div className={`flex items-center gap-1 ${hasNumber ? "text-emerald-700" : "text-gray-400"}`}>
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Có số</span>
                </div>
                <div className={`flex items-center gap-1 ${hasUpperLower ? "text-emerald-700" : "text-gray-400"}`}>
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Có chữ hoa và chữ thường</span>
                </div>
                <div className={`flex items-center gap-1 ${hasSpecial ? "text-emerald-700" : "text-gray-400"}`}>
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Có ký tự đặc biệt (!@#$% )</span>
                </div>
              </div>

              {/* Primary Register Button (Height 56px/62px, Radius 18px/Pill, #184D2F) */}
              <button
                type="submit"
                disabled={loading}
                className="w-full h-[56px] rounded-[18px] bg-[#184D2F] hover:bg-[#1B5E20] text-white font-extrabold text-xs shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer active:scale-[0.99] disabled:opacity-50 mt-2"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Đang xử lý đăng ký...</span>
                  </>
                ) : (
                  <span>Đăng ký</span>
                )}
              </button>
            </form>

            {/* Divider with text "hoặc" */}
            <div className="relative my-3">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-100" />
              </div>
              <div className="relative flex justify-center text-xs">
                <span className="bg-white px-3 text-gray-400 font-medium">hoặc</span>
              </div>
            </div>

            {/* Google Register Button (Outlined, Height 62px, Radius 18px) */}
            <button
              type="button"
              onClick={() => alert("Tính năng Đăng ký với Google đang được bảo trì.")}
              className="w-full h-[56px] rounded-[18px] border border-gray-200 bg-white hover:bg-gray-50 text-gray-700 font-bold text-xs flex items-center justify-center gap-2.5 shadow-2xs transition-all cursor-pointer"
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
              <span>Đăng ký với Google</span>
            </button>

            {/* Bottom Login Link: "Đã có tài khoản? Đăng nhập" */}
            <p className="text-center text-xs text-gray-600 font-medium pt-1">
              Đã có tài khoản?{" "}
              <Link to="/login" className="text-[#184D2F] font-extrabold hover:underline">
                Đăng nhập
              </Link>
            </p>
          </div>

          {/* Bottom Center Slogan */}
          <div className="mt-5 text-center text-xs font-bold text-[#184D2F] flex items-center justify-center gap-1.5">
            <span>🍃</span>
            <span>Bảo vệ từng cây – Kiến tạo tương lai xanh</span>
            <span>🌿</span>
          </div>
        </div>
      </div>
    </div>
  );
}
