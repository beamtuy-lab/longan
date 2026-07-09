# TK Longan Cashbill - GitHub Pages + Supabase

ระบบบิลเงินสดลำไยแบบ Static HTML เชื่อม Supabase โดยตรงผ่าน Edge Function `longan-api`

## วิธี Deploy

1. อัปโหลดไฟล์ทั้งหมดในโฟลเดอร์นี้ขึ้น GitHub repository
2. ไปที่ Settings > Pages
3. เลือก Source: GitHub Actions
4. ไปที่ Actions แล้วรัน workflow ชื่อ Deploy GitHub Pages หรือ push ขึ้น branch main/master

## ต้องมีไฟล์สำคัญ

- `index.html` อยู่ที่ root ของ repository
- `.nojekyll`
- `.github/workflows/deploy-pages.yml`

## Supabase Endpoint

ระบบตั้งค่าไว้แล้วที่:

`https://hpdedxdjjwhmejydaolo.supabase.co/functions/v1/longan-api`
