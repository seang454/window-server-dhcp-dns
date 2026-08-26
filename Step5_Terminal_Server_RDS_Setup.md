# Step 5: Terminal Server (Remote Desktop Services - RDS) Setup & Deployment Guide

**Windows Server 2022 on VMware Workstation**  
**Domain:** `e6.local`  
**Server Hostname:** `WIN-J17IMHCEMA9` (`server1.e6.local`)  
**Server IP:** `192.168.1.10`  
**Client VM:** `CLIENT` (`pro-win-client` at `192.168.1.100`)  
**Protocols & Ports:** TCP `3389` (RDP), TCP `443` (HTTPS RDWeb), TCP `80` (HTTP)  

---

## 📖 Deep-Dive Concepts & Architecture

### 🖥️ What is Terminal Server (RDS)?

**Terminal Server** (officially named **Remote Desktop Services - RDS** in Windows Server) is a centralized server role that enables **multiple users on remote client computers to log into a single Windows Server host simultaneously across the network** to run complete desktop environments and centralized applications.

```
                      ENTERPRISE RDS ARCHITECTURE
                      
  ┌─────────────────────────────────┐        ┌─────────────────────────────────┐
  │  Client Computer 1 (Alice)      │        │  Client Computer 2 (Bob)        │
  │  (Low-cost laptop / Thin Client)│        │  (Windows 10 / Mac Workstation) │
  │  User: s.pengseang              │        │  User: e6\bob                   │
  └────────────────┬────────────────┘        └────────────────┬────────────────┘
                   │                                          │
                   └────────────────────┬─────────────────────┘
                                        │ RDP Protocol (Port 3389)
                                        │ / HTTPS RDWeb (Port 443)
                                        ▼
                   ============================================
                   │      WINDOWS TERMINAL SERVER (RDS)       │
                   │      IP: 192.168.1.10 (pro-win-server)   │
                   │                                          │
                   │  ┌────────────────────────────────────┐  │
                   │  │ RD Session Host (RDSH Engine)      │  │
                   │  │ ├── Session 1: s.pengseang (Active)│  │
                   │  │ └── Session 2: bob (Active)        │  │
                   │  └────────────────────────────────────┘  │
                   │  ┌────────────────────────────────────┐  │
                   │  │ Published RemoteApps:              │  │
                   │  │ ├── DBeaver Community Edition      │  │
                   │  │ ├── Oracle SQL*Plus CLI            │  │
                   │  │ └── Accounting / ERP Tools         │  │
                   │  └────────────────────────────────────┘  │
                   │  ┌────────────────────────────────────┐  │
                   │  │ Central Resources (100% On-Server):│  │
                   │  │ Shared CPU, RAM, NVMe Disk Storage │  │
                   │  └────────────────────────────────────┘  │
                   ============================================
```

---

### 🏬 Real-World Analogy: The Central Super-Computer

Imagine a large **Corporate Computer Center**:

* **Traditional Method (Expensive & Risky):**  
  A company with 100 employees buys 100 high-end laptops ($1,500 each) and manually installs heavy software (Oracle, DBeaver, Visual Studio, Accounting systems) on all 100 laptops. If an employee loses their laptop, company data is stolen. If software needs patching, IT must touch 100 machines.
* **Terminal Server Method (Smart & Centralized):**  
  The company buys **ONE powerful Windows Server host** and installs the software **ONCE**. Employees use inexpensive laptops or thin clients to connect remotely via Remote Desktop (`mstsc`).  
  The server processes 100% of the computations in its own RAM and CPU, and merely streams keyboard/mouse inputs and visual pixels back to the clients!

---

### 🛡️ Why Enterprises Deploy Terminal Server (RDS)

| Benefit | Technical Rationale & Impact |
|:---|:---|
| 💰 **Massive Hardware Savings** | Low-cost thin clients, older PCs, and tablets can run heavy applications without needing expensive hardware. |
| 🔒 **Absolute Data Protection** | Data **NEVER leaves the server room**. All databases, files, and memory remain on `192.168.1.10`. Client theft results in zero data loss. |
| ⚡ **Single-Point Administration** | Software installations, updates, security patches, and database drivers are configured **once on the server** and instantly available to all domain users. |
| 🌐 **Seamless Remote Work** | Remote employees can access internal network tools securely over RDP (Port `3389`) or through a web browser using HTTPS (Port `443`). |

---

## 🧱 Core Roles & Components of Remote Desktop Services

### 🔍 Detailed Breakdown of the 6 RDS Role Services

#### 1. 🖥️ Remote Desktop Session Host (RDSH) — The Engine
* 🎯 **What it is:** The core workhorse of Terminal Server. It allows multiple users to log into the Windows Server simultaneously and run full desktop sessions or apps.
* 🏨 **Analogy:** The **Hotel Rooms** where users actually sit, work, and use applications.
* 👉 **Do we select it?** ✅ **YES! (Mandatory)** — Terminal Server cannot function without this.

#### 2. 🎫 Remote Desktop Licensing (RD Licensing) — The Ticket Validator
* 🎯 **What it is:** Manages and tracks RDS Client Access Licenses (CALs) for users or computers connecting to the server.
* 🎟️ **Analogy:** The **Ticket Booth / Cashier** checking entrance tickets.
* 💡 **Note:** Windows Server gives you a **120-day free evaluation grace period**, so you don't need to buy licenses to test and practice!
* 👉 **Do we select it?** ✅ **YES!**

#### 3. 🌐 Remote Desktop Web Access (RD Web Access) — The Web Portal
* 🎯 **What it is:** Creates a web portal (`https://192.168.1.10/RDWeb`) where users can open a web browser on their client machine (Chrome, Edge) and launch RemoteApps with 1 click!
* 💻 **Analogy:** The **Online Booking / Web Catalog** of applications.
* 👉 **Do we select it?** ✅ **YES!** (Great for testing browser and RemoteApp features).

#### 4. 🧭 Remote Desktop Connection Broker (RDCB) — The Traffic Director
* 🎯 **What it is:** In an enterprise with multiple terminal servers, the Connection Broker balances incoming connections (load balancing) and reconnects users to their existing disconnected sessions.
* 🛎️ **Analogy:** The **Hotel Front Desk Concierge** who checks which room you were staying in and gives you back your existing room key.
* 👉 **Do we select it?** ⚪ *Optional for single-server labs, but can be added if managing multi-server farms.*

#### 5. 🛡️ Remote Desktop Gateway (RD Gateway) — The Internet Firewall Tunnel
* 🎯 **What it is:** Encapsulates standard RDP (Port 3389) traffic inside secure HTTPS (Port 443) so users from home/internet can connect securely through firewalls without needing a VPN.
* 🛂 **Analogy:** The **Airport Passport Control / Security Checkpoint** for guests arriving from outside the country.
* 👉 **Do we select it?** ❌ *Not needed for our local private LAN (`VMnet8`).*

#### 6. 💻 Remote Desktop Virtualization Host (RDVH) — VDI Host
* 🎯 **What it is:** Used for Virtual Desktop Infrastructure (VDI) with Hyper-V, where each user gets their own dedicated Windows 10/11 virtual machine instead of sharing the server OS session.
* 📦 **Analogy:** Renting a separate private house for each guest rather than rooms in a shared building.
* 👉 **Do we select it?** ❌ *Not needed (we are doing session-based Terminal Server).*

---

### 📋 Summary: What to Check on the Server Manager Screen

Check these **3 boxes**:
* ✅ **Remote Desktop Session Host** *(When prompted, click **Add Features**)*
* ✅ **Remote Desktop Licensing**
* ✅ **Remote Desktop Web Access** *(When prompted, click **Add Features**)*

---

## 🚀 The 3 Delivery Methods of RDS

```
                     RDS APPLICATION DELIVERY MODES
                     
  1. Full Desktop Session        2. RemoteApp Program         3. RD Web Access Portal
     (mstsc.exe)                    (Seamless App Window)        (HTTPS Web Browser)
     
  ┌───────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
  │ Windows Server 2022   │      │ DBeaver [RemoteApp] │      │ https://.../RDWeb   │
  │ [Start] [Taskbar]     │      │ File Edit SQL ...   │      │ [Icons for Apps]    │
  │ Complete Desktop OS   │      │ Blends into Client  │      │ Launch via Browser  │
  └───────────────────────┘      └─────────────────────┘      └─────────────────────┘
```

| Method | How it Works | Best Used For |
|:---|:---|:---|
| 🖥️ **Full Desktop Session** | User connects via `mstsc` and receives a complete remote desktop with Windows desktop, taskbar, and Start menu. | Administrators, heavy users needing multiple simultaneous server tools. |
| 🚀 **RemoteApp** | Only the specific application window opens on the client machine, blending seamlessly into the client's local desktop without showing the server OS. | End-users who only need 1 or 2 specific enterprise apps (e.g. DBeaver, Accounting). |
| 🌐 **RD Web Access** | Web-based portal (`https://<Server_IP>/RDWeb`) accessible via any modern browser with single sign-on. | Work-from-home users, BYOD (Bring Your Own Device), cross-platform access. |

---

## ⚙️ Step-by-Step Implementation Guide

### Phase 1: Install Remote Desktop Services Roles

On **`pro-win-server` (`192.168.1.10`)**:

1. Open **Server Manager** → click **Manage** (top right) → select **Add Roles and Features**.
2. On **Installation Type**:
   * Choose **Role-based or feature-based installation** (or *Remote Desktop Services installation* for quick setup).
3. On **Server Selection**: Select `WIN-J17IMHCEMA9.e6.local` (`192.168.1.10`).
4. On **Server Roles**:
   * Scroll down and check **Remote Desktop Services** → click **Next**.
5. On **Role Services** under Remote Desktop Services, select:
   * ✅ **Remote Desktop Session Host (RDSH)** *(Prompts to add features → click Add Features)*
   * ✅ **Remote Desktop Licensing**
   * ✅ **Remote Desktop Web Access (RD Web Access)** *(Optional but recommended for web portal)*
6. Click **Next** → Click **Install**!
7. ⚠️ **Reboot Required:** When installation completes, click **Close** and restart the server (`shutdown /r /t 0`).

---

### Phase 2: Authorize Domain Users for Remote Desktop Access

By default, only domain administrators (`E6\Administrator`) can log in via Remote Desktop. Standard domain users (like `s.pengseang`) must be granted access.

#### Method A: Via Active Directory Users and Computers (`dsa.msc`)
1. Open **Active Directory Users and Computers** on `pro-win-server`.
2. Expand `e6.local` → click **Builtin** folder.
3. Double-click the security group **Remote Desktop Users**.
4. Click **Members** tab → click **Add...**.
5. Type **`s.pengseang`** (or **`Domain Users`** to allow all company employees) → click **Check Names** → click **OK**.
6. Click **Apply** → click **OK**!

#### Method B: Via PowerShell (Fast ⚡)
```powershell
Add-ADGroupMember -Identity "Remote Desktop Users" -Members "s.pengseang"
```

---

### Phase 3: Configure Windows Firewall for Remote Desktop (Port 3389)

On **`pro-win-server`**, open **PowerShell as Administrator** and run:

```powershell
# Enable Remote Desktop Firewall Rules
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Verify Port 3389 Listener is listening
Get-NetTCPConnection -LocalPort 3389 -State Listen
```

---

### Phase 4: Configure Group Policy for RDS Sessions (GPO)

To prevent disconnected or idle sessions from wasting server RAM and CPU memory, configure Group Policy session timeout rules:

1. Open **Group Policy Management (`gpmc.msc`)** on `pro-win-server`.
2. Create or edit a GPO linked to `Domain` or `Computer OU` (e.g. `RDS_Session_Policy`).
3. Navigate to:
   ```text
   Computer Configuration
   └── Policies
       └── Administrative Templates
           └── Windows Components
               └── Remote Desktop Services
                   └── Remote Desktop Session Host
                       ├── Connections
                       │   └── Restrict Remote Desktop Services users to a single Remote Desktop Services session ──► Enabled
                       └── Session Time Limits
                           ├── Set time limit for disconnected sessions ──► Enabled (e.g. 1 hour)
                           └── Set time limit for active but idle Remote Desktop Services sessions ──► Enabled (e.g. 30 minutes)
   ```
4. Run `gpupdate /force` to apply immediately.

---

## 🧪 Comprehensive Verification & Testing Suite

Execute these 3 verification tests to confirm your Terminal Server deployment is 100% operational:

### 🧪 Test 1: Direct Remote Desktop Connection (`mstsc`)

From **`pro-win-client` (`192.168.1.100`)**:

1. Press **`Win + R`** → type **`mstsc`** → press **Enter**.
2. In the **Computer** field, enter:
   ```text
   192.168.1.10
   ```
   *(or `server1.e6.local`)*
3. Click **Connect**.
4. When prompted for credentials, log in as:
   * **Username:** `E6\s.pengseang`
   * **Password:** `abc@123`
5. ✅ **Verification Result:** The remote Windows Server desktop opens smoothly, proving the RDSH session host and user authentication are fully functioning!

---

### 🧪 Test 2: Verify Active Remote Sessions on Server

On **`pro-win-server`**, open **Command Prompt (Admin)** or **PowerShell** and run:

```cmd
query session
```

Expected Output:
```text
 SESSIONNAME       USERNAME                 ID  STATE   TYPE        DEVICE
 services                                    0  Disc
 console           Administrator             1  Active
>rdp-tcp#0         s.pengseang               2  Active
 rdp-tcp                                 65536  Listen
```

* 🟢 **Status:** User `s.pengseang` is actively connected via session `rdp-tcp#0`!

---

### 🧪 Test 3: RD Web Access Portal Test (Browser Access)

From **`pro-win-client`**:

1. Open web browser (Chrome, Edge, or Internet Explorer).
2. Navigate to:
   ```text
   https://192.168.1.10/RDWeb
   ```
   *(or `https://server1.e6.local/RDWeb`)*
3. Bypass certificate warning (click *Advanced → Proceed to 192.168.1.10*).
4. Log in with domain credentials (`E6\s.pengseang` / `abc@123`).
5. ✅ **Verification Result:** The RD Web Access application portal loads with published icons!

---

## 🔧 Troubleshooting & Known Issues

| Symptom / Error | Root Cause | Exact Resolution |
|:---|:---|:---|
| **"The connection was denied because the user account is not authorized"** | User `s.pengseang` is not in the `Remote Desktop Users` group. | Add user to group via `dsa.msc` or run `Add-ADGroupMember -Identity "Remote Desktop Users" -Members "s.pengseang"`. |
| **"Remote Desktop can't connect to the remote computer"** | Firewall Port 3389 blocked or Remote Desktop disabled in System Properties. | In Server Manager → Local Server → Enable **Remote Desktop**; run `Enable-NetFirewallRule -DisplayGroup "Remote Desktop"`. |
| **Network Level Authentication (NLA) CredSSP Error** | Client OS and Server OS have mismatched NLA encryption settings. | In System Properties → Remote tab → uncheck *"Allow connections only from computers running Remote Desktop with NLA"* for testing. |
| **Licensing Grace Period Warning** | RDS has a 120-day evaluation period before requiring a licensed RD Licensing Server. | Windows Server provides 120 days of unlimited free testing without a License Server. |

---

## 📊 Summary of Master Server Roles Completed

| # | Server Role | Status | Documentation File |
|:---:|:---|:---:|:---|
| 1 | **DHCP & DNS Core Network** | ✅ Complete | [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md) |
| 2 | **File Server & FTP Storage** | ✅ Complete | [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md) |
| 3 | **Web Server (IIS + Next.js + PM2)** | ✅ Complete | [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md) |
| 4 | **Database Server (Oracle 19c & PostgreSQL)** | ✅ Complete | [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md) |
| 5 | **Terminal Server (Remote Desktop Services - RDS)** | 🚀 Ready to Execute | [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md) |
