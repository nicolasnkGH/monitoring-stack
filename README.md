# 📊 Home Lab Monitoring Stack

A production-grade observability suite deployed via **GitHub Actions** to a **Raspberry Pi 4 8GB RAM**. This stack provides a "Single Pane of Glass" for monitoring a distributed Proxmox cluster, AI workloads (RTX 3090 Ti), and 20+ containerized applications.

---

## 🏗️ Architecture Overview

The stack is designed for high availability and cross-VM communication:
* **Prometheus**: Time-series database scraping 27+ targets.
* **Grafana**: Visualization and alerting dashboard.
* **Loki**: Centralized log aggregation.
* **cAdvisor**: Container resource usage and performance metrics.
* **Nginx Proxy Manager**: Handles SSL and external routing for `*.domain.com`.

---

## 🚀 Automated Deployment

This project utilizes a **GitOps** approach. Changes pushed to the `main` branch trigger a GitHub Action that:
1.  Validates the `docker-compose.yml` syntax.
2.  Securely transfers configurations via SCP to the Raspberry Pi.
3.  Executes a remote SSH command to pull latest images and recreate containers.
4.  Performs a **Health Check** to ensure all 4 core services are `RUNNING`.

### Prerequisites
* GitHub Repository Secrets: `HOST`, `USERNAME`, `KEY`, `DOMAIN`, `GRAFANA_PASSWORD`.
* Raspberry Pi with Docker & Docker Compose installed.
* Node Exporter running on all monitored targets (Port 9100).

---

## 🌐 Networking Configuration

To ensure compatibility with an external **Nginx Proxy Manager (NPM)** VM, services are bound to the host's LAN IP.

| Service | Internal Port | External Port | Access URL |
| :--- | :--- | :--- | :--- |
| **Grafana** | 3000 | 3000 | `grafana.domain.com` |
| **Prometheus** | 9090 | 9090 | `prometheus.domain.com` |
| **cAdvisor** | 8080 | 8081 | `cadvisor.domain.com` |
| **Loki** | 3100 | 3100 | `loki.domain.com` |

> [!NOTE]
> **cAdvisor** is mapped to `8081` on the host to avoid conflicts with local Nginx services, but Prometheus scrapes it internally on `8080` via the Docker bridge network.

---

## 🎯 Scrape Targets

The stack currently monitors **27 endpoints** across the Columbus Lab:

* **Hypervisors**: 3x Proxmox Nodes
* **AI Stack**: Dedicated AI node with **NVIDIA RTX 3090 Ti**
* **Core Services**: Technitium DNS, Nginx Proxy Manager, Home Assistant
* **Media Stack**: Plex, Sonarr, Radarr, qBittorrent, and more.

### Adding New Targets
Update `targets.json` and push to main:
```json
{
  "targets": ["new-service.YOUR.DOMAIN:9100"],
  "labels": { "job": "new_category" }
}
```
---

## 🛠️ Maintenance Cheatsheet

**Reset Grafana Admin Password:**
```bash
docker exec -it grafana grafana cli admin reset-admin-password 'your-new-password'
```

**Check Prometheus Scrape Status:**

Visit `http://<pi-ip>:9090/targets` to verify all endpoints are `UP`.

**View Logs:**

```bash
docker compose logs -f [service_name]
```

## 🔒 Security Note: This stack is designed for a hardened home lab environment. It assumes:

**Network Isolation:** All containers run on a dedicated Monitoring VLAN.

**Reverse Proxy:** Traffic is handled via an internal Nginx Proxy Manager (NPM).

**Encryption:** Forced HTTPS/SSL via local certificates; all port 80/HTTP traffic is blocked at the firewall level.

**Access Control:** No direct WAN exposure; access is restricted to local/VPN clients.

---

Maintained by Nicolas Teixeira | 2026