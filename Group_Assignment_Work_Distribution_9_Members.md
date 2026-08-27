# Group Assignment: Enterprise Windows Server Roles & Work Distribution (9 Members)

**Royal University of Phnom Penh (RUPP) — Year 4 Semester 1**  
**Course:** Windows Server & Network Infrastructure Administration  
**Group Size:** 9 Members  
**Total Server Roles Covered:** 14 Enterprise Roles  
**Operating System:** Windows Server 2022 (with Windows Containers / Docker)  
**Primary Domain:** `e6.local` (NetBIOS: `E6`)  
**Primary Server:** `WIN-J17IMHCEMA9` (`pro-win-server` at `192.168.1.10`)  
**Primary Client:** `client` (`pro-win-client` at `192.168.1.100`)

---

## 🎓 Master Classroom Notes & Lecture Concepts (Verbatim)

> This semester we have to do everything on Windows:
> * **Windows Server (Docker)**
> 
> 1. **File Server:**
>    * Easy to backup data from server.
>    * We set to share with permission.
>    * For network to make centralization.
> 2. **Web Server:**
>    * To hosting web-based application.
> 3. **Mail Server:**
>    * Use to store email and send mail.
> 4. **FTP Server (File Transfer Protocol Server):**
>    * Used for transferring files between a client and a server over a network.
>    * Uploading files to a web server.
>    * Downloading files from a server.
>    * Managing website files (upload, delete, rename, move).
>    * Sharing files between computers.
> 5. **VPN Server (Virtual Private Network Server) for LAN:**
>    * Server is used to provide secure, encrypted connections between remote users or networks over the Internet.
>    * If user wants to access network company to use any resource, journals of company, we have to access VPN to go to LAN of company to access these resources.
>    * VPN uses encrypted communication in LAN we communicate.
> 6. **Radius Server:**
>    * Server used for centralized authentication, authorization, and accounting (AAA) for users and devices connecting to a network.
>    * Is used to store user and password of our system.
>    * Helps us to store password and link to one user + password to use all different devices or applications.
> 7. **Terminal Server:**
>    * Is the machine that has small RAM or CPU, no hard disk (thin terminals).
>    * Terminal server lets many Terminal devices boot/connect from this terminal server.
>    * So we want everything on server, we have to set up terminal server and thin terminals can connect this terminal to terminal server to do any operation.
> 8. **Load Balancing:**
>    * Is the process of distributing incoming traffic or workloads across multiple servers so that no single server becomes overloaded.
> 9. **Failover Cluster:**
>    * Is a group of servers (nodes) working together so that if one server fails, another server automatically takes over its workload.
>    * DHCP Server is for network configuration, it must be used with + subnet mask + gateway.
>    * We normally use this failover cluster with DHCP server (meaning we set up many DHCP servers, one active others standby; if active fails, standby becomes active).
> 10. **DHCP Server:**
>     * A DHCP server is used to automatically assign IP addresses and network configuration to devices when they join a network.
>     * Instead of manually configuring every device:
>       ```text
>       Device:
>       IP address: 192.168.1.50
>       Subnet mask: 255.255.255.0
>       Gateway: 192.168.1.1
>       DNS: 8.8.8.8
>       ```
>       The DHCP server provides these settings automatically.
> 11. **DNS Server:**
>     * Is a server that translates domain names into IP addresses so computers can find and communicate with each other on a network.
>     * We use SMART, we have ISP of SMART that has DNS server.
> 12. **Proxy Server:**
>     * Is a server that acts as an intermediary (middleman) between a client and the Internet or another server.
>     * We use to close or manage website, download, download manager and others.
>     * List all the actions or activities we have done like visit website or others.
>     * We use to improve the security.
> 13. **Backup Server:**
>     * Protects the organization against hardware crashes, human errors (accidental deletion of files or users), and ransomware attacks.
>     * Performs automated scheduled backups of the operating system, Active Directory database (`ntds.dit`), databases, and user mailboxes to an isolated storage repository.
> 14. **Database Server (Oracle, PostgreSQL):**
>     * Centralized relational database engine storing structured company records, transactional data, user credentials, and student information with ACID guarantees.
>     * PostgreSQL (Port 5432) for modern web applications; Oracle 19c (Port 1521) with Multitenant architecture (CDB/PDB) for enterprise scale.

---

## 📊 Master Allocation Matrix (14 Roles ──► 9 Members)

| Member # | Student Name | Assigned Server Roles | Core Protocols / Ports | Guide File Reference |
|:---:|:---|:---|:---|:---|
| **Member 1** | *[ Name 1 ]* | 🌐 **DHCP Server** & **DNS Server** | UDP 67/68, TCP/UDP 53 | [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md) |
| **Member 2** | *[ Name 2 ]* | 📁 **File Server** & **FTP Server** | TCP 445 (SMB), TCP 20/21 (FTP) | [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md) |
| **Member 3** | *[ Name 3 ]* | 🌍 **Web Server** & **Proxy Server** | TCP 80/443 (IIS), Port 3000 (Next.js) | [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md) |
| **Member 4** | *[ Name 4 ]* | 🗄️ **Database Server (Oracle, PostgreSQL)** | TCP 1521 (Oracle), TCP 5432 (Postgres) | [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md) |
| **Member 5** | *[ Name 5 ]* | 🖥️ **Terminal Server** | TCP 3389 (RDP), GPO Policies | [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md) |
| **Member 6** | *[ Name 6 ]* | 🛡️ **VPN Server** & **Radius Server** | L2TP/IPsec, SSTP (443), RADIUS (1812) | [`Step6_VPN_and_RADIUS_Server_Setup.md`](Step6_VPN_and_RADIUS_Server_Setup.md) |
| **Member 7** | *[ Name 7 ]* | ✉️ **Mail Server** | TCP 25/587 (SMTP), TCP 143/993 (IMAP) | [`Step7_Mail_Server_Setup.md`](Step7_Mail_Server_Setup.md) |
---

## ⚡ Quick Executive Summary: Technologies to Install & What to Do

| Member | Assigned Server Roles | Technology / Software to Install 📦 | What We Have to Do 🛠️ | What to Test 🧪 |
|:---:|:---|:---|:---|:---|
| **Member 1** | **DHCP Server**<br>**DNS Server** | • Windows Feature: `DHCP`<br>• Windows Feature: `DNS` | 1. Set static IP `192.168.1.10`.<br>2. Create zone `e6.local` with A, MX, PTR records.<br>3. Create DHCP Scope (`192.168.1.100 - .200`). | Run `ipconfig /renew` on client; run `nslookup mail.e6.local`. |
| **Member 2** | **File Server**<br>**FTP Server** | • Feature: `FS-FileServer`<br>• Feature: `Web-Ftp-Server` under IIS | 1. Create `C:\software` share (`\\pro-win-server\software`).<br>2. Set NTFS permissions (Admins Full, Users Read/Write).<br>3. Configure IIS FTP site on Port 21. | Map network drive `net use Z:`; upload/download via CLI FTP. |
| **Member 3** | **Web Server**<br>**Proxy Server** | • Feature: `Web-Server` (IIS)<br>• IIS ARR & URL Rewrite<br>• Node.js & PM2 (or Docker) | 1. Host web assets under `C:\inetpub\wwwroot\`.<br>2. Run Next.js portfolio on `localhost:3000`.<br>3. Configure IIS ARR reverse proxy from port 80 to 3000. | Browse `http://portfolio.e6.local`; inspect proxy headers. |
| **Member 4** | **Database Server**<br>*(Oracle, PostgreSQL)* | • PostgreSQL 18 (Port 5432)<br>• Oracle Database 19c (Port 1521)<br>• DBeaver SQL Client | 1. Install PostgreSQL on 5432; create `company_db`.<br>2. Install Oracle 19c on 1521; configure PDB `orclpdb`.<br>3. Open firewall ports 1521 & 5432. | Connect from client via DBeaver; run SQL queries & rollback. |
| **Member 5** | **Terminal Server** | • Feature: `RDS-RD-Server` (Remote Desktop)<br>• Group Policy Management (`gpmc.msc`) | 1. Enable RDP on Port 3389.<br>2. Edit GPO: Allow logon through Remote Desktop.<br>3. Add domain users to `Remote Desktop Users` group. | Launch `mstsc.exe` on Client 1 & 2 simultaneously for dual login. |
| **Member 6** | **VPN Server**<br>**Radius Server** | • Feature: `RemoteAccess` (RRAS)<br>• Feature: `NPAS` (Network Policy Server) | 1. Configure RRAS VPN (L2TP/IPsec + SSTP).<br>2. Set static IP pool `192.168.1.201 - .220`.<br>3. Configure NPS RADIUS network policy with MS-CHAPv2. | Connect to VPN via `rasdial`; access `\\192.168.1.10\software` over tunnel. |
| **Member 7** | **Mail Server** | • Software: `hMailServer 5.6.8`<br>• Prerequisite: `.NET 3.5`<br>• Client: Mozilla Thunderbird 115 | 1. Install hMailServer; add domain `e6.local`.<br>2. Create accounts `administrator`, `s.pengsorng`.<br>3. Configure Thunderbird on client (IMAP 143, SMTP 25). | Send email from Client to Admin; show raw `.eml` on server; reply! |
| **Member 8** | **Backup Server** | • Feature: `Windows-Server-Backup`<br>• CLI tool: `wbadmin.exe`<br>• Dedicated 40 GB SCSI Virtual Disk | 1. Format dedicated Drive `B:\` as NTFS.<br>2. Run System State backup (`ntds.dit`, Registry).<br>3. Schedule automatic 2:00 AM daily backup. | Delete test file `C:\Secret.txt`; run `wbadmin recovery` to resurrect! |
| **Member 9** | **Load Balancing**<br>**Failover Cluster** | • Feature: `NLB` (Network Load Balancing)<br>• Feature: `Failover-Clustering`<br>• DHCP Failover Feature | 1. Configure DHCP Failover (Active/Standby mode).<br>2. Configure NLB cluster with Virtual IP `192.168.1.50`.<br>3. Bind web traffic to cluster VIP. | Stop DHCP on Server 1; prove Server 2 answers client `renew`! |

---

# 📋 Detailed "What to DO" & "What to TEST" for Each Member

---

### 👤 Member 1: DHCP Server & DNS Server
* **Assigned Student:** `[ Name 1 ]`
* **Assigned Server Roles:** `DHCP Server`, `DNS Server`

#### 📖 Classroom Notes & Core Concepts:
* **DHCP Server:** Automatically assigns IP addresses and network configuration to devices when they join a network. Instead of manually configuring every device with IP address (`192.168.1.50`), Subnet mask (`255.255.255.0`), Gateway (`192.168.1.1`), and DNS (`8.8.8.8`), the DHCP server provides these settings automatically.
* **DNS Server:** Translates domain names into IP addresses so computers can find and communicate with each other on a network. We use SMART ISP DNS server for outside internet, and Windows DNS for private company domains (`e6.local`).

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Set Static Server IP:** Configure `192.168.1.10`, subnet mask `255.255.255.0`, gateway `192.168.1.1` on `pro-win-server`.
2. **Configure DNS Forward Lookup Zone:** Create primary zone `e6.local`.
3. **Configure DNS Records:**
   * Create Host (A) records: `mail.e6.local` (192.168.1.10), `ftp.e6.local` (192.168.1.10), `vpn.e6.local` (192.168.1.10).
   * Create Mail Exchanger (MX) record: `e6.local` ──► Priority `10` ──► `mail.e6.local`.
   * Create Reverse Lookup Zone `1.168.192.in-addr.arpa` and enable automatic PTR pointer generation.
   * Configure DNS Forwarders: Add ISP DNS (SMART) / Google `8.8.8.8`.
4. **Configure DHCP Scope:**
   * Scope Name: `LAN_Clients` (`192.168.1.100` to `192.168.1.200`, Subnet Mask `255.255.255.0`).
   * Router/Gateway Option: `192.168.1.1`.
   * DNS Server Option: `192.168.1.10`.
   * Configure Exclusion Range: `192.168.1.180 - .190` (reserved for network printers).
   * Configure IP Reservation: Bind Client VM's MAC address permanently to `192.168.1.150`.

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Automatic IP Lease Verification):**
  On `pro-win-client`, open PowerShell and run:
  ```powershell
  ipconfig /release
  ipconfig /renew
  ipconfig /all
  ```
  👉 *Verify:* Prove client gets an IP from the `.100` pool, Subnet Mask `255.255.255.0`, Default Gateway `192.168.1.1`, and DNS Server `192.168.1.10`!
* **Test Case 2 (IP Reservation Boundary Test):**
  On `pro-win-client`, run `ipconfig /renew`. Check if the IP equals `192.168.1.150`.  
  👉 *Verify:* Even after restarting the client VM, DHCP always reserves `192.168.1.150` for this specific MAC address!
* **Test Case 3 (DNS Forward & Reverse Lookup Test):**
  On `pro-win-client`, run:
  ```powershell
  nslookup mail.e6.local        # Forward test (Name -> IP)
  nslookup 192.168.1.10        # Reverse PTR test (IP -> Name)
  nslookup google.com          # Forwarder test (SMART/Google 8.8.8.8)
  ```
  👉 *Verify:* Forward resolves to `192.168.1.10`, Reverse resolves to `mail.e6.local`, and External resolves via SMART ISP!

---

### 👤 Member 2: File Server & FTP Server
* **Assigned Student:** `[ Name 2 ]`
* **Assigned Server Roles:** `File Server`, `FTP Server`

#### 📖 Classroom Notes & Core Concepts:
* **File Server:** Easy to backup data from server. We set to share with permissions. For network to make centralization.
* **FTP Server (File Transfer Protocol Server):** Used for transferring files between a client and a server over a network:
  * Uploading files to a web server.
  * Downloading files from a server.
  * Managing website files (upload, delete, rename, move).
  * Sharing files between computers.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Create Central File Shares:**
   * Create folder `C:\CompanyShares\Software` shared as `\\pro-win-server\software` (SMB Port 445).
   * Create folder `C:\CompanyShares\Finance` shared as `\\pro-win-server\finance`.
2. **Enforce NTFS vs Share Security Permissions:**
   * `Software`: Share = Everyone (Change), NTFS = Domain Users (Read & Execute, Write).
   * `Finance`: NTFS = Finance-Group (Full Control), Domain Users (Access Denied).
   * Enable Access-Based Enumeration (users only see folders they have permission to access).
3. **Configure Disk Quotas:**
   * Set a 500 MB disk quota on user folders with an email warning at 400 MB.
4. **Configure IIS FTP Server:**
   * Install IIS FTP Server role on Port 21.
   * Create folders: `C:\inetpub\ftproot\Public` (Read-only) and `C:\inetpub\ftproot\Uploads` (Read/Write).
   * Configure Basic Authentication and User Isolation.
   * Open Firewall: Inbound TCP 445 (SMB) and TCP 20, 21 (FTP).

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (SMB Drive Mapping & Centralization):**
  On Client VM, map the network drive:
  ```cmd
  net use Z: \\pro-win-server\software
  ```
  👉 *Verify:* Open Drive `Z:\` in File Explorer, create a file named `report.docx`, and verify it appears centralized on the server at `C:\CompanyShares\Software\report.docx`!
* **Test Case 2 (Permission Enforcement - Negative Test):**
  On Client VM, attempt to open `\\pro-win-server\finance` as standard user `s.pengsorng`.  
  👉 *Verify:* Windows displays: **"Access Denied: You do not have permission to access \\pro-win-server\finance"**!
* **Test Case 3 (FTP File Management: Upload, Delete, Rename, Move):**
  On Client VM command prompt, connect via CLI FTP:
  ```cmd
  ftp 192.168.1.10
  # Login as s.pengsorng
  cd Uploads
  put client_file.txt
  rename client_file.txt shared_file.txt
  ls
  delete shared_file.txt
  quit
  ```
  👉 *Verify:* All 4 actions (Upload, Rename, List, Delete) complete successfully over Port 21!

---

### 👤 Member 3: Web Server & Proxy Server
* **Assigned Student:** `[ Name 3 ]`
* **Assigned Server Roles:** `Web Server`, `Proxy Server`

#### 📖 Classroom Notes & Core Concepts:
* **Web Server:** To hosting web-based application.
* **Proxy Server:** Acts as an intermediary (middleman) between a client and the Internet or another server. We use to close or manage website, download, download manager and others. Lists all the actions or activities we have done like visit website or others. We use to improve the security.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Configure IIS Web Server:**
   * Install IIS Web Server listening on HTTP Port 80 and HTTPS Port 443.
   * Host production web assets under `C:\inetpub\wwwroot\`.
   * Configure custom error pages (Custom 404 Page).
2. **Deploy Containerized / Modern Web Application:**
   * Deploy the Next.js portfolio application running under **PM2** (or Docker on Windows Server) on `localhost:3000`.
3. **Configure Reverse Proxy (Application Request Routing - ARR):**
   * Enable ARR proxy module in IIS.
   * Create URL Rewrite rule: Match incoming requests for `portfolio.e6.local` and reverse proxy them to `http://localhost:3000`.
4. **Configure Proxy Security & Activity Logging:**
   * Configure Request Filtering: Block requests containing dangerous extensions (`.exe`, `/admin/`).
   * Enable W3C Extended Logging in `C:\inetpub\logs\LogFiles\` to record Client IP, Date/Time, URI Stem, HTTP Method, and Status Code.

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Web Application Delivery):**
  Open Google Chrome on Client VM and browse to: `http://portfolio.e6.local`.  
  👉 *Verify:* The Next.js web application renders smoothly through IIS on Port 80!
* **Test Case 2 (Middleman Reverse Proxy Header Verification):**
  On Client VM, run:
  ```powershell
  Invoke-WebRequest -Uri "http://portfolio.e6.local" | Select-Object -ExpandProperty Headers
  ```
  👉 *Verify:* The header returns `Server: Microsoft-IIS/10.0`, proving IIS acted as the middleman proxy hiding Node.js!
* **Test Case 3 (Proxy Website Management & Activity Logging):**
  * In browser, try browsing to: `http://portfolio.e6.local/admin` or `http://portfolio.e6.local/download.exe`.  
    👉 *Verify:* The Proxy blocks it with **`403 Forbidden`**!
  * Open `C:\inetpub\logs\LogFiles\W3SVC1\` on server:  
    👉 *Verify:* Show the logged line with client IP `192.168.1.100` and the blocked `403` status!

---

### 👤 Member 4: Database Server (Oracle, PostgreSQL)
* **Assigned Student:** `[ Name 4 ]`
* **Assigned Server Role:** `Database Server (Oracle, PostgreSQL)`

#### 📖 Classroom Notes & Core Concepts:
* **Database Server:** Centralized relational database engine storing structured company records, transactional data, user credentials, and student information with ACID guarantees.
* **PostgreSQL:** Open-source, enterprise-grade database on Port 5432, ideal for modern web applications and microservices.
* **Oracle Database 19c:** Commercial Fortune-500 relational database on Port 1521 featuring Multitenant architecture (Container Database CDB and Pluggable Databases PDB) for massive scalability and multi-department isolation.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Configure PostgreSQL 18:**
   * Manage PostgreSQL service listening on TCP Port 5432.
   * Edit `pg_hba.conf` to allow remote connections from LAN subnet `192.168.1.0/24`.
   * Create database `e6_company` and user `db_admin` with password `abc@1234`.
   * Create table `employees (id INT PRIMARY KEY, name VARCHAR(50), salary NUMERIC, department VARCHAR(50))`.
2. **Configure Oracle Database 19c Enterprise:**
   * Manage Oracle Listener on TCP Port 1521 (`TNSLSNR`).
   * Manage Container Database (`CDB$ROOT`) and Pluggable Database (`orclpdb`).
   * Create tablespace `APP_DATA` and table `STUDENTS (student_id INT, student_name VARCHAR2(100), gpa NUMBER)`.
3. **Open Firewall Rules:** Allow Inbound TCP 1521 (Oracle) and TCP 5432 (PostgreSQL).

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Remote SQL Query from Client):**
  Open DBeaver on Client VM:
  * Connect to PostgreSQL at `192.168.1.10:5432/e6_company`.
  * Run: `SELECT * FROM employees;`  
  👉 *Verify:* Table data returns live across the network!
* **Test Case 2 (ACID Transaction Consistency & Rollback Test):**
  In DBeaver, run this transaction:
  ```sql
  BEGIN;
  INSERT INTO employees VALUES (999, 'Test Ghost', 5000, 'Security');
  ROLLBACK; -- Cancel before commit!
  SELECT * FROM employees WHERE id = 999;
  ```
  👉 *Verify:* Returns 0 rows (proving transaction isolation works)! Then run with `COMMIT;` and prove persistent storage!
* **Test Case 3 (Oracle Multitenant PDB Verification):**
  In Oracle SQL Developer, connect to `192.168.1.10:1521/orclpdb` and execute:
  ```sql
  SELECT sys_context('USERENV', 'CON_NAME') AS CONTAINER_NAME FROM dual;
  ```
  👉 *Verify:* Query returns `ORCLPDB` (proving access into the isolated Pluggable Database)!

---

### 👤 Member 5: Terminal Server
* **Assigned Student:** `[ Name 5 ]`
* **Assigned Server Role:** `Terminal Server`

#### 📖 Classroom Notes & Core Concepts:
* **Terminal Server:** Is the machine that has small RAM or CPU, no hard disk (thin terminals). Terminal server lets many Terminal devices boot/connect from this terminal server. So we want everything on server, we have to set up terminal server and thin terminals can connect this terminal to terminal server to do any operation.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Enable Remote Desktop Services:**
   * Enable Remote Desktop on `pro-win-server` and verify TCP Port 3389 is listening.
2. **Configure Domain Controller GPO (User Rights Assignment):**
   * Open `gpmc.msc` ──► Edit *Default Domain Controllers Policy*.
   * Navigate to: *Computer Configuration ──► Policies ──► Windows Settings ──► Security Settings ──► Local Policies ──► User Rights Assignment*.
   * Add `Remote Desktop Users` group to: *"Allow log on through Remote Desktop Services"*.
3. **Assign User Permissions:**
   * In Active Directory (`dsa.msc`), add domain users (`s.pengsorng`, `s.pengseang`) to the `Remote Desktop Users` group.
4. **Configure Session Limits (GPO):**
   * Set *End disconnected session* to 15 minutes.
   * Set *Active but idle session limit* to 30 minutes.

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Simultaneous Multi-Session Login):**
  * From Client VM 1: Launch `mstsc.exe` and connect as `E6\s.pengsorng`.
  * From Client VM 2: Launch `mstsc.exe` and connect as `E6\administrator`.  
  👉 *Verify:* Both users work inside full desktop sessions on the server at the exact same time!
* **Test Case 2 (Session Isolation in Task Manager):**
  Open Task Manager on the server ──► click the **Users** tab.  
  👉 *Verify:* Show Session ID 1 (`s.pengsorng`) and Session ID 2 (`administrator`) running completely separate desktop heaps and processes!
* **Test Case 3 (Session Reconnect with Unsaved Work):**
  * On Client 1, open Notepad, type *"Unsaved Work On Server"*, and close the RDP window without logging off.
  * Go to Client 2, open RDP, and log in as `s.pengsorng`.  
  👉 *Verify:* The session reconnects with Notepad open and the unsaved text intact!

---

### 👤 Member 6: VPN Server & Radius Server
* **Assigned Student:** `[ Name 6 ]`
* **Assigned Server Roles:** `VPN Server`, `Radius Server`

#### 📖 Classroom Notes & Core Concepts:
* **VPN Server (Virtual Private Network Server) for LAN:**
  * Server is used to provide secure, encrypted connections between remote users or networks over the Internet.
  * If user wants to access network company to use any resource, journals of company, we have to access VPN to go to LAN of company to access these resources.
  * VPN uses encrypted communication in LAN we communicate.
* **Radius Server:**
  * Server used for centralized authentication, authorization, and accounting (AAA) for users and devices connecting to a network.
  * Is used to store user and password of our system.
  * Helps us to store password and link to one user + password to use all different devices or applications.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Configure Routing and Remote Access (RRAS):**
   * Configure RRAS as a VPN Server supporting L2TP/IPsec (with Pre-Shared Key: `E6Secret2026!`) and SSTP (TCP Port 443).
   * Set IPv4 static address pool for remote VPN clients: `192.168.1.201 - .220`.
2. **Configure Network Policy Server (NPS / RADIUS):**
   * Register NPS in Active Directory (`netsh ras add registeredprovider`).
   * Create Network Policy: *"VPN Access Policy"*.
   * Condition: Windows Groups = `Domain Users`.
   * Authentication: MS-CHAPv2.
3. **Configure User Dial-in Policies:**
   * In Active Directory (`dsa.msc`), set user account Dial-in permission to *"Control access through NPS Network Policy"*.

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Encrypted Tunnel Dial-in):**
  From external laptop or client VM, connect to the VPN using domain account `E6\s.pengsorng`:
  ```cmd
  rasdial "E6-Company-VPN" s.pengsorng abc@1234
  ```
  👉 *Verify:* Connection status: Connected! Run `ipconfig` to show assigned VPN IP: `192.168.1.201`!
* **Test Case 2 (Accessing Company LAN Resources / Journals Over VPN):**
  While connected to VPN:
  * Ping internal server: `ping 192.168.1.10`.
  * Access internal network share: Open `\\192.168.1.10\software` in File Explorer!  
  👉 *Verify:* Internal company resources are accessible securely from outside the LAN!
* **Test Case 3 (RADIUS Central AAA Enforcement - Negative Test):**
  * In Active Directory, open `s.pengsorng` properties ──► **Dial-in** tab ──► select **"Deny access"**.
  * Try connecting to VPN again.  
  👉 *Verify:* VPN rejects connection with **"Error 691: Access Denied"**! Show the rejected authentication event in Event Viewer under *Network Policy Server*!

---

### 👤 Member 7: Mail Server
* **Assigned Student:** `[ Name 7 ]`
* **Assigned Server Role:** `Mail Server`

#### 📖 Classroom Notes & Core Concepts:
* **Mail Server:** Use to store email and send mail.
* **Protocols:** Uses **SMTP** (Simple Mail Transfer Protocol on Port 25) for outbound push delivery, and **IMAP** (Internet Message Access Protocol on Port 143) for two-way multi-device folder synchronization.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Install & Configure hMailServer:**
   * Install hMailServer 5.6.8 (with .NET Framework 3.5 prerequisite).
   * Create email domain: `e6.local`.
   * Create mail accounts: `administrator@e6.local`, `s.pengsorng@e6.local` (password `abc@1234`), and `s.pengseang@e6.local`.
2. **Configure Relay Security & IP Ranges:**
   * Under `Settings ──► Advanced ──► IP Ranges ──► Internet`: Uncheck *"Require SMTP authentication for Local to local"* to permit internal testing, and set *"Allow plain text authentication"* to Always.
3. **Open Firewall Ports:** Allow TCP 25, 587 (SMTP) and TCP 143, 993 (IMAP).
4. **Configure Client MUA (Mozilla Thunderbird):**
   * Install Thunderbird 115 ESR on Windows 8 client VM.
   * Incoming Server: IMAP (`mail.e6.local`, Port 143, Normal Password).
   * Outgoing Server: SMTP (`mail.e6.local`, Port 25, Normal Password).
   * Sent Folder: Map to `Other: Local Folders ──► Sent` (or server Sent folder).

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Two-Way Live Email Delivery):**
  * In Thunderbird on Client VM, compose an email to `administrator@e6.local` with subject *"Lab Test"* and click **Send**.
  * Open server disk: `C:\Program Files (x86)\hMailServer\Data\e6.local\administrator\` to see the raw `.eml` file!
  * From Administrator, reply back to `s.pengsorng@e6.local`.  
  👉 *Verify:* Reply arrives live in the Thunderbird inbox!
* **Test Case 2 (IMAP Multi-Folder Synchronization):**
  * In Thunderbird on Client VM, create a new folder: `Projects`.  
  👉 *Verify:* Look on server disk: `C:\Program Files (x86)\hMailServer\Data\e6.local\s.pengsorng\Projects\` is created automatically!
* **Test Case 3 (Anti-Relay Protection - Security Test):**
  * In Thunderbird, attempt to send an email to an outside public address: `victim@gmail.com`.  
  👉 *Verify:* hMailServer rejects with **`550 Relay Access Denied`** (proving spammers cannot hijack your server)!

---

### 👤 Member 8: Backup Server
* **Assigned Student:** `[ Name 8 ]`
* **Assigned Server Role:** `Backup Server`

#### 📖 Classroom Notes & Core Concepts:
* **Backup Server:** Protects the organization against hardware crashes, human errors (accidental deletion of files or users), and ransomware attacks. Performs automated scheduled backups of the operating system, Active Directory database (`ntds.dit`), databases, and user mailboxes to an isolated storage repository.

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Provision Dedicated Backup Storage:**
   * Attach secondary 40 GB SCSI virtual disk in VMware Workstation.
   * Initialize as GPT, partition, and format as Drive **`B:\`** labeled **`Backups`**.
2. **Install Windows Server Backup:**
   * Run: `Install-WindowsFeature Windows-Server-Backup -IncludeManagementTools`.
3. **Execute System State Backup via `wbadmin`:**
   * Run command: `wbadmin start systemstatebackup -backupTarget:B: -quiet`.
   * Backs up Active Directory (`ntds.dit`), `SYSVOL`, Registry, and Boot configuration.
4. **Configure Automated Schedule:**
   * Set up an unattended automated daily backup schedule at 2:00 AM using `wbadmin` or PowerShell policy.

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (Backup Catalog & Version Verification):**
  In PowerShell on `pro-win-server`, run:
  ```powershell
  wbadmin get versions -backupTarget:B:
  ```
  👉 *Verify:* Output displays backup timestamp and confirms: **"Can recover: System State, Volume, Files"**!
* **Test Case 2 (Live Disaster Recovery / File Resurrect Test):**
  1. Create a critical file:
     ```powershell
     Set-Content -Path "C:\Corporate_Secret.txt" -Value "CONFIDENTIAL 2026"
     ```
  2. Run quick backup:
     ```powershell
     wbadmin start backup -backupTarget:B: -include:C:\Corporate_Secret.txt -quiet
     ```
  3. Delete the file (simulate ransomware/accidental loss):
     ```powershell
     Remove-Item "C:\Corporate_Secret.txt" -Force
     Test-Path "C:\Corporate_Secret.txt"   # Returns False!
     ```
  4. Restore the file from backup:
     ```powershell
     $v = (wbadmin get versions -backupTarget:B: | Select-String "Version identifier:")[-1].Line.Split(":")[-1].Trim()
     wbadmin start recovery -version:$v -items:C:\Corporate_Secret.txt -itemType:File -quiet
     ```
  👉 *Verify:* The file is resurrected on `C:\` with its original text intact!
* **Test Case 3 (Automated Schedule Verification):**
  Run:
  ```powershell
  Get-WBSchedule -Policy (Get-WBPolicy)
  ```
  👉 *Verify:* Returns `{02:00:00}`, proving the automated midnight backup timer is active!

---

### 👤 Member 9: Load Balancing & Failover Cluster
* **Assigned Student:** `[ Name 9 ]`
* **Assigned Server Roles:** `Load Balancing`, `Failover Cluster`

#### 📖 Classroom Notes & Core Concepts:
* **Load Balancing:** Is the process of distributing incoming traffic or workloads across multiple servers so that no single server becomes overloaded.
* **Failover Cluster:** Is a group of servers (nodes) working together so that if one server fails, another server automatically takes over its workload.
* **Classroom Failover Cluster Example (DHCP Failover):** DHCP Server is for network configuration, it must be used with + subnet mask + gateway. We normally use this failover cluster with DHCP server (meaning we set up many DHCP servers, one active others standby; if active fails, standby becomes active).

#### 🛠️ What to DO MORE (Configuration Checklist):
1. **Configure DHCP Failover Cluster (Active/Standby Mode):**
   * Configure DHCP Failover relationship between Server 1 (`192.168.1.10`) and Server 2 (`192.168.1.11`).
   * Mode: Hot Standby (Active 95%, Standby 5%).
   * Set Shared Secret for cluster synchronization.
2. **Configure Network Load Balancing (NLB) for Web Services:**
   * Install feature: `Install-WindowsFeature NLB`.
   * Create NLB Cluster with Virtual IP (VIP: `192.168.1.50`).
   * Bind web traffic (Port 80/443) to cluster VIP.

#### 🧪 What to TEST (3 Detailed Test Cases):
* **Test Case 1 (DHCP Normal Lease from Active Server):**
  On Client VM, run `ipconfig /renew`.  
  👉 *Verify:* Server 1 (Active) handles and grants the lease.
* **Test Case 2 (Live DHCP Failover Under Server Crash):**
  * On Server 1, stop the DHCP service:
    ```powershell
    Stop-Service dhcpserver
    ```
  * On Client VM, immediately run `ipconfig /renew`.  
  👉 *Verify:* Server 2 (Standby) takes over instantly and issues the lease with ZERO network drop!
* **Test Case 3 (Web Server High Availability Test):**
  * Run a continuous ping or curl loop to the VIP: `ping -t 192.168.1.50`.
  * Disconnect Server 1 network adapter in VMware.  
  👉 *Verify:* The ping continues answering without drops because Server 2 handles the cluster traffic!

---

## 🏆 Summary
* Every single line from your lecture notes is preserved verbatim.
* Every member has a detailed **"What to DO MORE"** configuration checklist.
* Every member has **3 specific "What to TEST" test cases** with exact commands and expected results! 🚀👥🎓
