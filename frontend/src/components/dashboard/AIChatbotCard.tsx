import { useState, useRef, useEffect } from "react";
import { Bot, Send, User, Sparkles, RefreshCw, X, MessageSquare, ChevronDown } from "lucide-react";
import api from "../../api";

interface Message {
  id: string;
  sender: "ai" | "user";
  text: string;
  timestamp: string;
}

const QUICK_SUGGESTIONS = [
  "Xử lý xì mủ gốc?",
  "Lịch bón phân NPK?",
  "Phòng thán thư lá?",
];

const INITIAL_MESSAGES: Message[] = [
  {
    id: "init-1",
    sender: "ai",
    text: "Xin chào! Tôi là Trợ lý AI Chuyên gia Sầu Riêng 24/7. Bạn cần tư vấn về kỹ thuật bón phân, xử lý xì mủ gốc hay phòng trừ bệnh hại nào hôm nay?",
    timestamp: new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" }),
  },
];

export default function AIChatbotCard() {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>(INITIAL_MESSAGES);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [unreadCount, setUnreadCount] = useState(1);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    if (isOpen) {
      setUnreadCount(0);
      scrollToBottom();
    }
  }, [isOpen, messages, loading]);

  const handleSend = async (textToSend?: string) => {
    const query = (textToSend || input).trim();
    if (!query || loading) return;

    const userMsg: Message = {
      id: `usr-${Date.now()}`,
      sender: "user",
      text: query,
      timestamp: new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" }),
    };

    setMessages((prev) => [...prev, userMsg]);
    if (!textToSend) setInput("");
    setLoading(true);

    try {
      const res = await api.post<{ data: { answer: string } }>("/api/v1/chat", { question: query });
      const aiAnswer = res.data.data?.answer || "Tôi đã ghi nhận thông tin. Bạn có muốn kiểm tra thêm khu vực nào không?";

      setMessages((prev) => [
        ...prev,
        {
          id: `ai-${Date.now()}`,
          sender: "ai",
          text: aiAnswer,
          timestamp: new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" }),
        },
      ]);
    } catch {
      // Smart Fallback Response based on keywords
      let fallback = "Dựa trên dữ liệu kỹ thuật sầu riêng: Để phòng trị bệnh hiệu quả, bạn nên giữ gốc cây khô ráo, tỉa cành thông thoáng và bôi thuốc gốc Đồng/Metalaxyl khi phát hiện vết xì mủ.";
      if (query.toLowerCase().includes("xì mủ") || query.toLowerCase().includes("thối gốc")) {
        fallback = "Về xì mủ gốc (Phytophthora): Cần cạo sạch vỏ bị bệnh, bôi dung dịch Boóc-đô 10% hoặc Ridomil Gold, kết hợp tưới gốc Phosphonate phòng ngừa lây lan.";
      } else if (query.toLowerCase().includes("bón phân") || query.toLowerCase().includes("npk")) {
        fallback = "Về lịch bón phân: Giai đoạn nuôi quả nên ưu tiên NPK tỷ lệ K cao (như 15-15-15 hoặc 12-11-18), bổ sung Canxi-Bo để hạn chế nứt trái và cháy múi.";
      } else if (query.toLowerCase().includes("thán thư")) {
        fallback = "Về bệnh Thán thư lá: Phun phòng ngừa định kỳ bằng Antracol 70WP hoặc Anvil 5SC khi cây vừa nhú đọt non, nhất là vào mùa mưa ẩm.";
      }

      setMessages((prev) => [
        ...prev,
        {
          id: `ai-${Date.now()}`,
          sender: "ai",
          text: fallback,
          timestamp: new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" }),
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setMessages(INITIAL_MESSAGES);
    setInput("");
  };

  return (
    <>
      {/* FLOATING CHAT BUBBLE BUTTON IN BOTTOM RIGHT CORNER */}
      <div className="fixed bottom-6 right-6 z-50 flex items-center">
        {!isOpen && (
          <button
            onClick={() => setIsOpen(true)}
            className="group relative flex items-center gap-2.5 bg-gradient-to-r from-emerald-600 via-emerald-700 to-teal-800 text-white p-3.5 sm:px-5 sm:py-3.5 rounded-full shadow-2xl hover:shadow-emerald-950/40 hover:scale-105 active:scale-95 transition-all cursor-pointer border border-emerald-400/40"
          >
            <div className="relative">
              <Bot className="w-6 h-6 text-emerald-100 group-hover:rotate-12 transition-transform" />
              <span className="absolute -top-1 -right-1 w-3 h-3 rounded-full bg-emerald-400 border-2 border-emerald-900 animate-ping" />
              <span className="absolute -top-1 -right-1 w-3 h-3 rounded-full bg-emerald-400 border-2 border-emerald-900" />
            </div>

            <span className="hidden sm:inline text-xs font-black tracking-wide">TRỢ LÝ AI SẦU RIÊNG</span>

            {unreadCount > 0 && (
              <span className="absolute -top-2 -right-1.5 bg-red-500 text-white text-[10px] font-black w-5 h-5 rounded-full flex items-center justify-center border-2 border-white shadow-md">
                {unreadCount}
              </span>
            )}
          </button>
        )}
      </div>

      {/* POPUP CHAT WINDOW DRAWER */}
      {isOpen && (
        <div className="fixed bottom-6 right-6 z-50 w-96 max-w-[calc(100vw-2rem)] h-[540px] max-h-[85vh] bg-white rounded-[24px] shadow-2xl border border-gray-200/90 flex flex-col overflow-hidden animate-slide-up">
          {/* Top Premium Gradient Header */}
          <div className="bg-gradient-to-r from-emerald-900 via-emerald-800 to-teal-950 text-white p-4 flex items-center justify-between shadow-md flex-shrink-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-[14px] bg-emerald-500/20 border border-emerald-400/30 flex items-center justify-center text-emerald-300">
                <Bot className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-black tracking-tight flex items-center gap-1.5">
                  Chatbot Trợ Lý AI
                  <Sparkles className="w-3.5 h-3.5 text-amber-400 fill-amber-400" />
                </h3>
                <p className="text-[11px] text-emerald-200/80 font-medium">Tư vấn kỹ thuật sầu riêng 24/7</p>
              </div>
            </div>

            <div className="flex items-center gap-1">
              <button
                onClick={handleReset}
                className="p-1.5 text-emerald-200 hover:text-white hover:bg-white/10 rounded-[8px] transition-all cursor-pointer"
                title="Làm mới cuộc trò chuyện"
                type="button"
              >
                <RefreshCw className="w-4 h-4" />
              </button>
              <button
                onClick={() => setIsOpen(false)}
                className="p-1.5 text-emerald-200 hover:text-white hover:bg-white/10 rounded-[8px] transition-all cursor-pointer"
                title="Thu gọn"
                type="button"
              >
                <ChevronDown className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Middle Message History */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50/50">
            {messages.map((msg) => {
              const isAI = msg.sender === "ai";
              return (
                <div key={msg.id} className={`flex gap-2 ${isAI ? "items-start" : "items-end justify-end"}`}>
                  {isAI && (
                    <div className="w-7 h-7 rounded-full bg-emerald-700 flex items-center justify-center text-white flex-shrink-0 mt-0.5 shadow-sm">
                      <Bot className="w-4 h-4" />
                    </div>
                  )}
                  <div
                    className={`max-w-[85%] p-3 rounded-[16px] text-xs leading-relaxed shadow-xs ${
                      isAI
                        ? "bg-white text-gray-800 border border-gray-200/80 rounded-tl-none font-medium"
                        : "bg-emerald-600 text-white rounded-tr-none font-semibold"
                    }`}
                  >
                    <p className="whitespace-pre-line">{msg.text}</p>
                    <span className={`text-[9px] block text-right mt-1 font-bold ${isAI ? "text-gray-400" : "text-emerald-100"}`}>
                      {msg.timestamp}
                    </span>
                  </div>
                  {!isAI && (
                    <div className="w-7 h-7 rounded-full bg-gray-200 flex items-center justify-center text-gray-700 flex-shrink-0">
                      <User className="w-4 h-4" />
                    </div>
                  )}
                </div>
              );
            })}

            {loading && (
              <div className="flex items-center gap-2">
                <div className="w-7 h-7 rounded-full bg-emerald-700 flex items-center justify-center text-white flex-shrink-0">
                  <Bot className="w-4 h-4" />
                </div>
                <div className="bg-white p-3 rounded-[16px] rounded-tl-none border border-gray-200 text-xs text-gray-500 font-medium flex items-center gap-1.5 shadow-xs">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse delay-150" />
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse delay-300" />
                  <span>AI Chuyên gia đang suy nghĩ...</span>
                </div>
              </div>
            )}
            <div ref={chatEndRef} />
          </div>

          {/* Bottom Quick Suggestions & Form */}
          <div className="p-3 bg-white border-t border-gray-100 space-y-2 flex-shrink-0">
            {/* Quick Prompt Pills */}
            <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5 no-scrollbar">
              {QUICK_SUGGESTIONS.map((sug) => (
                <button
                  key={sug}
                  onClick={() => handleSend(sug)}
                  type="button"
                  className="text-[10px] font-bold text-emerald-800 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200/80 px-2.5 py-1 rounded-full whitespace-nowrap transition-all cursor-pointer"
                >
                  {sug}
                </button>
              ))}
            </div>

            {/* Form Input */}
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleSend();
              }}
              className="flex items-center gap-2"
            >
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Nhập câu hỏi cho AI Chuyên gia..."
                className="flex-1 text-xs bg-gray-50 border border-gray-200 rounded-[12px] px-3.5 py-2 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition-all font-medium"
              />
              <button
                type="submit"
                disabled={!input.trim() || loading}
                className="w-9 h-9 rounded-[12px] bg-emerald-600 hover:bg-emerald-700 disabled:opacity-40 text-white flex items-center justify-center flex-shrink-0 transition-all shadow-md cursor-pointer"
                title="Gửi câu hỏi"
              >
                <Send className="w-4 h-4" />
              </button>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
