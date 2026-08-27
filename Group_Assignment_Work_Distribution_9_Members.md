# Group Assignment: Enterprise Windows Server Roles & Detailed Work Distribution (9 Members)

**Royal University of Phnom Penh (RUPP) — Year 4 Semester 1**  
**Course:** Windows Server & Network Infrastructure Administration  
**Group Size:** 9 Members  
**Total Server Roles Covered:** 14 Enterprise Roles  
**Primary Domain:** `e6.local` (NetBIOS: `E6`)  
**Primary Server:** `WIN-J17IMHCEMA9` (`pro-win-server` at `192.168.1.10`)  
**Primary Client:** `client` (`pro-win-client` at `192.168.1.100`)

---

## 📊 Master Task Allocation Matrix (14 Roles ──► 9 Members)

| Member # | Student Name | Assigned Server Roles (From Exact Syllabus List) | Core Protocols / Ports | Guide File Reference |
|:---:|:---|:---|:---|:---|
| **Member 1** | *[ Name 1 ]* | 🌐 **DHCP Server** & **DNS Server** | UDP 67/68, TCP/UDP 53 | [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md) |
| **Member 2** | *[ Name 2 ]* | 📁 **File Server** & **FTP Server** | TCP 445 (SMB), TCP 20/21 (FTP) | [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md) |
| **Member 3** | *[ Name 3 ]* | 🌍 **Web Server** & **Proxy Server** | TCP 80/443 (IIS), Port 3000 (Next.js) | [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md) |
| **Member 4** | *[ Name 4 ]* | 🗄️ **Database Server (Oracle, PostgreSQL)** | TCP 1521 (Oracle), TCP 5432 (Postgres) | [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md) |
| **Member 5** | *[ Name 5 ]* | 🖥️ **Terminal Server** | TCP 3389 (RDP), GPO Policies | [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md) |
| **Member 6** | *[ Name 6 ]* | 🛡️ **VPN Server** & **Radius Server** | L2TP/IPsec, SSTP (443), RADIUS (1812) | [`Step6_VPN_and_RADIUS_Server_Setup.md`](Step6_VPN_and_RADIUS_Server_Setup.md) |
| **Member 7** | *[ Name 7 ]* | ✉️ **Mail Server** | TCP 25/587 (SMTP), TCP 143/993 (IMAP) | [`Step7_Mail_Server_Setup.md`](Step7_Mail_Server_Setup.md) |
| **Member 8** | *[ Name 8 ]* | 💾 **Backup Server** | VSS Engine, `wbadmin`, System State | [`Step8_Backup_Server_Setup.md`](Step8_Backup_Server_Setup.md) |
| **Member 9** | *[ Name 9 ]* | ⚖️ **Load Balancing** & **Failover Cluster** | Virtual IP (VIP), Active/Standby Nodes | [`Step8_Backup_Server_Deep_Dive_Concepts.md`](Step8_Backup_Server_Deep_Dive_Concepts.md) |

---

## 🎯 14 Server Roles Verification Checklist

Every single server role from your professor's exact list is 100% accounted for:

* [x] **1. File Server** ──► Assigned to **Member 2**
* [x] **2. Web Server** ──► Assigned to **Member 3**
* [x] **3. Mail Server** ──► Assigned to **Member 7**
* [x] **4. FTP Server** ──► Assigned to **Member 2**
* [x] **5. VPN Server** ──► Assigned to **Member 6**
* [x] **6. Radius Server** ──► Assigned to **Member 6**
* [x] **7. Terminal Server** ──► Assigned to **Member 5**
* [x] **8. Load Balancing** ──► Assigned to **Member 9**
* [x] **9. Failover Cluster** ──► Assigned to **Member 9**
* [x] **10. DHCP Server** ──► Assigned to **Member 1**
* [x] **11. DNS Server** ──► Assigned to **Member 1**
* [x] **12. Proxy Server** ──► Assigned to **Member 3**
* [x] **13. Backup Server** ──► Assigned to **Member 8**
* [x] **14. Database Server (Oracle, PostgreSQL)** ──► Assigned to **Member 4**

---

## 📋 Complete Member Work Profiles & Detailed Action Steps

---

### 👤 Member 1: DHCP Server & DNS Server
* **Assigned Student:** `[ Name 1 ]`
* **Assigned Server Roles:** `DHCP Server`, `DNS Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **DHCP Server:** Automatically assigns IP addresses, subnet masks, default gateways (`192.168.1.1`), and DNS servers (`192.168.1.10`) to devices when they join the network, eliminating manual IP configuration and IP conflicts.
* **DNS Server:** Translates human-friendly domain names (like `mail.e6.local` or `portfolio.e6.local`) into machine IP addresses (`192.168.1.10`). In Cambodia, ISPs like SMART have external DNS servers to resolve public internet addresses; inside the company, Windows DNS handles private local resolution.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Configure DNS Forward Lookup Zone:** Create primary zone `e6.local` on the Domain Controller.
2. **Publish Required Records:**
   * Host (A) records: `mail.e6.local`, `ftp.e6.local`, `vpn.e6.local` pointing to `192.168.1.10`.
   * Mail Exchanger (MX) record: `e6.local` ──► Priority `10` ──► `mail.e6.local`.
   * Reverse Lookup Zone: `1.168.192.in-addr.arpa` with PTR pointer records.
   * DNS Forwarder: Configure forwarder to `8.8.8.8` / ISP DNS (SMART).
3. **Configure DHCP Scope:**
   * Scope Name: `LAN_Clients` (`192.168.1.100` to `192.168.1.200`, Subnet Mask `255.255.255.0`).
   * Router/Gateway Option: `192.168.1.1`.
   * DNS Server Option: `192.168.1.10`.
   * Lease Duration: Set to 8 days.

#### 🧪 Live Exam Demonstration:
* On `pro-win-client`, run `ipconfig /renew` to prove the client received `192.168.1.100`.
* Run `nslookup mail.e6.local` to show DNS returns `192.168.1.10`.
* **Guide File:** [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md)

---

### 👤 Member 2: File Server & FTP Server
* **Assigned Student:** `[ Name 2 ]`
* **Assigned Server Roles:** `File Server`, `FTP Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **File Server:** Centralizes company data storage on the network, makes backups easy, and enforces granular folder-level and file-level permissions so departments only access their own documents.
* **FTP Server (File Transfer Protocol):** Dedicated service for transferring files between clients and servers over TCP Ports 20 and 21. Used for uploading website assets, bulk file downloads, managing remote files (upload, delete, rename, move), and sharing files across diverse platforms.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Create Enterprise File Share:**
   * Create directory `C:\software` and share it as `\\pro-win-server\software` (SMB Port 445).
   * Enforce **NTFS Security Permissions**: Domain Admins (Full Control), Domain Users (Read & Execute, Write).
   * Enable Access-Based Enumeration (users only see folders they have permission to access).
2. **Install & Configure IIS FTP Server:**
   * Add FTP Server role under IIS.
   * Create FTP Site: Port `21`, SSL set to `Allow SSL` or `No SSL` for local lab.
   * Authentication: Basic Authentication; Authorization: Specified Users (Domain Users Read/Write).
3. **Open Firewall Rules:** Allow TCP Ports 445 (SMB) and 20, 21 (FTP).

#### 🧪 Live Exam Demonstration:
* From Client VM, open File Explorer, type `\\pro-win-server\software`, and create a text document.
* Open command prompt or FileZilla, connect to `ftp://192.168.1.10`, log in, and upload/download a file.
* **Guide File:** [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md)

---

### 👤 Member 3: Web Server & Proxy Server
* **Assigned Student:** `[ Name 3 ]`
* **Assigned Server Roles:** `Web Server`, `Proxy Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **Web Server:** Hosts web-based applications, business portals, and HTTP/HTTPS services accessible via browsers.
* **Proxy Server:** Acts as an intermediary (middleman) between clients and web/backend servers. Used to manage websites, block unauthorized downloads, inspect web traffic, log all user browsing activities, and shield internal backend architecture from public visibility.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Configure IIS Web Server:**
   * Install IIS Web Server listening on HTTP Port 80 and HTTPS Port 443.
   * Host production web assets under `C:\inetpub\wwwroot\`.
2. **Deploy Modern Web Application:**
   * Run the Next.js portfolio application under Node.js and **PM2** process manager on `localhost:3000`.
3. **Configure Reverse Proxy (Application Request Routing - ARR):**
   * Enable ARR proxy feature in IIS.
   * Configure URL Rewrite rule: match requests for `portfolio.e6.local` and reverse proxy them to `http://localhost:3000`.
   * Enable request logging to track client IP, request path, and timestamp.

#### 🧪 Live Exam Demonstration:
* Open a browser on Client VM, navigate to `http://portfolio.e6.local`, and prove the Next.js app renders seamlessly through IIS Reverse Proxy on port 80!
* **Guide File:** [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md)

---

### 👤 Member 4: Database Server (Oracle, PostgreSQL)
* **Assigned Student:** `[ Name 4 ]`
* **Assigned Server Role:** `Database Server (Oracle, PostgreSQL)`

#### 📖 Concepts & Theory (From Classroom Notes):
* **Database Server:** Centralized relational database engine storing structured company records, transactional data, user credentials, and student information with ACID guarantees.
* **PostgreSQL:** Open-source, enterprise-grade database on Port 5432, ideal for modern web applications and microservices.
* **Oracle Database 19c:** Commercial Fortune-500 relational database on Port 1521 featuring Multitenant architecture (Container Database CDB and Pluggable Databases PDB) for massive scalability and multi-department isolation.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Configure PostgreSQL 18:**
   * Manage PostgreSQL service listening on TCP Port 5432.
   * Configure `pg_hba.conf` and `postgresql.conf` to allow remote connections from `192.168.1.0/24`.
2. **Configure Oracle Database 19c Enterprise:**
   * Manage Oracle Listener on TCP Port 1521 (`TNSLSNR`).
   * Manage Container Database (`CDB$ROOT`) and Pluggable Database (`orclpdb`).
   * Create database tables, primary keys, and sample records.
3. **Open Firewall Rules:** Allow Inbound TCP 1521 (Oracle) and TCP 5432 (PostgreSQL).

#### 🧪 Live Exam Demonstration:
* Open DBeaver or SQL Developer on Client VM, connect to `192.168.1.10:5432` and `192.168.1.10:1521/orclpdb`, and execute `SELECT * FROM ...` queries live.
* **Guide File:** [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md)

---

### 👤 Member 5: Terminal Server
* **Assigned Student:** `[ Name 5 ]`
* **Assigned Server Role:** `Terminal Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **Terminal Server (Remote Desktop Services - RDS):** Allows multiple thin-client machines (devices with low RAM, weak CPUs, or no local hard disks) to connect over the network and run full Windows desktop sessions and applications hosted directly on the central server's hardware.
* All data and software stay on the server; the client devices only transmit screen pixels, mouse clicks, and keyboard strokes.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Enable Remote Desktop Services:**
   * Enable Remote Desktop on `pro-win-server` and verify TCP Port 3389 is listening.
2. **Configure Domain Controller GPO (User Rights Assignment):**
   * Edit Default Domain Controllers Policy: Navigate to *Computer Configuration ──► Policies ──► Windows Settings ──► Security Settings ──► Local Policies ──► User Rights Assignment*.
   * Add `Remote Desktop Users` group to: *"Allow log on through Remote Desktop Services"*.
3. **Assign User Permissions:**
   * Add domain accounts (`s.pengsorng`, `s.pengseang`) to the `Remote Desktop Users` group in Active Directory (`dsa.msc`).
4. **Configure Session Policies:** Set idle timeouts and disconnected session limits.

#### 🧪 Live Exam Demonstration:
* Launch `mstsc.exe` on Client VM 1 (logged in as `s.pengsorng`) and Client VM 2 (logged in as `administrator`) at the exact same time.
* Open Task Manager on the server to show two concurrent, isolated user desktop sessions running simultaneously!
* **Guide File:** [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md)

---

### 👤 Member 6: VPN Server & Radius Server
* **Assigned Student:** `[ Name 6 ]`
* **Assigned Server Roles:** `VPN Server`, `Radius Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **VPN Server (Virtual Private Network):** Provides secure, encrypted tunnels over untrusted networks (Internet/Wi-Fi) so remote employees can connect to the company LAN and access private internal resources, confidential databases, and journals as if they were sitting in the office.
* **Radius Server (Network Policy Server - NPS):** Centralized Authentication, Authorization, and Accounting (AAA) server. Instead of storing passwords on every router or VPN gateway, RADIUS links to Active Directory so users use **one single username and password** across all VPN connections, Wi-Fi access points, and network switches.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Configure Routing and Remote Access (RRAS):**
   * Configure RRAS as a VPN Server supporting L2TP/IPsec (with Pre-Shared Key) and SSTP (TCP Port 443).
   * Configure IPv4 static address pool for remote VPN clients (`192.168.1.201` – `192.168.1.220`).
2. **Configure Network Policy Server (NPS / RADIUS):**
   * Register NPS in Active Directory.
   * Configure Network Policy: *"Virtual Private Network (VPN) Connections"*.
   * Set Condition: Windows Groups = `Domain Users` or `VPN-Users`.
   * Set Authentication Methods: MS-CHAPv2.
3. **Configure User Dial-in:** Set user account Dial-in permission to *"Control access through NPS Network Policy"*.

#### 🧪 Live Exam Demonstration:
* From client laptop, open Windows VPN settings, dial in using domain account `E6\s.pengsorng`, receive an internal IP (`192.168.1.201`), and ping internal server resources.
* **Guide File:** [`Step6_VPN_and_RADIUS_Server_Setup.md`](Step6_VPN_and_RADIUS_Server_Setup.md)

---

### 👤 Member 7: Mail Server
* **Assigned Student:** `[ Name 7 ]`
* **Assigned Server Role:** `Mail Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **Mail Server:** Enterprise communication engine used to store, route, send, and receive electronic mail across the network.
* **Protocols:** Uses **SMTP** (Simple Mail Transfer Protocol on Port 25) to transmit outgoing mail, and **IMAP** (Internet Message Access Protocol on Port 143) to synchronize inboxes, sent folders, and messages across multiple client devices.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Install & Configure hMailServer:**
   * Install hMailServer 5.6.8 using .NET Framework 3.5 prerequisite.
   * Add company domain: `e6.local`.
   * Create mailboxes: `administrator@e6.local`, `s.pengsorng@e6.local`, and `s.pengseang@e6.local`.
2. **Configure IP Ranges & Relay Security:**
   * Under `Settings ──► Advanced ──► IP Ranges ──► Internet`: uncheck *"Require SMTP authentication for Local to local"* to permit internal testing, and set *"Allow plain text authentication"* to Always.
3. **Open Firewall Rules:** Open Inbound TCP Ports 25, 587 (SMTP) and 143, 993 (IMAP).
4. **Configure Client MUA (Mozilla Thunderbird):**
   * Install Thunderbird 115 ESR on Windows 8 client VM.
   * Configure IMAP (Port 143, `mail.e6.local`) and SMTP (Port 25, `mail.e6.local`).
   * Map the Sent folder (`Other: Local Folders ──► Sent` or server Sent folder).

#### 🧪 Live Exam Demonstration:
* Compose an email in Thunderbird on Client VM, send it to `administrator@e6.local`.
* Show the raw `.eml` email file sitting on the server's hard drive at:  
  `C:\Program Files (x86)\hMailServer\Data\e6.local\administrator\`.
* Send a reply from Administrator back to the client!
* **Guide File:** [`Step7_Mail_Server_Setup.md`](Step7_Mail_Server_Setup.md)

---

### 👤 Member 8: Backup Server
* **Assigned Student:** `[ Name 8 ]`
* **Assigned Server Role:** `Backup Server`

#### 📖 Concepts & Theory (From Classroom Notes):
* **Backup Server:** Centralized disaster recovery system responsible for capturing scheduled snapshots of the entire operating system, Active Directory database, databases, and user mailboxes to a dedicated storage repository.
* Protects the organization against hardware crashes, human errors (accidental deletion of files or users), and ransomware attacks.

#### 🛠️ What This Member Must Do (Action Steps):
1. **Provision Dedicated Backup Storage:**
   * Add a secondary 40 GB SCSI virtual disk in VMware Workstation.
   * Initialize as GPT, partition, and format as Drive **`B:\`** with label **`Backups`**.
2. **Install Windows Server Backup:**
   * Install feature: `Install-WindowsFeature Windows-Server-Backup -IncludeManagementTools`.
3. **Execute System State Backup via `wbadmin`:**
   * Run command: `wbadmin start systemstatebackup -backupTarget:B: -quiet`.
   * Backs up Active Directory (`ntds.dit`), `SYSVOL`, Registry, and Boot configuration.
4. **Configure Automated Schedule:**
   * Configure unattended automated daily backups at 2:00 AM using `wbadmin` or PowerShell policy.
5. **Live Disaster Recovery Test:**
   * Create test file `C:\Corporate_Secret.txt`, run backup, delete file to simulate disaster, and run `wbadmin start recovery` to resurrect the file!

#### 🧪 Live Exam Demonstration:
* Run `wbadmin get versions -backupTarget:B:` to show archived snapshots on Drive `B:\`.
* Delete a file live in front of the professor and restore it in 15 seconds!
* **Guide File:** [`Step8_Backup_Server_Setup.md`](Step8_Backup_Server_Setup.md)

---

### 👤 Member 9: Load Balancing & Failover Cluster
* **Assigned Student:** `[ Name 9 ]`
* **Assigned Server Roles:** `Load Balancing`, `Failover Cluster`

#### 📖 Concepts & Theory (From Classroom Notes):
* **Load Balancing:** The process of distributing incoming network traffic or workloads across multiple server nodes so that no single server becomes overloaded or slow.
* **Failover Cluster:** A group of servers (nodes) working together with heartbeat monitoring. If the active server crashes, loses power, or fails, the standby server automatically takes over its workload with zero interruption.
* **Classroom Example (DHCP Failover):** Configuring two DHCP servers where Server 1 is Active and Server 2 is Standby. If Server 1 goes down, Server 2 immediately takes over handing out IP addresses, subnet masks, and default gateways so clients never lose internet connectivity!

#### 🛠️ What This Member Must Do (Action Steps):
1. **Configure DHCP Failover Cluster (Active/Standby Mode):**
   * Configure DHCP Failover relationship between Server 1 (`192.168.1.10`) and Server 2 (`192.168.1.11`).
   * Mode: Hot Standby (Active 95%, Standby 5%) or Load Balance (50/50 split).
   * Shared Secret: Set cluster authentication key.
2. **Configure Network Load Balancing (NLB) for Web Services:**
   * Install Network Load Balancing feature: `Install-WindowsFeature NLB`.
   * Create NLB Cluster with Virtual IP (VIP: `192.168.1.50`).
   * Bind IIS web nodes to the cluster VIP.
3. **Simulate Live Failover:**
   * Release and renew client IP while powering off Server 1; prove Server 2 answers the DHCP request instantly!

#### 🧪 Live Exam Demonstration:
* Show DHCP console with Failover state: *"Normal / Active-Standby"*.
* Disconnect Server 1 network adapter; show that clients continue receiving IP leases and web pages from Server 2 with zero downtime!
* **Guide File:** [`Step8_Backup_Server_Deep_Dive_Concepts.md`](Step8_Backup_Server_Deep_Dive_Concepts.md)

---

## 🤝 Summary Recommendation for the Group:
1. Every member should write their name on their assigned section above.
2. Each member can open their corresponding markdown guide file to study their exact commands.
3. All 14 server roles from your professor's syllabus are covered with zero gaps! 🚀👥🎓
