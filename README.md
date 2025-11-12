# Exxomm: MERN E-commerce DevOps Project

This repository documents the complete, automated deployment of the **Exxomm** MERN-stack e-commerce application to a production environment on **AWS**. The entire workflow—from cloud infrastructure creation to application deployment and monitoring—is managed using a modern **DevOps toolchain**.

---

## 🚀 Technology Stack

This project integrates several key technologies to achieve full automation and observability.

| Layer | Technology |
|--------|-------------|
| **Application** | MERN Stack (React.js, Node.js, Express.js) |
| **Database** | MongoDB Atlas (Managed Cloud Database) |
| **Containerization** | Docker & Docker Compose |
| **Cloud Provider** | Amazon Web Services (AWS) |
| **Infrastructure as Code (IaC)** | Terraform |
| **Configuration Management** | Ansible |
| **Monitoring** | Nagios Core |

---

## 🏗️ Project Architecture

The infrastructure is designed to be **scalable**, **secure**, and **fully automated**.

### Phase 1: Terraform (Infrastructure Provisioning)
Terraform provisions all foundational infrastructure on AWS, including:

- A **custom VPC**, public subnet, internet gateway, and route tables.
- An **EC2 instance** for the Frontend (React/Nginx).
- An **EC2 instance** for the Backend (Node.js/Express).
- An **EC2 instance** for the Monitoring Server (Nagios).
- Three distinct **Security Groups** (firewalls) to control web, Nagios, and database access.
- An **AWS Key Pair** (saved locally as `.pem`) for SSH access.

### MongoDB Atlas (Database)
- A managed, cloud-native MongoDB service for persistent storage.
- Firewall configured to only allow traffic from AWS EC2 public IPs.

### Phase 2: Ansible (Configuration & Deployment)
After Terraform completes, Ansible:

- **Configures servers:** Installs Docker, Nginx, and Nagios agents.
- **Deploys containers:** Pulls `exxomm-fe` and `exxomm-be` Docker images from Docker Hub.
- **Injects environment variables** securely using an **Ansible Vault** (`secrets.yml`).

### Phase 3: Nagios (Monitoring Setup)
- Installs and configures **Nagios Core** on the monitoring server.
- Deploys **NRPE agents** on the backend and frontend servers.
- The **Nagios dashboard** continuously monitors service uptime, performance, and connectivity.

---

## ⚙️ Prerequisites

Before running this deployment, ensure you have:

- An **AWS Account** with IAM user credentials configured.
- A **MongoDB Atlas** cluster.
- A **Docker Hub** account for hosting container images.
- **Terraform** and **Docker Desktop** installed locally.

---

## 🚀 Deployment Workflow

### Phase 0: Containerize the Application
Before deployment, the backend and frontend applications must be containerized.

#### Backend (`exxomm-be`)
- The Dockerfile sets up the Node.js environment.
- The `db.js` file references `process.env.MONGO_URI` for the database connection.

#### Frontend (`exxomm-fe`)
- The config file uses relative paths (`baseURL: ""`) in production.
- `nginx.conf` serves static files and reverse proxies API calls to the backend.

#### Build and Push Docker Images
```bash
docker build -t your-username/exxomm-be-image:latest ./exxomm-be
docker build -t your-username/exxomm-fe-image:latest ./exxomm-fe

docker push your-username/exxomm-be-image:latest
docker push your-username/exxomm-fe-image:latest
```

---

### Phase 1: Provision Infrastructure (Terraform)

```bash
cd infra/
terraform init
terraform apply
```

This will:
- Create all AWS resources.
- Generate an SSH key named `exxomm-key.pem`.

---

### Phase 2: Deploy Application (Ansible)

#### Update Inventory
Add your EC2 public IPs to `ansible/inventory`:
```ini
[frontend]
frontend_server ansible_host=<frontend_public_ip>

[backend]
backend_server ansible_host=<backend_public_ip>

[monitor]
nagios_server ansible_host=<nagios_public_ip>

[all:vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
```

#### Create Ansible Vault
```bash
docker run --rm -it -v "${pwd}:/ansible" cytopia/ansible:latest ansible-vault create /ansible/secrets.yml
```
Add:
```yaml
MONGO_URI: "mongodb+srv://<atlas-user>:<atlas-pass>@cluster..."
JWT_SECRET: "your-jwt-secret"
DOCKER_HUB_PASS: "your-docker-hub-password"
```

#### Run the Playbook
```bash
docker run --rm -it \
  -v "${pwd}:/ansible" \
  -v "G:\Projects\devops_project\exxomm\infra\exxomm-key.pem:/root/.ssh/id_rsa:ro" \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  willhallonline/ansible:latest \
  sh -c "chmod 600 /root/.ssh/id_rsa && ansible-playbook -i /ansible/inventory /ansible/deploy.yml --ask-vault-pass"
```

#### (Optional) Seed Database
```bash
docker run --rm -it \
  -v "${pwd}:/ansible" \
  -v "G:\Projects\devops_project\exxomm\infra\exxomm-key.pem:/root/.ssh/id_rsa:ro" \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  willhallonline/ansible:latest \
  sh -c "chmod 600 /root/.ssh/id_rsa && ansible backend -i /ansible/inventory -m shell -a 'docker exec exxomm-backend node backend/seederScript.js'"
```

---

### Phase 3: Configure Monitoring (Nagios)

#### Install Nagios Core Server
```bash
docker run --rm -it \
  -v "${pwd}:/ansible" \
  -v "G:\Projects\devops_project\exxomm\infra\exxomm-key.pem:/root/.ssh/id_rsa:ro" \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  willhallonline/ansible:latest \
  sh -c "chmod 600 /root/.ssh/id_rsa && ansible-playbook -i /ansible/inventory /ansible/nagios_install.yml"
```

#### Configure Nagios
```bash
docker run --rm -it \
  -v "${pwd}:/ansible" \
  -v "G:\Projects\devops_project\exxomm\infra\exxomm-key.pem:/root/.ssh/id_rsa:ro" \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  willhallonline/ansible:latest \
  sh -c "chmod 600 /root/.ssh/id_rsa && ansible-playbook -i /ansible/inventory /ansible/nagios_configure.yml"
```

---

## 🌐 Accessing the Application

| Component | URL | Notes |
|------------|-----|-------|
| **Frontend (Website)** | `http://<aws-frontend-public-ip>` | React/Nginx-based UI |
| **Backend (API)** | `http://<aws-backend-public-ip>` | Node.js/Express server |
| **Monitoring Dashboard** | `http://<aws-nagios-public-ip>/nagios4` | Username: `nagiosadmin` <br> Password: *(set in playbook)* |

---

## ✅ Summary

The **Exxomm** project demonstrates a complete CI/CD-style infrastructure setup and deployment pipeline for a MERN e-commerce application. Using **Terraform**, **Ansible**, and **Docker**, it achieves:

- Fully automated provisioning and configuration.
- Secure environment variable management via Ansible Vault.
- Centralized monitoring through Nagios.
- Infrastructure-as-Code reproducibility and scalability.

---

> 💡 *Designed and deployed as part of an end-to-end DevOps learning project integrating modern cloud automation principles.*
