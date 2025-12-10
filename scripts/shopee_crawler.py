import time
import json
import random
import undetected_chromedriver as uc
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from firebase_admin import credentials, firestore, initialize_app

# --- 1. Firebase 設定 (把抓到的直接存進去) ---
# 請確認 serviceAccountKey.json 在同目錄
cred = credentials.Certificate("serviceAccountKey.json")
initialize_app(cred)
db = firestore.client()

# --- 2. 爬蟲設定 ---
# 蝦皮 "女生衣著" 類別的熱銷排行 URL
TARGET_URL = "https://shopee.tw/%E9%9F%93%E5%9C%8B%E7%A7%8B%E5%86%AC%E6%96%B0%E5%93%81%E9%80%A3%E7%B7%9A-col.2326762"
SCROLL_PAUSE_TIME = 2  # 捲動等待時間 (秒)
MAX_ITEMS = 50         # 你想抓幾件?

def start_crawling():
    print("🚀 啟動瀏覽器爬蟲...")

    # 設定瀏覽器選項 (模擬真人)
    chrome_options = Options()
    
    # chrome_options.add_argument("--headless") # 開發時建議註解掉這行，看得到瀏覽器動作比較安心
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

    driver = uc.Chrome(options=chrome_options)
    
    try:
        # 先去蝦皮首頁
        driver.get(TARGET_URL)
        print("🔗 已進入蝦皮頁面，開始模擬捲動...")
        
        # --- 3. 瘋狂捲動 (因為蝦皮是 Lazy Load，不捲動抓不到下面的商品) ---
        for i in range(5): # 捲動 5 次通常夠抓 60 件
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(SCROLL_PAUSE_TIME + random.random()) # 隨機等待防被抓
        
        print("👀 頁面載入完成，開始解析商品...")

        # --- 4. 抓取商品元素 ---
        # 這是蝦皮目前的商品卡片 class (可能會變，如果抓不到要檢查網頁原始碼)
        # 通常是用 shopee-search-item-result__item
        items = driver.find_elements(By.CSS_SELECTOR, ".shopee-search-item-result__item")
        
        saved_count = 0
        batch = db.batch() # 使用 Batch 寫入 Firestore

        for item in items:
            if saved_count >= MAX_ITEMS:
                break
                
            try:
                # 解析內部資料
                # 這裡使用相對路徑來抓
                
                # 連結
                link_tag = item.find_element(By.TAG_NAME, "a")
                product_link = link_tag.get_attribute("href")
                
                # 圖片 (蝦皮有時候圖在 img 裡，有時候是 background-image)
                try:
                    img_tag = item.find_element(By.CSS_SELECTOR, "img")
                    image_url = img_tag.get_attribute("src")
                except:
                    image_url = ""

                # 名稱 & 價格
                # 蝦皮的 class 很亂，通常抓結構比較穩
                text_content = item.text.split('\n')
                # text_content 通常包含: 名稱, 價格, 銷售量...
                # 這邊做個簡單處理，實際可能要根據 text_content 內容微調
                
                name = ""
                price = 0
                
                # 嘗試抓取特定元素 (這裡需要根據當下蝦皮的 DOM 結構調整)
                # 假設結構: 圖片區 -> 資訊區
                # 資訊區通常有 truncate 的 class
                name_el = item.find_element(By.CSS_SELECTOR, "div[data-sqe='name']")
                name = name_el.text
                
                price_el = item.find_element(By.CSS_SELECTOR, "div[data-sqe='rating'] + div") # 價格通常在評價後面
                # 或是直接找有 $ 符號的文字
                price_str = item.find_element(By.XPATH, ".//span[text()='$']//following-sibling::span").text
                price = float(price_str.replace(",", "").replace(".", ""))

                # --- 5. 資料清洗與儲存 ---
                if name and image_url and product_link:
                    # 建立資料物件
                    doc_ref = db.collection("products").document()
                    batch.set(doc_ref, {
                        "name": name,
                        "price": price,
                        "imageUrl": image_url,
                        "images": [image_url], # 先塞一張，之後詳情頁再說
                        "description": "熱銷商品推薦", # 爬蟲很難進內頁抓詳情，先用預設
                        "deepLink": product_link, # ★ 這是原始連結，賺不到錢
                        "originalLink": product_link, # 備份起來，以後用來轉分潤
                        "source": "shopee_crawler", # 標記來源，以後方便批次修改
                        "isAffiliated": False, # 標記尚未轉成分潤連結
                        "timestamp": firestore.SERVER_TIMESTAMP
                    })
                    
                    saved_count += 1
                    print(f"✅ 抓到: {name} (${price})")

            except Exception as e:
                # 爬蟲容錯很重要，單一商品失敗不要停
                continue
        
        # 提交 Batch
        batch.commit()
        print(f"🎉 成功爬取並寫入 {saved_count} 筆商品！")

    except Exception as e:
        print(f"❌ 發生錯誤: {e}")
    finally:
        driver.quit()

if __name__ == "__main__":
    start_crawling()