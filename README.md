# TK Longan Cash Bill - Supabase Direct Ready

ไฟล์ชุดนี้ตั้งค่าให้ใช้ Supabase 100% แล้ว ไม่ใช้ Google Apps Script

## Supabase Project
- Project: beamtuy-lab's Project
- SUPABASE_URL: https://hpdedxdjjwhmejydaolo.supabase.co
- SUPABASE_DIRECT_ENDPOINT: https://hpdedxdjjwhmejydaolo.supabase.co/functions/v1/longan-api
- Edge Function: longan-api
- Database RPC: longan_*

## วิธีใช้งาน
1. ใช้ไฟล์ `index_SUPABASE_DIRECT_READY.html` เป็นไฟล์หลักของระบบ
2. อัปโหลดไฟล์นี้ไปที่ Hosting ของมหาวิทยาลัย / Netlify / Vercel / Cloudflare Pages / Static Hosting อื่น ๆ
3. ไม่ต้องใช้ `Code.gs` หรือ Google Apps Script อีกต่อไป
4. เปิดเว็บแล้วกด F12 > Console ควรเห็นข้อความเชื่อมต่อ Supabase
5. เมื่อกดบันทึกบิล ข้อมูลจะถูกส่งไปยัง `longan-api` แล้วบันทึกลงตาราง `longan_cash_bills`

## การตรวจสอบ Network
เมื่อกดบันทึก ให้เห็น request ไปที่:

```text
https://hpdedxdjjwhmejydaolo.supabase.co/functions/v1/longan-api
```

## ตารางหลัก
- `longan_cash_bills` สำหรับบิลเงินสด
- `longan_delivery_bills` สำหรับใบส่งของ

## Admin
รหัสเริ่มต้นที่ตั้งไว้ในฐานข้อมูลคือ `3304` ควรเปลี่ยนหลังเริ่มใช้งานครั้งแรก
