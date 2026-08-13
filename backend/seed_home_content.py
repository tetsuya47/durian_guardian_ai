import asyncio
import logging
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorClient

MONGODB_URL = "mongodb+srv://sanghoanga8_db_user:9390PahlsR5J2d8X@durianguardianai.72acfra.mongodb.net/?appName=DurianGuardianAI"
MONGODB_DB_NAME = "durian_guardian_ai"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed_home_content")

async def seed_data():
    client = AsyncIOMotorClient(MONGODB_URL, tlsAllowInvalidCertificates=True)
    db = client[MONGODB_DB_NAME]
    
    # 1. Durian Orchard Farm-Gate Market Prices (Hàng Đẹp & Hàng Xô Lùa)
    market_prices = [
        # Sầu riêng Ri6
        {
            "name": "Sầu riêng Ri6",
            "variety_id": "ri6",
            "variety_name": "Sầu riêng Ri6",
            "quality": "Hàng đẹp (Loại 1)",
            "grade_type": "dep",
            "price": "65.000 vnđ/kg",
            "price_number": 65000,
            "change": "+1.000",
            "trend": "up",
            "region": "ĐBSCL / Tây Nguyên",
            "description": "Cơm vàng hạt lép, vỏ mỏng, trái đều hộc",
            "icon": "ri6"
        },
        {
            "name": "Sầu riêng Ri6",
            "variety_id": "ri6",
            "variety_name": "Sầu riêng Ri6",
            "quality": "Hàng xô lùa (Xô vườn)",
            "grade_type": "xo_lua",
            "price": "45.000 vnđ/kg",
            "price_number": 45000,
            "change": "0",
            "trend": "stable",
            "region": "ĐBSCL (Tiền Giang, Bến Tre)",
            "description": "Thu mua xô nguyên vườn cắt lứa",
            "icon": "ri6"
        },

        # Sầu riêng Monthong (Thái)
        {
            "name": "Sầu riêng Monthong (Thái A)",
            "variety_id": "monthong",
            "variety_name": "Sầu riêng Monthong",
            "quality": "Hàng đẹp (Xuất khẩu)",
            "grade_type": "dep",
            "price": "95.000 vnđ/kg",
            "price_number": 95000,
            "change": "+2.000",
            "trend": "up",
            "region": "Tây Nguyên (Đắk Lắk, Lâm Đồng)",
            "description": "Trái to đều hộc, cơm dày béo ngọt chuẩn GACC",
            "icon": "monthong"
        },
        {
            "name": "Sầu riêng Monthong (Thái)",
            "variety_id": "monthong",
            "variety_name": "Sầu riêng Monthong",
            "quality": "Hàng xô lùa (Xô vườn)",
            "grade_type": "xo_lua",
            "price": "68.000 vnđ/kg",
            "price_number": 68000,
            "change": "-500",
            "trend": "down",
            "region": "Tây Nguyên / Đông Nam Bộ",
            "description": "Xô vườn cắt lùa bình dân",
            "icon": "monthong"
        },

        # Sầu riêng Musang King
        {
            "name": "Sầu riêng Musang King",
            "variety_id": "musang_king",
            "variety_name": "Sầu riêng Musang King",
            "quality": "Hàng đẹp (VIP Xuất khẩu)",
            "grade_type": "dep",
            "price": "160.000 vnđ/kg",
            "price_number": 160000,
            "change": "+5.000",
            "trend": "up",
            "region": "Lâm Đồng / Đắk Lắk",
            "description": "Cơm vàng đậm dẻo mịn, đáy trái hình sao 5 cánh",
            "icon": "musang_king"
        },
        {
            "name": "Sầu riêng Musang King",
            "variety_id": "musang_king",
            "variety_name": "Sầu riêng Musang King",
            "quality": "Hàng xô lùa (Xô vườn)",
            "grade_type": "xo_lua",
            "price": "110.000 vnđ/kg",
            "price_number": 110000,
            "change": "0",
            "trend": "stable",
            "region": "Tây Nguyên",
            "description": "Xô lùa nguyên vườn trái nhỏ",
            "icon": "musang_king"
        },

        # Sầu riêng Chuồng Bò
        {
            "name": "Sầu riêng Chuồng Bò",
            "variety_id": "chuong_bo",
            "variety_name": "Sầu riêng Chuồng Bò",
            "quality": "Hàng đẹp (Loại 1)",
            "grade_type": "dep",
            "price": "70.000 vnđ/kg",
            "price_number": 70000,
            "change": "+1.000",
            "trend": "up",
            "region": "ĐBSCL (Bến Tre, Tiền Giang)",
            "description": "Đặc sản truyền thống cơm béo ngậy tự nhiên",
            "icon": "chuong_bo"
        },
        {
            "name": "Sầu riêng Chuồng Bò",
            "variety_id": "chuong_bo",
            "variety_name": "Sầu riêng Chuồng Bò",
            "quality": "Hàng xô lùa (Xô vườn)",
            "grade_type": "xo_lua",
            "price": "48.000 vnđ/kg",
            "price_number": 48000,
            "change": "0",
            "trend": "stable",
            "region": "ĐBSCL",
            "description": "Thu mua xô tại vườn",
            "icon": "chuong_bo"
        },

        # Sầu riêng Black Thorn (Gai Đen / Sáu Hữu)
        {
            "name": "Sầu riêng Black Thorn (Gai Đen)",
            "variety_id": "black_thorn",
            "variety_name": "Sầu riêng Black Thorn",
            "quality": "Hàng đẹp (Thượng hạng)",
            "grade_type": "dep",
            "price": "180.000 vnđ/kg",
            "price_number": 180000,
            "change": "+3.000",
            "trend": "up",
            "region": "ĐBSCL / Tây Nguyên",
            "description": "Cơm đỏ cam, vị ngọt dịu đậm đà thơm quyến rũ",
            "icon": "black_thorn"
        },
        {
            "name": "Sầu riêng Black Thorn (Gai Đen)",
            "variety_id": "black_thorn",
            "variety_name": "Sầu riêng Black Thorn",
            "quality": "Hàng xô lùa (Xô vườn)",
            "grade_type": "xo_lua",
            "price": "125.000 vnđ/kg",
            "price_number": 125000,
            "change": "0",
            "trend": "stable",
            "region": "ĐBSCL",
            "description": "Xô vườn trái lệch hộc",
            "icon": "black_thorn"
        }
    ]
    
    await db["durian_market_prices"].delete_many({})
    await db["durian_market_prices"].insert_many([{
        **p,
        "scraped_at": datetime.now(timezone.utc)
    } for p in market_prices])
    logger.info("Seeded %d market price items", len(market_prices))

    # 2. News Articles (Điểm tin sầu riêng các vùng miền)
    news_articles = [
        {
            "title": "Sầu riêng Đắk Lắk vào vụ thu hoạch chính: Giá thu mua Monthong đạt 95.000đ/kg",
            "summary": "Tại Krông Pắk và Cư M'gar (Đắk Lắk), không khí thu hoạch sầu riêng đang vô cùng nhộn nhịp với mức giá cao kỷ kỷ lục.",
            "content": "Theo Sở Nông nghiệp và PTNT Đắk Lắk, toàn tỉnh hiện có trên 32.000 ha sầu riêng. Vụ thu hoạch năm 2026 ghi nhận năng suất vượt trội, thương lái và doanh nghiệp xuất khẩu thu mua xô tại vườn từ 85.000 - 95.000đ/kg đối với sầu riêng Monthong loại 1...",
            "image_url": "assets/images/durian_news_daklak.png",
            "category": "Thị trường",
            "region": "Tây Nguyên (Đắk Lắk)",
            "source": "Báo Nông Nghiệp VN",
            "is_featured": True,
            "created_at": datetime.now(timezone.utc)
        },
        {
            "title": "Xuất khẩu sầu riêng sang Trung Quốc tăng trưởng mạnh: GACC cấp thêm 120 mã số vùng trồng",
            "summary": "Tổng cục Hải quan Trung Quốc (GACC) vừa phê duyệt thêm 120 mã số vùng trồng và 45 cơ sở đóng gói sầu riêng cho Việt Nam.",
            "content": "Cục Bảo vệ Thực vật cho biết, việc tuân thủ nghiêm ngặt quy trình kiểm dịch thực vật và giám sát mã số vùng trồng giúp kim ngạch xuất khẩu sầu riêng Việt Nam tiếp tục duy trì vị thế dẫn đầu tại thị trường tỷ dân...",
            "image_url": "assets/images/durian_news_export.png",
            "category": "Xuất khẩu",
            "region": "Toàn quốc / Xuất khẩu",
            "source": "Cục Bảo vệ thực vật",
            "is_featured": True,
            "created_at": datetime.now(timezone.utc)
        },
        {
            "title": "Tiền Giang: Nông dân trúng lớn vụ sầu riêng nghịch vụ Ri6 nhờ kỹ thuật tưới tiết kiệm",
            "summary": "Nhà vườn tại huyện Cai Lậy và Cái Bè (Tiền Giang) bội thu sầu riêng nghịch vụ với giá bán tại vườn 120.000đ/kg.",
            "content": "Nhờ áp dụng công nghệ tưới nhỏ giọt tự động kết hợp xử lý xiết nước tạo mầm hoa sớm, các vườn sầu riêng Ri6 tại Tiền Giang đạt tỷ lệ đậu trái trên 85%, hạn chế tối đa hiện tượng rụng trái non và sượng cơm...",
            "image_url": "assets/images/durian_news_tech.png",
            "category": "Kỹ thuật",
            "region": "ĐBSCL (Tiền Giang)",
            "source": "Sở NN&PTNT Tiền Giang",
            "is_featured": True,
            "created_at": datetime.now(timezone.utc)
        },
        {
            "title": "Bến Tre: Thành công từ mô hình trồng sầu riêng hữu cơ xuất khẩu sang Nhật Bản & EU",
            "summary": "Hợp tác xã Chợ Lách liên kết với 50 hộ nông dân canh tác sầu riêng không hóa chất độc hại, đạt chứng nhận quốc tế.",
            "content": "Mô hình sử dụng 100% phân bón vi sinh hữu cơ và nấm đối kháng sinh học giúp cây sầu riêng nâng cao tuổi thọ, cơm vàng óng, độ ngọt tự nhiên và đáp ứng các tiêu chuẩn khắt khe nhất của thị trường khó tính...",
            "image_url": "assets/images/durian_news_organic.png",
            "category": "Mô hình hay",
            "region": "ĐBSCL (Bến Tre)",
            "source": "Báo Nông thôn ngày nay",
            "is_featured": False,
            "created_at": datetime.now(timezone.utc)
        }
    ]

    await db["news"].delete_many({})
    await db["news"].insert_many(news_articles)
    logger.info("Seeded %d news articles", len(news_articles))

    # 3. Videos
    videos = [
        {
            "title": "NỮ HOÀNG SƠN CƯỚC TRÊN NÓC NHÀ ĐÔNG DƯƠNG",
            "view_count": 123,
            "thumbnail_url": "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=400&q=80",
            "video_url": "https://www.w3schools.com/html/mov_bbb.mp4",
            "duration": "01:45",
            "created_at": datetime.now(timezone.utc)
        },
        {
            "title": "LOÀI CÂY MỌC HOÀNG NGOÀI RỪNG NAY ĐƯỢC GIỚI NHÀ GIÀU ƯA CHUỘNG",
            "view_count": 90,
            "thumbnail_url": "https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=400&q=80",
            "video_url": "https://www.w3schools.com/html/mov_bbb.mp4",
            "duration": "02:10",
            "created_at": datetime.now(timezone.utc)
        }
    ]

    await db["videos"].delete_many({})
    await db["videos"].insert_many(videos)
    logger.info("Seeded %d videos", len(videos))

    client.close()
    logger.info("Seeding completed successfully!")

if __name__ == "__main__":
    asyncio.run(seed_data())
