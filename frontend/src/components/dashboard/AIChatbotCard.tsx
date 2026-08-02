import { useState, useRef, useEffect } from "react";
import { Bot, Send, User, Sparkles, RefreshCw } from "lucide-react";
import Card from "./Shared/Card";
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
    text: "Xin chào! Tôi là Trợ lý AI Chuyên gia Sầu Riêng. Bạn cần tư vấn về kỹ thuật bón phân, xử lý xì mủ gốc hay phòng trừ bệnh hại nào hôm nay?",
    timestamp: new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" }),
  },
];

export default function AIChatbotCard() {
  const [messages, setMessages] = useState<Message[]>(INITIAL_MESSAGES);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, loading]);

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
    <Card className="flex flex-col h-full overflow-hidden" padding={false} hover={false}>
      <div className="flex flex-col h-full p-3.5 justify-between">
        {/* Top Header */}
        <div className="flex items-center justify-between pb-2 border-b border-gray-100 flex-shrink-0">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-[10px] bg-emerald-100 flex items-center justify-center flex-shrink-0">
              <Bot className="w-4.5 h-4.5 text-emerald-700" />
            </div>
            <div>
              <h3 className="text-[14px] font-bold text-gray-900 leading-none flex items-center gap-1">
                🤖 CHATBOT TRỢ LÝ AI
                <Sparkles className="w-3.5 h-3.5 text-amber-500 fill-amber-400" />
              </h3>
              <p className="text-[10px] text-gray-500 font-medium leading-tight mt-0.5">Tư vấn kỹ thuật sầu riêng 24/7</p>
            </div>
          </div>

          <button
            onClick={handleReset}
            className="p-1.5 text-gray-400 hover:text-emerald-700 hover:bg-emerald-50 rounded-[8px] transition-all"
            title="Làm mới cuộc trò chuyện"
            type="button"
          >
            <RefreshCw className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Middle Message List */}
        <div className="flex-1 overflow-y-auto py-2 space-y-2.5 min-h-0 pr-1">
          {messages.map((msg) => {
            const isAI = msg.sender === "ai";
            return (
              <div key={msg.id} className={`flex gap-2 ${isAI ? "items-start" : "items-end justify-end"}`}>
                {isAI && (
                  <div className="w-6 h-6 rounded-full bg-emerald-600 flex items-center justify-center text-white flex-shrink-0 mt-0.5 shadow-sm">
                    <Bot className="w-3.5 h-3.5" />
                  </div>
                )}
                <div
                  className={`max-w-[85%] p-2.5 rounded-[14px] text-[12px] leading-relaxed shadow-sm ${
                    isAI
                      ? "bg-gray-50 text-gray-800 border border-gray-100 rounded-tl-none font-medium"
                      : "bg-emerald-600 text-white rounded-tr-none font-semibold"
                  }`}
                >
                  <p className="whitespace-pre-line">{msg.text}</p>
                  <span className={`text-[9px] block text-right mt-1 ${isAI ? "text-gray-400" : "text-emerald-100"}`}>
                    {msg.timestamp}
                  </span>
                </div>
                {!isAI && (
                  <div className="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center text-gray-600 flex-shrink-0">
                    <User className="w-3.5 h-3.5" />
                  </div>
                )}
              </div>
            );
          })}

          {loading && (
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 rounded-full bg-emerald-600 flex items-center justify-center text-white flex-shrink-0">
                <Bot className="w-3.5 h-3.5" />
              </div>
              <div className="bg-gray-50 p-2.5 rounded-[14px] rounded-tl-none border border-gray-100 text-[11px] text-gray-500 font-medium flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse delay-150" />
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse delay-300" />
                <span>AI đang suy nghĩ...</span>
              </div>
            </div>
          )}
          <div ref={chatEndRef} />
        </div>

        {/* Bottom Quick Suggestions & Input */}
        <div className="flex-shrink-0 pt-1.5 border-t border-gray-100">
          {/* Quick Suggestions */}
          <div className="flex items-center gap-1.5 mb-2 overflow-x-auto pb-1">
            {QUICK_SUGGESTIONS.map((sug) => (
              <button
                key={sug}
                onClick={() => handleSend(sug)}
                type="button"
                className="text-[10px] font-semibold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200/60 px-2 py-0.5 rounded-full whitespace-nowrap transition-colors"
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
            className="flex items-center gap-1.5"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Nhập câu hỏi cho AI..."
              className="flex-1 text-[12px] bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-1.5 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition-all"
            />
            <button
              type="submit"
              disabled={!input.trim() || loading}
              className="w-8 h-8 rounded-[10px] bg-emerald-600 hover:bg-emerald-700 disabled:opacity-40 text-white flex items-center justify-center flex-shrink-0 transition-all shadow-sm"
              title="Gửi câu hỏi"
            >
              <Send className="w-3.5 h-3.5" />
            </button>
          </form>
        </div>
      </div>
    </Card>
  );
}
