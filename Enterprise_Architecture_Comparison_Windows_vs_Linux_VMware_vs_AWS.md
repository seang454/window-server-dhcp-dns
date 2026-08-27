# Enterprise Infrastructure Architecture Guide: Windows vs. Linux & VMware vs. AWS Cloud

**Royal University of Phnom Penh (RUPP) — Year 4 Computer Science**  
**Context:** Multi-Server System Administration, Enterprise Networking & Cloud Migration  
**Document Purpose:** Architectural comparison explaining why protocols are identical across operating systems, and why on-premises hypervisors (VMware) differ fundamentally from public cloud networks (AWS VPC).

---

## 📖 Table of Contents

1. [The Golden Rule of Enterprise Networking](#1-the-golden-rule-of-enterprise-networking)
2. [Master Comparison: 14 Server Roles Across Windows, Linux, VMware & AWS](#2-master-comparison-14-server-roles-across-windows-linux-vmware--aws)
3. [The Layer 2 vs. Layer 3 Reality: Why VMware Works and AWS Restricts](#3-the-layer-2-vs-layer-3-reality-why-vmware-works-and-aws-restricts)
4. [Why AWS Blocks DHCP Broadcasts & Port 25 (Technical Deep-Dive)](#4-why-aws-blocks-dhcp-broadcasts--port-25-technical-deep-dive)
5. [Windows Server vs. Linux on AWS: Identical Cloud Rules](#5-windows-server-vs-linux-on-aws-identical-cloud-rules)
6. [The Real-World Standard: The Hybrid Cloud Enterprise Architecture](#6-the-real-world-standard-the-hybrid-cloud-enterprise-architecture)
7. [Why VMware Workstation is the #1 Platform for University Exams](#7-why-vmware-workstation-is-the-1-platform-for-university-exams)
8. [Student Presentation Script: How to Explain This to the Professor](#8-student-presentation-script-how-to-explain-this-to-the-professor)

---

## 1. The Golden Rule of Enterprise Networking

```text
  ┌────────────────────────────────────────────────────────────────────────────────────────┐
  │                           THE UNIVERSAL PROTOCOL LAW                                   │
  │                                                                                        │
  │  Operating Systems (Windows vs. Linux) are just the software user interface.           │
  │  The NETWORK PROTOCOLS (TCP/IP, DORA, DNS, SMB, HTTP, SMTP) are 100% UNIVERSAL!        │
  │                                                                                        │
  │  Whether you click in Windows Server Manager or write configuration in Linux /etc/:   │
  │  • DHCP is ALWAYS UDP Ports 67 & 68.                                                   │
  │  • DNS is ALWAYS TCP & UDP Port 53.                                                    │
  │  • SMB File Sharing is ALWAYS TCP Port 445.                                            │
  │  • Mail Delivery is ALWAYS TCP Port 25 (SMTP) & Port 143 (IMAP).                       │
  │  • Remote Desktop is ALWAYS TCP Port 3389.                                             │
  └────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Master Comparison: 14 Server Roles Across Windows, Linux, VMware & AWS

| # | Server Role | Protocol & Port | 🪟 Windows Server 2022 | 🐧 Linux Standard (Ubuntu/RHEL) | 💻 VMware Workstation Behavior | ☁️ AWS Cloud Behavior (VPC) |
|:---:|:---|:---|:---|:---|:---|:---|
| **1** | **DHCP Server** | UDP 67, 68 | Windows DHCP Server Role | `isc-dhcp-server` / `kea` / `dnsmasq` | ✅ **Native Layer 2 Broadcast** (DORA works 100%) | ❌ **Blocked!** AWS VPC drops broadcast packets |
| **2** | **DNS Server** | TCP/UDP 53 | Windows DNS Role (Active Directory) | BIND9 (`named`) / Unbound | ✅ **Full Local Control** (`e6.local`) | ⚠️ Uses AWS Route 53 or private hosted zones |
| **3** | **File Server** | TCP 445 (SMB) | File and Storage Services | Samba (`smbd` / CIFS) | ✅ **10 Gbps Virtual LAN Speed** | ☁️ EC2 self-hosted or AWS FSx / S3 |
| **4** | **FTP Server** | TCP 20, 21 | IIS FTP Service | `vsftpd` / `proftpd` | ✅ Native Active & Passive modes | ⚠️ Requires opening passive ports in Security Group |
| **5** | **Web Server** | TCP 80, 443 | Internet Information Services (IIS) | Nginx / Apache HTTP Server | ✅ Local virtual hosting & bindings | ✅ Publicly reachable via Elastic IP |
| **6** | **Proxy Server** | TCP 80, 8080 | IIS Application Request Routing (ARR) | Squid Proxy / HAProxy | ✅ Local reverse proxy to `localhost:3000` | ☁️ AWS ALB (Application Load Balancer) |
| **7** | **Database Server** | TCP 1521 / 5432 | Oracle 19c & PostgreSQL 18 | Oracle on Linux & PostgreSQL 18 | ✅ Full ACID transactions, local storage | ☁️ EC2 self-hosted or Amazon RDS |
| **8** | **Terminal Server** | TCP 3389 (RDP) | Remote Desktop Services (RDSH) | XRDP / Apache Guacamole | ✅ Multi-session concurrency testing | ⚠️ Exposed to brute force; requires Bastion/SSM |
| **9** | **VPN Server** | UDP 500/4500, TCP 443 | Routing & Remote Access (RRAS) | WireGuard / OpenVPN / strongSwan | ✅ Dial-in from physical laptop to VM | ☁️ AWS Client VPN or Transit Gateway |
| **10**| **RADIUS Server** | UDP 1812, 1813 | Network Policy Server (NPS) | FreeRADIUS | ✅ 802.1X central authentication | ☁️ AWS Directory Service / IAM Identity |
| **11**| **Mail Server** | TCP 25, 143 | hMailServer 5.6.8 | Postfix (SMTP) + Dovecot (IMAP) | ✅ Raw unblocked SMTP delivery | ❌ **Port 25 blocked by default** (Spam protection) |
| **12**| **Backup Server** | VSS Engine | Windows Server Backup (`wbadmin`) | Restic / BorgBackup / Rsync | ✅ Dedicated secondary virtual disk (`B:\`) | ☁️ AWS EBS Snapshots & AWS Backup vault |
| **13**| **Load Balancing**| Layer 4 / Layer 7 | Network Load Balancing (NLB) | HAProxy / Keepalived | ✅ Virtual IP (VIP) balancing | ☁️ AWS Network Load Balancer (NLB) |
| **14**| **Failover Cluster**| Heartbeat & Quorum| Failover Clustering (WSFC) | Pacemaker + Corosync | ✅ Active/Standby DHCP Failover | ☁️ Multi-AZ Cloud High Availability |

---

## 3. The Layer 2 vs. Layer 3 Reality: Why VMware Works and AWS Restricts

The fundamental difference between **VMware Workstation** and **AWS Cloud** is **how the virtual network is engineered**:

```text
  VMWARE WORKSTATION: LAYER 2 PHYSICAL SWITCH SIMULATION
  ┌────────────────────────────────────────────────────────────────────────┐
  │  Client VM ──► [Broadcast: 255.255.255.255] ──► Virtual Switch (VMnet8)│
  │                                                        │               │
  │                                                        ▼               │
  │                                               Windows Server 2022      │
  │                                               (Answers DHCP Offer!)    │
  └────────────────────────────────────────────────────────────────────────┘
  🟢 Result: Full broadcast domain. ARP, NetBIOS, and DHCP DORA work exactly like a physical cable!

  AWS VPC: LAYER 3 SOFTWARE-DEFINED ROUTED FABRIC (NO BROADCASTS)
  ┌────────────────────────────────────────────────────────────────────────┐
  │  Client EC2 ──► [Broadcast: 255.255.255.255] ──► AWS VPC SDN Fabric   │
  │                                                        │               │
  │                                                        ▼               │
  │                                               ❌ PACKET DROPPED!       │
  │                                               (Never reaches server!)  │
  └────────────────────────────────────────────────────────────────────────┘
  🔴 Result: AWS intentionally drops broadcast packets to prevent broadcast storms across millions of servers!
```

---

## 4. Why AWS Blocks DHCP Broadcasts & Port 25 (Technical Deep-Dive)

### 🚫 Why AWS Blocks Broadcast DHCP:
1. **Broadcast Storm Prevention:** In an AWS datacenter housing 1,000,000 servers, if instances sent broadcast packets (`255.255.255.255`), every server in the datacenter would have to process the packet, causing catastrophic network collapse!
2. **AWS Software-Defined Network (SDN):** AWS manages all IP allocation at the hypervisor level. When an EC2 instance boots, AWS assigns its private IP directly. You configure **AWS DHCP Option Sets** to tell instances which DNS server to use, but you cannot run a raw DHCP server.

### 🚫 Why AWS Blocks Outbound Port 25 (SMTP):
1. **Spam & IP Blacklisting Protection:** Hackers frequently launch cloud servers to send millions of spam and phishing emails. If AWS allowed open Port 25, major email providers (Gmail, Outlook, Yahoo) would blacklist the entire AWS IP range!
2. **The Cloud Alternative:** To send mail from AWS, you must submit a formal identity verification request to AWS support, use **Port 587 with STARTTLS**, or route through **Amazon Simple Email Service (SES)**.

---

## 5. Windows Server vs. Linux on AWS: Identical Cloud Rules

A common misconception among students is that switching from Windows Server to Linux allows them to bypass cloud limitations. **This is completely false!**

```text
┌──────────────────────────────────────┬──────────────────────────────────────┐
│ 🪟 Windows Server 2022 on AWS        │ 🐧 Linux (Ubuntu / RHEL) on AWS      │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Broadcast DHCP is BLOCKED by AWS.  │ • Broadcast DHCP is BLOCKED by AWS.  │
│ • Outbound Port 25 is BLOCKED.       │ • Outbound Port 25 is BLOCKED.       │
│ • Must configure AWS Security Groups.│ • Must configure AWS Security Groups.│
│ • Hard drives attach via AWS EBS.    │ • Hard drives attach via AWS EBS.    │
│ • Web traffic routes via AWS ALB.    │ • Web traffic routes via AWS ALB.    │
│ • Costs: Hardware + Windows License. │ • Costs: Hardware ONLY (Zero OS fee).│
└──────────────────────────────────────┴──────────────────────────────────────┘
```

👉 **Key Takeaway:** AWS enforces its networking rules at the **cloud infrastructure layer**, regardless of whether the operating system is Windows or Linux!

---

## 6. The Real-World Standard: The Hybrid Cloud Enterprise Architecture

Real-world enterprises (banks, hospitals, universities, multinationals) do not choose between On-Premises or Cloud — **they use BOTH in a Hybrid Cloud model**:

```text
  ========================================================================================
                             HYBRID ENTERPRISE ARCHITECTURE
  ========================================================================================

  🏢 ON-PREMISES HEADQUARTERS (Local LAN)            ☁️ AWS CLOUD VIRTUAL PRIVATE CLOUD (VPC)
  ┌────────────────────────────────────────┐         ┌───────────────────────────────────┐
  │ • Physical PCs, Laptops, Printers      │         │ • High-traffic IIS / Nginx Web    │
  │ • Local Windows DHCP Server (DORA)     │         │ • Cloud Application Load Balancer │
  │ • Primary Active Directory DC1         │◄───────►│ • Secondary Active Directory DC2 │
  │ • Local High-Speed SMB File Shares     │ (IPsec  │ • Oracle / PostgreSQL Database    │
  │ • Terminal Services (RDSH)             │  VPN)   │ • Off-Site S3 Backup Repository   │
  └────────────────────────────────────────┘         └───────────────────────────────────┘
```

### Strategic Placement Doctrine:
* **Keep On-Premises:** Services that interact directly with physical office equipment, local Ethernet cables, or require low-latency LAN throughput (DHCP, Local Print, Primary DC, 10 Gbps Video File Storage).
* **Move to Cloud (AWS):** Services that require 24/7/365 global reach, public internet traffic handling, auto-scaling, and off-site geographic disaster recovery (Web Apps, Public APIs, Cloud Databases, Backup Vaults).

---

## 7. Why VMware Workstation is the #1 Platform for University Exams

For university coursework and academic project evaluations:

1. **100% Free Forever:** Zero cloud billing surprises, credit card requirements, or hourly charges.
2. **100% Offline Resilience:** University Wi-Fi can drop, be throttled, or block ports during exams. VMware runs entirely on internal laptop memory (`VMnet8`), immune to internet outages!
3. **True Layer 2 Broadcast Domain:** DHCP DORA broadcasts, ARP requests, and NetBIOS name resolution function natively as they do on physical enterprise switches.
4. **Instant Snapshot Recovery:** The `Take Snapshot` and `Revert to Snapshot` features provide instant point-in-time recovery during lab experimentation.
5. **Exact Curriculum Alignment:** Academic syllabi are designed around hypervisor virtualization where professors inspect virtual network adapters, static IP configurations, and client-server handshakes directly.

---

## 8. Student Presentation Script: How to Explain This to the Professor

When presenting your project, use this script during your introduction or conclusion to demonstrate senior-level architectural maturity:

> *"Respected Professor, our team designed this enterprise infrastructure recognizing two fundamental architectural truths:*
> 
> *First, network protocols are universal: whether implemented on Windows Server 2022 or enterprise Linux, DHCP remains UDP 67/68, DNS remains Port 53, and SMB remains Port 445.*
> 
> *Second, we evaluated deployment environments: On-premises virtualization (VMware Workstation) provides a complete Layer 2 broadcast domain, making it the mathematically correct environment to deploy and test native DHCP DORA negotiation, raw SMTP mail relay, and Active Directory replication.*
> 
> *In contrast, public cloud providers like AWS operate an abstract Layer 3 Software-Defined Network that intentionally filters Layer 2 broadcasts and outbound Port 25 to protect cloud scale. Therefore, in real enterprise IT, organizations adopt a **Hybrid Cloud Architecture**—maintaining local network infrastructure on-premises while federating web, database, and disaster recovery tiers to the cloud.*
> 
> *Our project today demonstrates the complete, fully operational on-premises core of this enterprise architecture."*

👉 **Result:** This demonstration of architectural depth proves you understand not just how to click buttons, but **how enterprise computer networks actually operate globally**! 🚀🎓🏆
