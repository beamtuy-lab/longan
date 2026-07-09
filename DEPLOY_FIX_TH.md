# วิธีแก้ GitHub Pages Deploy ไม่ผ่าน

จากรูป Build ผ่านแล้ว แต่ Deploy ล้มเหลว แนะนำเปลี่ยน Pages Source เป็น GitHub Actions แล้วใช้ workflow ในชุดไฟล์นี้

## ตั้งค่าใน GitHub

1. เปิด repository
2. ไปที่ Settings > Pages
3. Source เลือก `GitHub Actions`
4. ไปที่ Settings > Actions > General
5. ที่ Workflow permissions เลือก `Read and write permissions`
6. ติ๊ก `Allow GitHub Actions to create and approve pull requests` ไม่จำเป็น แต่เปิดไว้ได้
7. ไปที่ Actions > Deploy GitHub Pages > Run workflow

## โครงสร้างไฟล์ที่ถูกต้อง

```text
index.html
404.html
.nojekyll
README.md
DEPLOY_FIX_TH.md
.github/workflows/deploy-pages.yml
```

## ถ้าใช้ branch main หรือ master

workflow รองรับทั้งสอง branch แล้ว
