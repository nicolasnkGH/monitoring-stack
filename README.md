# 📈 Proxmox Cluster Observability with Zabbix

## Overview

This repository documents the deployment and configuration of a robust monitoring solution required to maintain the stability and health of my rapidly expanding home infrastructure. This project demonstrates proficiency in setting up a professional-grade observability stack, integrating system administration skills with real-time alerting.

## 💡 Challenge & Solution Rationale

### The Challenge
As my home infrastructure grew to include a three-node Proxmox cluster, various virtual machines, and containerized applications, I needed a centralized, efficient, and reliable system to track performance, preemptively identify hardware failure, and manage service uptime.

### Why Zabbix Was Chosen

While my professional experience includes extensive work with Prometheus and Grafana for monitoring Kubernetes-based applications, Zabbix was chosen for the home lab due to its suitability for agent-based monitoring and deep, out-of-the-box support for heterogeneous infrastructure (Proxmox, physical hosts, and Windows/Linux VMs). Zabbix excels at:

- **Ease of Configuration:** Agent installation and template-based monitoring require less custom metric exposition compared to Prometheus.
- **Built-in Alerting:** Provides a superior, comprehensive alerting and event management system necessary for critical home infrastructure.

## ✨ Project Highlights & Skills Demonstrated

**1. Monitoring Stack Implementation**
- **Core Deployment:** Zabbix server deployed on a resource-efficient Raspberry Pi (or similar low-power host) for 24/7 continuous operation.

- **Multi-Node Integration:** Successfully configured Zabbix agents and/or SNMP checks on all three Proxmox nodes and key guest virtual machines (VMs).

- **Infrastructure Metrics:** Collecting and visualizing critical metrics including CPU utilization, RAM consumption, network I/O, and storage health across the cluster.

**2. Real-Time Alerting and Event Management**
- **Telegram Integration:** Implemented a custom Zabbix media type and trigger action to send real-time text message alerts directly to my Telegram application upon detecting a critical event (e.g., node loss, disk failure, high CPU utilization).

- **Demonstrated Skill:** Proficiency in configuring third-party connectors and designing complex alert rules for instant notification of infrastructure degradation.

## 🛠️ Project Contents

This repository contains the necessary configuration files and documentation:

- ```zabbix_templates/```: Custom templates used for Proxmox and specific VM services.

- ```install_scripts/```: Any deployment scripts (e.g., shell scripts) used to automate agent setup.

- ```docs/```: Configuration guide detailing the Telegram media type setup and alerting rules.

## 🛠️ Project Contents

My experience with Zabbix is complemented by professional proficiency in other leading observability tools:

- **Prometheus & Grafana**: Used at a professional level for collecting, querying, and visualizing metrics from Kubernetes clusters and distributed microservices.
