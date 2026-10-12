# การออกแบบ Architecture และ CI/CD Pipeline

เอกสาร No.2 อธิบายแนวทางออกแบบระบบ Web Application บน AWS และกระบวนการ
นำ code จากการพัฒนาไป deploy ให้ผู้ใช้ โดยแบ่งเป็น 2 ส่วนที่ทำงานสอดคล้องกัน:
Architecture กำหนดส่วนประกอบและเส้นทางการเชื่อมต่อของระบบ ส่วน CI/CD Pipeline
กำหนดขั้นตอนตรวจสอบและส่งมอบ code ในแต่ละ environment

## 1. Architecture

ระบบใช้ VPC เป็นเครือข่ายส่วนตัวสำหรับ service บน AWS โดยมีองค์ประกอบหลักดังนี้:

- **CloudFront** เป็นจุดรับ traffic จากผู้ใช้ และใช้กำหนดการเข้าถึง เช่น บังคับ HTTPS
  หรือจำกัด IP ตามนโยบายขององค์กร
- **Web application และ API บน ECS** ทำงานในรูปแบบ container โดย Web application
  ให้บริการผู้ใช้ ส่วน API รับคำขอและติดต่อกับฐานข้อมูล
- **RDS** เก็บข้อมูลหลักของระบบ และเปิดให้ service ที่ได้รับอนุญาตเชื่อมต่อเท่านั้น
- **Airflow บน EC2** ใช้ตั้งเวลาและควบคุมการทำงานของ data pipeline
- **On-premise และทีมพัฒนา** เชื่อมต่อระบบภายในผ่าน VPN หรือ private endpoint
  ตามสิทธิ์ที่กำหนด เพื่อไม่ให้การเข้าถึงข้อมูลภายในเปิดสู่ public internet

การแบ่งเครือข่ายและกำหนด Security Group ช่วยควบคุมว่า service ใดติดต่อกันได้
ผ่าน IP และ port ใด ส่วน ECS เหมาะกับการ deploy และ scale application แบบ
container ขณะที่ EC2 สำหรับ Airflow เปิดให้ติดตั้งและปรับแต่ง component ได้ยืดหยุ่น

ดูรายละเอียดและภาพประกอบได้ที่ [architecture.md](./architecture.md)

## 2. CI/CD Pipeline

Pipeline ใช้ GitHub Actions ทำงานเมื่อมีการ push code หรือส่ง Pull Request
โดยแบ่งการส่งมอบเป็น Dev, Staging และ Prod เพื่อให้ตรวจพบปัญหาก่อนถึงผู้ใช้:

1. **Dev:** push code ไป branch `develop` แล้วตรวจ security และ dependency,
   รัน automated test และ smoke test, สร้าง image และ deploy ให้ทีมพัฒนาทดสอบ
2. **Staging:** เมื่อการทดสอบและ code review ผ่าน ให้ตรวจ security เพิ่ม
   และ deploy ไปทดสอบ load, stress และ performance
3. **Prod:** เมื่อได้รับอนุมัติจากผู้เกี่ยวข้องและตรวจ config แล้ว จึงระบุ version,
   สร้างหรือ promote image และ deploy ขึ้นระบบจริง พร้อม smoke test หลัง deploy

หากขั้นตอนใดไม่ผ่าน ให้ส่งผลตรวจกลับไปแก้ไขก่อนดำเนินการต่อ การแยก environment
และมีจุดอนุมัติช่วยลดความเสี่ยงที่ code หรือ config ที่ยังไม่พร้อมจะขึ้น Production

ดูรายละเอียดแต่ละขั้นตอนได้ที่ [pipeline.md](./pipeline.md)
