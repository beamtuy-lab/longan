# วิธี Deploy ระบบ TK Longan Supabase บน GitHub Pages

## โครงสร้างไฟล์ที่ต้องอยู่หน้าแรกของ Repository

```text
index.html
.nojekyll
README.md
supabase_schema.sql
```

ไฟล์สำคัญที่สุดคือ `index.html` ต้องอยู่ที่ root ของ repository เท่านั้น ห้ามใช้ชื่อ `index_SUPABASE_DIRECT_READY.html` เพราะ GitHub Pages จะไม่ใช้เป็นหน้าแรกโดยอัตโนมัติ

## ตั้งค่า GitHub Pages

1. เข้า Repository บน GitHub
2. ไปที่ Settings > Pages
3. Source เลือก Deploy from a branch
4. Branch เลือก `main` และ Folder เลือก `/ (root)`
5. กด Save

รอระบบ Deploy แล้วเปิด URL ที่ GitHub Pages สร้างให้

## ตรวจสอบการเชื่อมต่อ

เปิดหน้าเว็บ แล้วกด F12 > Console ควรเห็นระบบเชื่อมต่อ Supabase และเมื่อกดบันทึกบิล Network ควรมี request ไปที่:

```text
https://hpdedxdjjwhmejydaolo.supabase.co/functions/v1/longan-api
```

