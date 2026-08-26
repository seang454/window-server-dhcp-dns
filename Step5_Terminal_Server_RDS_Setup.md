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

### 🔍 Exhaustive Deep-Dive: The 6 RDS Role Services Architecture

```
                    MASTER RDS ENTERPRISE COMPONENT MAP
                    
   [ CLIENT TIER ]                                    [ SERVER TIER ]
   
   🌐 Web Browser ───────────► TCP 443 (HTTPS) ────► 🌐 RD Web Access (IIS / RDWeb)
   (Chrome/Edge)                                            │
                                                            │ Internal App Catalog
                                                            ▼
   💻 mstsc.exe ─────────────► TCP 3389 (RDP) ─────► 🧭 RD Connection Broker (RDCB)
   (RDP Client)                                             │
                                                            ├─► 🎫 RD Licensing Server (CAL)
                                                            │   (Validates User/Device tokens)
                                                            │
                                                            ▼ Session Routing / Reconnection
                                                    ┌───────────────────────────────┐
                                                    │ 🖥️ RD Session Host (RDSH)      │
                                                    │   (Hosts Windows Sessions,    │
                                                    │    Apps, RAM, CPU & Storage)  │
                                                    └───────────────────────────────┘
                                                            ▲
   🌍 Remote Worker ─────────► TCP 443 (HTTPS) ────► 🛡️ RD Gateway (DMZ Perimeter)
   (Public Internet)                                    (Bypasses VPN / Encapsulates RDP)
```

---

#### 1. 🖥️ Remote Desktop Session Host (RDSH) — *The Compute Engine & Execution Workhorse*

* **Official Full Name:** Remote Desktop Session Host
* **Core Function:** The fundamental compute engine of Windows Terminal Server. It allows a single Windows Server instance to create, isolate, and maintain multiple concurrent interactive user sessions in kernel memory. Users run full Windows desktops or individual applications directly against the server's CPU, RAM, and disk storage.

##### ⚙️ Under the Hood Technical Mechanism:
* **Windows Service Name:** `TermService` (Remote Desktop Services)
* **Underlying Executable & DLL:** `C:\Windows\System32\svchost.exe -k NetworkService` loading `C:\Windows\System32\termsrv.dll`
* **Kernel Driver:** `termdd.sys` (Terminal Server Device Driver) and `rdpdr.sys` (RDP Device Redirector for printers, drives, and clipboards)
* **Network Listener & Port:** TCP `3389` (Standard RDP) and UDP `3389` (RDP 8.0+ RemoteFX transport for high-frame-rate video and audio streaming)
* **Session Isolation Mechanism:** Every connecting user is assigned a unique Windows Session ID (e.g., Session 0 = OS System Services; Session 1 = Console Administrator; Session 2 = `s.pengseang`). Each session maintains its own private desktop heap, private registry hive (`HKEY_CURRENT_USER`), and isolated process space (`csrss.exe` and `winlogon.exe` instance per user).

##### 🏨 Real-World Analogy:
Think of RDSH as a **High-Rise Apartment Building**:
Each resident (user) rents an apartment (Session ID). Every resident gets their own private living room, furniture, and closet (user profile, desktop, registry), but they all share the building's central foundation, electricity, plumbing, and air conditioning (server CPU, RAM, and hardware).

##### 🏢 Enterprise Use Case:
A corporate call center or branch office with 500 agents. Instead of deploying 500 expensive physical desktops with localized software installations, agents log into a pool of 5 RDSH servers. When an application like DBeaver or SAP needs patching, the sysadmin applies the patch once on the RDSH server, instantly updating all 500 workers.

##### 📋 Lab Verdict:
👉 **MANDATORY (Must Select ✅):** Terminal Server cannot exist without RDSH. It is the actual server that executes your programs.

---

#### 2. 🎫 Remote Desktop Licensing (RD Licensing) — *The Ticket Booth & Compliance Auditor*

* **Official Full Name:** Remote Desktop Licensing Service
* **Core Function:** Issues, records, and manages Remote Desktop Services Client Access Licenses (RDS CALs). It ensures legal compliance with Microsoft licensing terms whenever users or client devices establish connections to RDSH.

##### ⚙️ Under the Hood Technical Mechanism:
* **Windows Service Name:** `TermServLicensing` (Remote Desktop Licensing)
* **Underlying Executable:** `C:\Windows\System32\lserver.exe`
* **Management Consoles:** `licmgr.exe` (Remote Desktop Licensing Manager) and `lsdiag.msc` (RD Licensing Diagnoser)
* **Network Communication:** Uses RPC (Remote Procedure Call) over TCP Port `135` and dynamically negotiated high ports (TCP `49152-65535`) to communicate with RD Session Hosts.
* **Licensing Modes Supported:**
  1. **Per-User CAL:** The license is permanently tied to an Active Directory user account (`e6\s.pengseang`). That user can connect to RDS from unlimited devices (laptop, home PC, phone, tablet) using 1 license.
  2. **Per-Device CAL:** The license is physically tied to the client machine's hardware certificate. Any number of employees (shift workers) can share the same physical computer to connect to RDS.
* **Evaluation Grace Period:** Windows Server includes a built-in **120-day evaluation grace period** (`Licensing Grace Period`). During this 120-day window, RDSH permits unlimited concurrent user connections without requiring active CAL keys or a registered license server.

##### 🎟️ Real-World Analogy:
Think of RD Licensing as the **Box Office & Ticket Validator at a Movie Theater**:
RDSH is the movie theater room showing the film. RD Licensing is the cashier booth at the entrance checking whether you have a valid ticket (CAL) before letting you into the auditorium.

##### 🏢 Enterprise Use Case:
A hospital with 1,000 nurses working 3 rotating shifts on 300 hospital workstations. The hospital deploys **Per-Device CALs** on the RD Licensing Server so that nurses on all 3 shifts can use the 300 workstations without buying 1,000 separate user licenses.

##### 📋 Lab Verdict:
👉 **RECOMMENDED (Select ✅):** Allows you to explore the Licensing Manager tool and examine the 120-day grace period behavior.

---

#### 3. 🌐 Remote Desktop Web Access (RD Web Access) — *The Web Application Portal*

* **Official Full Name:** Remote Desktop Web Access
* **Core Function:** Deploys a secure web application portal hosted inside Microsoft IIS (`https://<Server_Name>/RDWeb`). Domain users open Chrome, Edge, or Firefox, log in with Active Directory credentials, and view a customized catalog of published RemoteApps and Remote Desktops with one-click browser launching.

##### ⚙️ Under the Hood Technical Mechanism:
* **Web Engine:** Microsoft Internet Information Services (IIS) 10.0
* **Physical Directory on Disk:** `C:\Windows\Web\RDWeb\`
  * `C:\Windows\Web\RDWeb\Pages\` (ASP.NET scripts, `default.aspx`, web configuration)
  * `C:\Windows\Web\RDWeb\App_Data\` (XML application feeds)
* **IIS Application Pool:** `RDWebAccess` running under `W3WP.exe`
* **Network Protocol & Port:** TCP `443` (HTTPS with SSL/TLS encryption) and TCP `80` (HTTP redirect)
* **How It Works Under the Hood:** When a user clicks an application icon on `/RDWeb`, the server dynamically generates a signed `.rdp` file on the fly and streams it to the browser. The browser's RDP client helper immediately launches the application in a seamless, borderless window!

##### 💻 Real-World Analogy:
Think of RD Web Access as an **Enterprise App Store / Netflix Catalog for Company Software**:
Instead of opening command prompts or remembering server IP addresses and port numbers, employees visit a clean web page, see friendly icons for "DBeaver", "Oracle SQL Developer", and "Accounting", and click to launch them instantly.

##### 🏢 Enterprise Use Case:
A university or enterprise with BYOD (Bring Your Own Device) policies. Students or contractors working from MacBooks, Chromebooks, or personal Windows PCs log into `https://portal.university.edu/RDWeb` to use licensed academic software without installing anything on their personal machines.

##### 📋 Lab Verdict:
👉 **RECOMMENDED (Select ✅):** Allows client testing from web browsers and demonstrates modern RemoteApp delivery.

---

#### 4. 🧭 Remote Desktop Connection Broker (RDCB) — *The Traffic Director & Session Reconnector*

* **Official Full Name:** Remote Desktop Connection Broker
* **Core Function:** Acts as the central traffic controller, load balancer, and state database for multi-server RDS farms. When users connect, RDCB evaluates server load across all RDSH nodes, routes the connection to the least-utilized server, and tracks active/disconnected sessions so users never lose unsaved work.

##### ⚙️ Under the Hood Technical Mechanism:
* **Windows Service Name:** `Tssdis` (Remote Desktop Connection Broker)
* **Database Backend:** In single-broker setups, it stores session state in an embedded Windows Internal Database (WID). In enterprise high-availability setups, it synchronizes across multiple brokers using a dedicated Microsoft SQL Server database.
* **Network Port:** TCP `135` (RPC Endpoint Mapper) and dynamic high RPC ports.
* **Core Features:**
  * **Session Reconnection / State Persistence:** If user `s.pengseang` is writing a complex SQL script on Server 2 and their Wi-Fi drops, their session remains running in RAM. When they reconnect 5 minutes later, RDCB checks its state database, bypasses Server 1, and reconnects the user back to Server 2 right where they left off with zero data loss!
  * **Session Load Balancing:** Uses round-robin or session-weight metrics to distribute incoming logins across 10 session host servers evenly.

##### 🛎️ Real-World Analogy:
Think of RDCB as the **Hotel Front Desk Manager**:
When you check in, the front desk looks at which rooms are vacant and gives you a key. If you leave the hotel to go to dinner and return later, the front desk does not assign you a random new room—they look up your reservation and send you straight back to your original room with all your luggage intact!

##### 🏢 Enterprise Use Case:
An enterprise with 2,000 employees connecting to a farm of 15 RDSH servers. The Connection Broker ensures no single server gets overwhelmed with CPU load, and guarantees that disconnected sessions are seamlessly restored.

##### 📋 Lab Verdict:
👉 **OPTIONAL / ADVANCED (Leave Unchecked ❌ for simple role-based installs):** In single-server standalone mode, RDSH handles direct connections without a broker. A connection broker is primarily utilized in multi-server farm deployments.

---

#### 5. 🛡️ Remote Desktop Gateway (RD Gateway) — *The Secure Internet Perimeter Tunnel*

* **Official Full Name:** Remote Desktop Gateway
* **Core Function:** Enables authorized external remote users across the public Internet to connect securely to internal network RD Session Hosts and desktops without configuring a VPN (Virtual Private Network).

##### ⚙️ Under the Hood Technical Mechanism:
* **Windows Service Name:** `RpcProxy` (Remote Desktop Gateway Service) / `NPAS` (Network Policy and Access Services)
* **Network Protocol & Port:** Encapsulates raw RDP packets (Port 3389) inside standard **HTTPS (Port 443 TCP/UDP)** using TLS encryption.
* **Security Integration:**
  * **RAP (Resource Authorization Policies):** Restricts which specific internal computers an external user is allowed to connect to.
  * **CAP (Connection Authorization Policies):** Restricts who can authenticate (e.g., requires Multi-Factor Authentication / Smart Cards).
* **Why Port 3389 is Never Exposed to the Internet:** Exposing port 3389 directly to the public internet attracts thousands of brute-force botnet attacks per second. RD Gateway terminates connections at the DMZ firewall on Port 443, authenticates the user, and proxies the traffic internally.

##### 🛂 Real-World Analogy:
Think of RD Gateway as the **Airport International Customs & Passport Control**:
Foreign travelers arriving from outside the country cannot just walk straight into the city streets. They must pass through the secure airport terminal gate (Port 443), present their verified passport (CAP/RAP policies), and only then are they permitted inside the country.

##### 🏢 Enterprise Use Case:
Work-from-home employees connecting to their office desktop PCs from home without needing to install or connect to a corporate Cisco/Fortinet VPN client.

##### 📋 Lab Verdict:
👉 **NOT NEEDED (Skip ❌):** Our lab operates entirely on a private offline internal network (`VMnet8`: `192.168.1.0/24`), so an internet perimeter gateway is unnecessary.

---

#### 6. 💻 Remote Desktop Virtualization Host (RDVH) — *The VDI Hyper-V Hypervisor*

* **Official Full Name:** Remote Desktop Virtualization Host
* **Core Function:** Integrates Remote Desktop Services with Microsoft Hyper-V to manage and deliver **Virtual Desktop Infrastructure (VDI)**. Instead of sharing a server operating system session, each user is given their own dedicated virtual machine running client Windows (Windows 10 or Windows 11 Enterprise).

##### ⚙️ Under the Hood Technical Mechanism:
* **Prerequisites:** Requires the **Hyper-V** hypervisor role installed on bare-metal hardware with hardware-assisted virtualization (Intel VT-x or AMD-V).
* **Virtual Machine Pools:**
  1. **Pooled VDI Desktops:** Users receive a temporary, pristine Windows 10 VM clone from a master gold image. When they log off, all changes are discarded, and the VM rolls back to its original state.
  2. **Personal VDI Desktops:** Each user is permanently assigned their own dedicated VM with full administrator rights where they can install custom software and retain changes indefinitely.

##### 📦 Real-World Analogy:
Think of RDVH as **Renting a Standalone Private House** vs. RDSH which is **Sharing an Apartment Building**:
In RDSH (Session Host), all users share the same kitchen, plumbing, and roof (server operating system). In RDVH (VDI), every user gets their own completely detached private house with its own walls, roof, and foundation (individual dedicated VM).

##### 🏢 Enterprise Use Case:
Software developers, CAD engineers, or compliance officers who require full local administrator rights, custom kernel drivers, or total operating system isolation that cannot be permitted in a shared server session environment.

##### 📋 Lab Verdict:
👉 **NOT NEEDED (Skip ❌):** Running Hyper-V inside a VMware Workstation virtual machine creates nested virtualization overhead, and our goal is session-based Terminal Server.

---

### 📊 Master Comparison Matrix of All 6 RDS Roles

| Role Service | Abbr | Primary Protocol & Port | Analogy | Multi-Server Farm? | Lab Status |
|:---|:---:|:---:|:---|:---:|:---:|
| **Remote Desktop Session Host** | **RDSH** | TCP/UDP `3389` | 🏨 Hotel Rooms (Compute) | Yes | ✅ **REQUIRED** |
| **Remote Desktop Licensing** | **RD Licensing** | TCP `135` / RPC | 🎫 Ticket Booth (CALs) | Yes | ✅ **SELECTED** |
| **Remote Desktop Web Access** | **RD Web Access** | TCP `443` (HTTPS) | 💻 App Catalog (Browser) | Yes | ✅ **SELECTED** |
| **Remote Desktop Connection Broker** | **RDCB** | TCP `135` / RPC | 🧭 Front Desk Concierge | Mandatory | ⚪ Optional |
| **Remote Desktop Gateway** | **RD Gateway** | TCP/UDP `443` (TLS) | 🛂 Customs Border Checkpoint | External Only | ❌ Skip |
| **Remote Desktop Virtualization Host**| **RDVH** | Hyper-V Bus | 📦 Private Standalone House | VDI Only | ❌ Skip |

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

### Phase 2: Authorize Domain Users for Remote Desktop Access (The 2 Mandatory Steps)

By default, only domain administrators (`E6\Administrator`) can log in via Remote Desktop. To grant domain users remote access on a Domain Controller, **two mandatory steps** must be completed.

---

#### 🛠️ Step 2A: Add `Domain Users` to `Remote Desktop Users` Builtin Group

Instead of adding individual users, we follow enterprise best practices by adding the entire **`Domain Users`** group:

##### Method A: Via Active Directory Users and Computers (`dsa.msc`)
1. Open **Active Directory Users and Computers (`dsa.msc`)** on `pro-win-server`.
2. Expand `e6.local` ──► click **Builtin** folder.
3. Double-click the security group **`Remote Desktop Users`**.
4. Click **Members** tab ──► click **Add...**.
5. Type **`Domain Users`** *(or `s.pengseang` for single-user testing)* ──► click **Check Names** ──► click **OK**.
6. Click **Apply** ──► click **OK**!

##### Method B: Via PowerShell (Instant ⚡)
```powershell
Add-ADGroupMember -Identity "Remote Desktop Users" -Members "Domain Users"
```

##### 🏢 Deep-Dive: Why Enterprise IT Uses Groups Instead of Individual Users (AGDLP Principle)

In enterprise Active Directory environments, administrators **never** assign permissions to individual user accounts (`s.pengseang`, `alice`, `john`):

1. **The Individual User Nightmare ❌:** If a company has 500 employees, adding individual users means modifying policies 500 times. When employees leave or transfer, IT must clean up hundreds of scattered permissions.
2. **The Group-Based Power (`Domain Users`) ✅:** Adding **`Domain Users`** means every existing and newly hired employee instantly inherits Remote Desktop access automatically upon account creation!
3. **The Gold Standard (AGDLP Role-Based Access) 🏆:** In large enterprises where only specific departments need RDP, sysadmins create a global group `RDS_Allowed_Users`, nest it inside `Remote Desktop Users`, and manage membership dynamically.

| Method | Enterprise Rating | When to Use |
|:---|:---:|:---|
| Add individual user (`s.pengseang`) | ❌ **Poor Practice** | Only for quick temporary single-user tests. |
| Add **`Domain Users`** | ✅ **Great Practice** | When all company employees should have remote access. |
| Add custom role group (`RDS_Allowed_Users`) | 🏆 **Gold Standard** | When only specific departments should have remote access. |

---

#### 🛡️ Step 2B: Allow `Remote Desktop Users` in Domain Controller GPO User Rights Assignment

##### ❓ Why is Step 2B Strictly Required on a Domain Controller?
On a standard Windows member server, Step 2A is enough. **HOWEVER**, because `pro-win-server` is an **Active Directory Domain Controller**, Microsoft enforces an additional security lock:
> ⚠️ On a Domain Controller, the security policy **"Allow log on through Remote Desktop Services"** by default **ONLY grants access to `Administrators`**! If this step is skipped, users receive:  
> *"To sign in remotely, you need the right to sign in through Remote Desktop Services..."*

##### 🛠️ Step-by-Step Configuration in `gpmc.msc`:
1. On `pro-win-server`, press **`Win + R`** ──► type **`gpmc.msc`** ──► press **Enter**.
2. Expand:
   ```text
   Forest: e6.local
   └── Domains
       └── e6.local
           └── Domain Controllers
   ```
3. Right-click **`Default Domain Controllers Policy`** ──► click **Edit**.
4. In the Group Policy Management Editor, navigate to:
   ```text
   Computer Configuration
   └── Policies
       └── Windows Settings
           └── Security Settings
               └── Local Policies
                   └── User Rights Assignment
   ```
5. In the right pane, find and double-click:  
   👉 **"Allow log on through Remote Desktop Services"**
6. Click **Add User or Group...** ──► click **Browse...**.
7. Type: **`Remote Desktop Users`** ──► click **Check Names** ──► click **OK** ──► click **OK**.
8. Click **Apply** ──► click **OK**!
9. Close the Group Policy Editor.
10. In Command Prompt or PowerShell, enforce the policy immediately:
    ```cmd
    gpupdate /force
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

To prevent disconnected or idle sessions from wasting server RAM and CPU memory, configure Group Policy session timeout rules.

#### ❓ Deep-Dive Architecture Question: Where do we create and link this GPO, and WHY?

👉 **Recommendation:** Link the GPO to the **`Domain Controllers` OU** (or to the Domain root **`e6.local`**).

```
                      ACTIVE DIRECTORY OBJECT HIERARCHY
                      
  e6.local (Domain Root)
   ├── 📁 Domain Controllers (OU)  ──► 🖥️ WIN-J17IMHCEMA9 (pro-win-server / RDS Host) ◄── [LINK GPO HERE!]
   └── 📁 Computers (CN Container) ──► 💻 CLIENT (pro-win-client / User Laptop)
```

##### 🔍 The 2 Critical Technical Reasons:

1. 🖥️ **Reason 1: The Terminal Server is INSIDE `Domain Controllers`!**
   * Ask: *Which machine is actually hosting the remote desktop sessions?* ──► **The Server (`WIN-J17IMHCEMA9`)!**
   * The GPO settings we are configuring (*"Disconnect idle sessions after 30 minutes"*, *"Restrict users to 1 session"*) are **SERVER-SIDE rules** that control the server's CPU, RAM, and session tables.
   * If you tried to apply this policy to the client machine (`Computers`), the client PC would ignore it because it does not run the Terminal Server engine. Meanwhile, the server (`WIN-J17IMHCEMA9`) would **never receive the policy** because it lives in the `Domain Controllers` OU!

2. 🚫 **Reason 2: Active Directory CANNOT link GPOs to the default `Computers` folder!**
   * In Active Directory architecture:
     * **`Domain Controllers`** is an **OU** (`Organizational Unit`).
     * **`Computers`** is a **Default System Container** (`CN=Computers`), **NOT an OU**!
   * 🛡️ **Fundamental Active Directory Rule:** Group Policies can **ONLY** be linked to **Sites, Domains, and OUs**. Active Directory does not permit linking a GPO directly to default system containers like `CN=Computers` or `CN=Users` (in `gpmc.msc`, `Computers` doesn't even have a link option!).

---

#### 🛠️ Step-by-Step Configuration in `gpmc.msc`:

1. Open **Group Policy Management (`gpmc.msc`)** on `pro-win-server`.
2. Expand:
   ```text
   Forest: e6.local
   └── Domains
       └── e6.local
   ```
3. Right-click **`Domain Controllers`** (or right-click **`e6.local`**).
4. Select: **"Create a GPO in this domain, and Link it here..."**.
5. Name the GPO: **`RDS_Session_Policy`** ──► click **OK**.
6. Right-click **`RDS_Session_Policy`** ──► click **Edit**.
7. Navigate to:
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
8. Close the Group Policy Editor window.
9. In PowerShell or Command Prompt, run:
   ```cmd
   gpupdate /force
   ```

---

#### 💡 Deep-Dive: What Do These 3 Policies Do & Why Are They Essential?

```
                     RDS SESSION LIFECYCLE & POLICY TIMELINE
                     
  [ User Logs In ] ──► [ Active Working Session ]
                              │
                              ├─► User leaves desk (No mouse/keyboard input for 30m)
                              │   ▼
                              │  ⏳ [ Idle Timeout Reached (30m) ] ──► Policy disconnects session
                              │
                              └─► User closes RDP window directly (X button) without logging off
                                  ▼
                                 🔌 [ Session is Disconnected ]
                                    (Apps like DBeaver stay open in server RAM)
                                    │
                                    ├─► User logs in again within 1 hour ──► Reconnected to existing session!
                                    │
                                    └─► 1 hour passes without reconnecting
                                        ▼
                                       🛑 [ Disconnected Timeout Reached (1h) ]
                                          ──► Session is TERMINATED & RAM memory is freed!
```

---

##### 1. 🔒 Restrict Remote Desktop Services users to a single session
* **What it does:** Ensures each domain user account (e.g. `s.pengseang`) can have **ONLY ONE** active session on the server at any given time.
* **Without this policy (The Problem):**  
  If user `s.pengseang` connects from their office PC, then connects from a laptop in a conference room, and later connects from home, Windows Server creates **3 separate, simultaneous desktop sessions** for that same user! Each session consumes 500MB–1GB of server RAM and locks file handles.
* **With this policy (The Solution):**  
  When `s.pengseang` connects from their laptop, the server automatically **reconnects them to their existing running session**, bringing their open windows with them, rather than spinning up a new session!

---

##### 2. 🔌 Set time limit for disconnected sessions (e.g. 1 Hour)
* **What it does:** Automatically logs off and terminates sessions that have been abandoned or disconnected for more than the specified duration (e.g. 1 hour).
* **Without this policy (The Problem):**  
  Most users simply click the **"X" (close)** button on their RDP client window at the end of the workday instead of clicking *Start ──► Sign Out*. The session remains running in the server's RAM forever! Over weeks, 50 abandoned sessions accumulate ("ghost sessions"), eventually exhausting all server memory and crashing the server!
* **With this policy (The Solution):**  
  If a user disconnects their network or clicks "X", Windows Server keeps their session alive for 1 hour (in case their Wi-Fi dropped or they just rebooted their laptop). If they don't return within 1 hour, the server gracefully closes the background processes and releases the RAM back to the operating system!

---

##### 3. ⏳ Set time limit for active but idle sessions (e.g. 30 Minutes)
* **What it does:** Detects when a remote session has had **zero keyboard or mouse interaction** for the specified time limit (e.g. 30 minutes) and changes the session state from `Active` to `Disconnected`.
* **Security & Resource Benefit:**  
  * **Physical Security:** If an employee walks away from their client desk to go to lunch without locking their screen, an unauthorized person could access sensitive company databases. After 30 minutes of inactivity, the session locks/disconnects!
  * **Resource Preservation:** Idle sessions holding database locks or heavy queries are paused so other working employees get full CPU priority.

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
