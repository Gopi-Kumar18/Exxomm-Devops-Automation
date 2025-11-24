# Exxomm: Secure MERN E-commerce DevOps Project

This repository contains the fully automated deployment of the Exxomm MERN-based e‑commerce platform on AWS, designed with a production‑grade, three‑tier architecture and modern DevOps practices.

---

## 🚀 Live Deployment

**Live URL:** `http://13.204.242.139`
*(Replace with your actual Elastic IP. If unreachable, instances may be stopped under Free Tier.)*

---

## 🏗️ Architecture Overview

This project extends beyond a basic server setup and implements a decoupled, secure, distributed cloud layout.

### **1. Reverse Proxy Gatekeeper**

A dedicated Nginx proxy acts as the only public entry point.

* Users access the application through an Elastic IP on port 80.
* Traffic is internally forwarded to:

  * Frontend Server → Port 3000
  * Backend Server → Port 8000
* Internal routing occurs over the AWS private network.

### **2. Zero‑Trust Security Groups**

Strict firewall policies enforce a closed‑network model.

* **Proxy SG** → Only inbound HTTP from the internet.
* **Web SG** → Rejects public traffic entirely; allows inbound requests exclusively from the proxy.

### **3. Containerized Microservices**

* **Frontend:** React app served via Nginx (Alpine) → Host 3000 → Container 80
* **Backend:** Node/Express API → Host 8000 → Container 3000

---

## 🛠️ Technology Stack

| Layer          | Tool          | Purpose                                |
| -------------- | ------------- | -------------------------------------- |
| Infrastructure | Terraform     | Creates VPC, Subnets, EC2s, EIP, SGs   |
| Configuration  | Ansible       | Installs Nginx, Docker, deploys apps   |
| Containers     | Docker        | Packages frontend and backend services |
| Gateway        | Nginx         | Reverse proxy & internal router        |
| Database       | MongoDB Atlas | Cloud-managed data storage             |
| Monitoring     | Nagios Core   | Tracks uptime, HTTP health, TCP checks |

---

## ⚙️ Deployment Workflow

### **Phase 1 — Provision Infrastructure (Terraform)**

Run inside the `infra/` folder:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**Outcome:**
VPC, subnets, four EC2 instances (Proxy, Frontend, Backend, Nagios), and an Elastic IP bound to the proxy.

---

### **Phase 2 — Configure & Deploy (Ansible)**

#### **1. Update Inventory**

Example:

```
[proxy]
13.204.242.139 ansible_user=ubuntu ansible_ssh_private_key_file=exxomm-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[proxy:vars]
frontend_private_ip=10.0.1.38
backend_private_ip=10.0.1.237
```

#### **2. Deploy Applications**

```bash
docker run --rm -it -v "${PWD}:/work" -w /work willhallonline/ansible:latest \
  sh -c "chmod 600 exxomm-key.pem && chmod 644 inventory && ansible-playbook -i inventory deploy.yml --ask-vault-pass"
```

#### **3. Configure Reverse Proxy**

```bash
docker run --rm -it -v "${PWD}:/work" -w /work willhallonline/ansible:latest \
  sh -c "chmod 600 exxomm-key.pem && chmod 644 inventory && ansible-playbook -i inventory configure-proxy.yml"
```

---

### **Phase 3 — Monitoring (Nagios)**

Install Nagios to monitor infrastructure health:

```bash
docker run --rm -it -v "${PWD}:/work" -w /work willhallonline/ansible:latest \
  sh -c "chmod 600 exxomm-key.pem && chmod 644 inventory && ansible-playbook -i inventory nagios_install.yml"
```

Access Dashboard:

```
http://<Nagios-Public-IP>/nagios4
```

---

## 🌐 Traffic Flow Summary

1. User visits Elastic IP (port 80).
2. Proxy receives and interprets the request.
3. Proxy forwards it internally to the frontend at `10.x.x.x:3000` (Frontend Private IP).
4. Security Groups validate source as the proxy.
5. Docker maps port 3000 → container port 80.
6. React app responds to the client.

---

## 📜 License & Credits

Designed and implemented as a comprehensive DevOps project. Replace with your details where needed.
