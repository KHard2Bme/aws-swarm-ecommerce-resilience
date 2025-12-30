# 🛒 Swarm E-Commerce Project

[![Terraform](https://img.shields.io/badge/Terraform-1.4-blue)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-orange)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-Container-blue?logo=docker)](https://www.docker.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-red?logo=prometheus)](https://prometheus.io/)

---

## 🚀 Project Overview

This project demonstrates a **realistic e-commerce environment** deployed on **AWS using Docker Swarm**. It includes:

- EC2-based Swarm Manager and Worker nodes  
- **Docker Swarm cluster** with frontend and checkout services  
- Observability stack: **Prometheus + Grafana**  
- **Application Load Balancer (ALB)** with health checks  
- **Traffic generator** to simulate load  
- Outage simulation for CPU, latency, and traffic spikes  

The project is fully automated using **Terraform** for infrastructure provisioning and **user data scripts** for cluster bootstrap.

---

## 📦 Repository Structure

```
.
├── main.tf                 # Terraform main configuration
├── providers.tf            # Terraform AWS provider
├── variables.tf            # Terraform variables
├── outputs.tf              # Terraform outputs (URLs, ALB DNS)
├── user_data/
│   ├── manager.sh          # Swarm Manager bootstrap
│   ├── worker.sh           # Swarm Worker join
│   └── deploy-services.sh  # Deploy services & observability
└── README.md               # This file
```

---

## ⚙️ Setup Instructions

### 1️⃣ Terraform Apply
```bash
terraform init
terraform apply
```
- Creates EC2 instances for **manager + workers**
- Sets up **VPC, Security Groups, ALB, and Target Groups**
- Bootstraps **Docker Swarm cluster**

### 2️⃣ Deploy Services
SSH into the manager instance:
```bash
ssh ec2-user@<manager-public-ip>
```
Run:
```bash
./deploy-services.sh
```
- Creates overlay network
- Deploys **frontend**, **checkout**, **Prometheus**, **Grafana**, and **traffic generator**
- Services are scheduled according to Swarm roles

### 3️⃣ Access Services
- **Frontend/Checkout via ALB**: `http://<ALB-DNS>`  
- **Grafana**: `http://<manager-public-ip>:3000`  
- **Prometheus**: `http://<manager-public-ip>:9090`

Outputs are also available via Terraform:
```bash
terraform output
```

---

## 📊 Observability

### Prometheus Metrics
- Container CPU/Memory usage  
- Node-level performance  
- Service health  
- ALB target metrics  

### Grafana Dashboards
- CPU & Memory heatmaps  
- Request latency & rate  
- Service health overview  

> All dashboards update dynamically as traffic flows through the cluster.

---

## 🔥 Outage Simulation

Simulate real-world issues:

### 1️⃣ CPU Saturation
```bash
docker service update --command "sh -c 'while true; do :; done'" checkout
```
### 2️⃣ Latency Injection
```bash
docker service update --command "sh -c 'sleep 5 && nginx -g \"daemon off;\"'" checkout
```
### 3️⃣ Traffic Surge
```bash
docker service scale traffic-generator=10
```

**Monitor impact:**  
- Prometheus: CPU, memory, request rate  
- Grafana: Latency heatmaps, node load  
- ALB: Target response times, 5xx errors  

**Recovery:**  
```bash
docker service rollback checkout
docker service scale traffic-generator=1
```

---

## 💡 Best Practices Demonstrated

- Separation of **infrastructure (Terraform)** vs **application deployment (user data scripts + deploy-services.sh)**  
- Observability-driven outage validation  
- Safe, repeatable cluster bootstrap and service deployment  
- Real-world cloud patterns: ALB, Target Groups, multi-node Swarm

---

## 🔑 Key Variables (Terraform)
| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `key_name` | EC2 key pair | `LUIT_XXXXXX_XXXs` |
| `instance_type` | EC2 type | `t3.micro` |
| `manager_count` | Number of manager nodes | 1 |
| `worker_count` | Number of worker nodes | 2 |
| `project_name` | Project identifier | `swarm-ecommerce` |
| `alb_name` | ALB name | `swarm-ecommerce-alb` |

---

## ⚡ Notes

- Workers **auto-join** Swarm using manager token at runtime  
- Services are constrained to run on **appropriate nodes**:  
  - Frontend & Checkout → Workers  
  - Prometheus & Grafana → Manager  
- The **traffic generator** simulates load for monitoring and testing  
- Outage scenarios can be **reproduced repeatedly**  

---

## 🖼 Example Architecture

```
[ ALB ]
    |
[ Manager EC2 ]  <-- Prometheus + Grafana
    |
[ Worker EC2s ] <-- Frontend + Checkout + Traffic generator
```

---

## 🔗 References

- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)  
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)  
- [Prometheus](https://prometheus.io/docs/introduction/overview/)  
- [Grafana](https://grafana.com/docs/grafana/latest/)  

---

## 🎯 Outcome

- Fully functioning **Swarm-based e-commerce cluster** on AWS  
- **Observability** integrated via Prometheus & Grafana  
- **Outage simulation** demonstrates operational resiliency  
- Infrastructure is **fully Terraform-managed**  

