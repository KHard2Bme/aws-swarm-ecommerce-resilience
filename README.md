# AWS Swarm E-Commerce Resilience 🚀

![Terraform](https://img.shields.io/badge/Terraform-IaC-blueviolet?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![Docker](https://img.shields.io/badge/Docker-Containers-blue?logo=docker)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-red?logo=prometheus)

---

## 🌍 Overview

This project simulates a **real-world e-commerce checkout outage** on AWS using **Docker Swarm**.  
It demonstrates **Infrastructure as Code**, **container orchestration**, **synthetic traffic generation**,  
and **full-stack observability** using **Prometheus**, **Grafana**, and **AWS Application Load Balancer (ALB)**.

🎯 **Real-world scenarios covered:**
- ⚠️ Backend service saturation
- 📈 Load-induced failures
- 🔍 Metrics-driven detection & recovery
- 🧑‍💻 Customer-impact analysis

---

## 🏗️ Architecture

```
Users 🌐
   ↓
AWS Application Load Balancer ⚖️
   ↓
EC2 Docker Swarm Cluster 🐳
   ↓
E-Commerce Services (Frontend + Checkout) 🛒
   ↓
Observability Stack (Prometheus + Grafana) 📊
```

---

## 🔧 Core Components

- 🖥️ **EC2 Instances** – Docker Swarm manager & worker nodes  
- 🐳 **Docker Swarm** – Service orchestration & self-healing  
- 🛒 **E-Commerce Application** – Frontend & checkout services  
- 🤖 **Synthetic Traffic Generator** – Simulated user behavior  
- 📊 **Prometheus** – Metrics collection (Swarm + ALB via CloudWatch Exporter)  
- 📈 **Grafana** – Dashboards & outage visualization  
- ⚖️ **AWS ALB** – Load balancing, health checks, traffic routing  

---

## ✨ Features

- ✅ Terraform-based AWS infrastructure (default VPC)
- ✅ Docker Swarm cluster on EC2
- ✅ ALB + Target Group integration
- ✅ Synthetic traffic-driven outage simulation
- ✅ Prometheus & Grafana observability
- ✅ Realistic failure & recovery workflows

---

## 🛠️ Prerequisites

- AWS account with **EC2, ALB, CloudWatch** permissions
- Terraform **>= 1.4**
- AWS CLI configured
- EC2 SSH key pair

---

## 🚀 Deployment Steps

```bash
git clone https://github.com/<username>/aws-swarm-ecommerce-resilience.git
cd aws-swarm-ecommerce-resilience
terraform init
terraform apply
```

After deployment:
- Access the application via the **ALB DNS**
- Grafana: `http://<manager-public-ip>:3000`
- Prometheus: `http://<manager-public-ip>:9090`

---

## 🧪 Testing & Observability

- 🔹 Validate baseline checkout traffic
- 🔹 Enable synthetic traffic generator
- 🔹 Simulate checkout service saturation
- 🔹 Observe ALB vs application metrics
- 🔹 Correlate latency & error rates with customer impact

**Key ALB Metrics:**
- `RequestCount`
- `TargetResponseTime`
- `HTTPCode_Target_5XX_Count`
- `HealthyHostCount`

---

## 📂 Project Structure

```
.
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── user_data/
│   ├── manager.sh
│   └── worker.sh
├── dashboards/
├── README.md
```

---

## 🌟 Future Enhancements

- 🔐 HTTPS with AWS ACM
- 📦 Auto Scaling Groups (advanced)
- 🧪 Chaos engineering scenarios
- 🚨 Prometheus alerts & SLOs

---

## 🎓 Learning Outcomes

- Infrastructure as Code with Terraform
- Docker Swarm operations & failure modes
- AWS ALB behavior & health checks
- Prometheus & Grafana observability
- Real-world incident response workflows

---

## 📜 License

MIT License

---

## 👨‍💻 Author

**Your Name** – Cloud / DevOps / SRE  
GitHub: https://github.com/<username>
