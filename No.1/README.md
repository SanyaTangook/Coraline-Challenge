# No.1 — AWS VPC, PostgreSQL RDS และ Metabase

Terraform ในโฟลเดอร์ `terraform/` สร้างระบบสำหรับใช้งาน Metabase บน AWS โดยให้ PostgreSQL RDS เป็นฐานข้อมูลภายใน VPC และให้ผู้ใช้เปิดหน้า Metabase จากภายนอกได้ผ่าน EC2

## โครงสร้างระบบ

```text
Internet
    |
    | TCP 3000 (อนุญาตเฉพาะ metabase_allowed_cidrs)
    v
EC2: Amazon Linux 2023 + Docker + Metabase
    |  private connection, TCP 5432
    v
RDS PostgreSQL (private only)
```

VPC มี public subnet หนึ่งชุดสำหรับ EC2 และ private database subnets สองชุดในคนละ Availability Zone สำหรับ RDS DB subnet group ตามข้อกำหนดของ AWS

## Resources ที่สร้าง

- VPC, Internet Gateway และ route table สำหรับเครือข่ายหลักและอินเทอร์เน็ตของ EC2
- Public subnet 1 ชุด สำหรับ EC2/Metabase และ private DB subnets 2 ชุดสำหรับ RDS ใน 2 Availability Zones
- `aws_db_instance` PostgreSQL พร้อม encryption, backup และ Multi-AZ
- `aws_instance` Amazon Linux 2023 จำนวน 1 เครื่อง พร้อม Docker และ Metabase ที่ติดตั้งอัตโนมัติด้วย EC2 user data โดยรับ AMI ID ล่าสุดจาก AWS public SSM parameter
- Secrets Manager สำหรับ master password ที่ RDS สร้าง และ VPC Flow Logs ใน CloudWatch Logs

## การรักษาความปลอดภัย

- RDS ตั้ง `publicly_accessible = false` และอยู่ใน private subnet เท่านั้น
- RDS รับ PostgreSQL ที่พอร์ต `5432` จาก CIDR ภายใน VPC เท่านั้น
- EC2 ใช้ IMDSv2, root volume แบบเข้ารหัส และใช้ SSM สำหรับการจัดการเครื่องแทน SSH
- EC2 มีสิทธิ์อ่าน Secrets Manager ได้เฉพาะ secret ที่ RDS สร้างให้ เพื่อ bootstrap Metabase
- Metabase เปิดผ่าน TCP/3000 ตาม allowlist `metabase_allowed_cidrs`

> ค่า example ใช้ `0.0.0.0/0` เพื่อให้ทดสอบจากภายนอกได้ทันที ควรเปลี่ยนเป็น IP สาธารณะของสำนักงาน/VPN ก่อนนำไปใช้จริง เช่น `metabase_allowed_cidrs = ["203.0.113.10/32"]`

Metabase ให้บริการเป็น HTTP ที่พอร์ต 3000 โดยตรง สำหรับ production ควรเพิ่ม Application Load Balancer และ ACM certificate เพื่อใช้ HTTPS

## Deploy

```bash
cd No.1/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

แก้ค่า network, instance type และ allowlist IP ที่ไฟล์ `terraform.tfvars` ก่อน apply

## เข้าใช้งาน Metabase

หลัง deploy สำเร็จ ให้ดึง URL ด้วยคำสั่ง:

```bash
terraform output -raw metabase_url
```

เปิด URL ใน browser และตั้งค่า Metabase ในหน้าแรกได้ทันที โดย metadata ของ Metabase ถูกเก็บใน database ชื่อ `metabase` บน RDS แล้ว

## Outputs สำคัญ

- `metabase_url` — URL ภายนอกของ Metabase
- `ec2_instance_id` — ID สำหรับเข้าเครื่องด้วย SSM
- `postgres_endpoint` — private endpoint ของ RDS
- `postgres_master_user_secret_arn` — ARN ของ Secrets Manager ที่เก็บ credential RDS

## ข้อควรระวังเมื่อลบระบบ

RDS เปิด `deletion_protection = true` และตั้งให้สร้าง final snapshot ดังนั้นต้องปิด deletion protection ก่อนสั่ง `terraform destroy` เมื่อยืนยันว่าต้องการลบฐานข้อมูลจริง
