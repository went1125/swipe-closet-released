// functions/index.js

const { onRequest } = require("firebase-functions/v2/https"); // ★ 改用 V2
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

if (!admin.apps.length) {
  admin.initializeApp();
}

// ★ 定義 Secret
const affiliateApiKey = defineSecret("AFFILIATE_API_KEY");

// ★ 設定區
const API_BASE_URL = "https://api.pub.affiliates.one/api/v2/affiliates/products.json";
const TARGET_OFFER_ID = "4139"; // 蝦皮商城

// ★ V2 語法：直接在 onRequest 的第一個參數設定 secrets
exports.syncAffiliateProducts = onRequest(
  { 
    secrets: [affiliateApiKey],
    timeoutSeconds: 60, // 避免執行太久被切斷
    region: "us-central1" // 或你指定的區域
  },
  async (req, res) => {
    try {
      console.log(`🚀 開始同步 Offer ID: ${TARGET_OFFER_ID} 的商品...`);

      // ★ 取出 Secret 的值
      const apiKey = affiliateApiKey.value();

      // 1. 呼叫聯盟網 API
      const response = await axios.get(API_BASE_URL, {
        params: {
          api_key: apiKey,
          offer_id: TARGET_OFFER_ID,
          locale: "zh-TW",
          currency: "TWD",
          per_page: 50,
          page: req.query.page || 1,
        }
      });

      const products = response.data.data;
      
      if (!products || !Array.isArray(products) || products.length === 0) {
        return res.json({ 
          success: false, 
          message: "找不到商品或 API 回傳空值",
          debug: response.data 
        });
      }

      const batch = admin.firestore().batch();
      const collectionRef = admin.firestore().collection("products");
      let count = 0;

      // 2. 資料清洗
      for (const item of products) {
        const docId = item.universal_id_value || (item.id ? item.id.toString() : admin.firestore().collection("products").doc().id);
        const docRef = collectionRef.doc(docId);

        let price = 0;
        if (item.prices) {
          if (item.prices.sale && item.prices.sale.TWD) {
            price = item.prices.sale.TWD;
          } else if (item.prices.retail && item.prices.retail.TWD) {
            price = item.prices.retail.TWD;
          }
        } else if (item.price_min) {
          price = item.price_min;
        }

        let images = [];
        if (Array.isArray(item.images) && item.images.length > 0) {
          images = item.images.map(img => (typeof img === 'object' ? img.url : img)).filter(url => url);
        } else if (item.image_url) {
          images = [item.image_url];
        }
        
        if (images.length === 0) continue;

        const categories = [];
        if (item.category_1) categories.push(item.category_1);
        if (item.category_2) categories.push(item.category_2);

        const productData = {
          id: docId,
          name: item.title,
          price: parseFloat(price),
          images: images,
          imageUrl: images[0],
          description: item.description_1 || "精選商品",
          deepLink: item.tracking_url,
          categories: categories,
          platform: "affiliates_one",
          offerId: TARGET_OFFER_ID,
          isAvailable: true,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        };

        batch.set(docRef, productData, { merge: true });
        count++;
      }

      if (count > 0) {
        await batch.commit();
      }
      
      console.log(`✅ 成功同步 ${count} 筆商品`);
      res.json({ success: true, count: count, message: "同步完成 (V2)" });

    } catch (error) {
      console.error("API Error:", error.message);
      res.status(500).json({ success: false, error: error.message });
    }
  }
);