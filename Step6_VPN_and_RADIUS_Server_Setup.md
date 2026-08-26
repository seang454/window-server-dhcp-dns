# Step 6: VPN Server (RRAS) & RADIUS Server (NPS) Setup & Deployment Guide

**Windows Server 2022 on VMware Workstation**  
**Domain:** `e6.local`  
**Server Hostname:** `WIN-J17IMHCEMA9` (`server1.e6.local`)  
**Server IP:** `192.168.1.10`  
**Client VM:** `CLIENT` (`pro-win-client` at `192.168.1.100`)  
**Services:** Routing and Remote Access (RRAS) + Network Policy Server (NPS)  
**Protocols & Ports:**  
* **RADIUS Authentication:** UDP `1812` (Auth), UDP `1813` (Accounting)  
* **VPN SSTP:** TCP `443` (HTTPS SSL/TLS Tunnel)  
* **VPN PPTP:** TCP `1723` + GRE Protocol 47  
* **VPN L2TP/IPsec:** UDP `500`, UDP `4500`, UDP `1701`  

---

## 📖 Deep-Dive Concepts & Architecture

### 🛡️ 1. What is a VPN Server (RRAS)?

A **Virtual Private Network (VPN)** server enables remote workers outside the office (at home, in coffee shops, or traveling) to establish a **secure, encrypted network tunnel** over the public Internet into the company's internal private local area network (`192.168.1.0/24`).

* **Windows Component:** **Routing and Remote Access Service (RRAS)**.
* **How it Works:** When a client connects via VPN, the VPN server assigns the client an internal corporate IP address (e.g. `192.168.1.221`). To the client, it behaves as though their laptop is physically plugged into the office network switch with an Ethernet cable!

---

### 🔐 2. What is a RADIUS Server (NPS)?

**RADIUS** stands for **Remote Authentication Dial-In User Service**. It is the global networking standard (RFC 2865 / 2866) for centralized **AAA** security:

1. **Authentication:** *"Who are you? Are your domain username and password valid?"*
2. **Authorization:** *"What are you allowed to do? Are you permitted to connect to the VPN right now?"*
3. **Accounting:** *"When did you connect, how many bytes did you transfer, and when did you disconnect?"*

* **Windows Component:** **Network Policy Server (NPS)**.
* **Role in Enterprise:** Instead of configuring user permissions inside every single Wi-Fi router, VPN server, and firewall independently, all network equipment points to the **central RADIUS Server (NPS)**. NPS checks Active Directory and grants or denies access centrally!

---

### 🗺️ Master Architecture: How RRAS & RADIUS Work Together

```
                  ENTERPRISE VPN + RADIUS ARCHITECTURE
                  
   [ Remote Client ] (pro-win-client)
   IP: 192.168.1.100
         │
         │ 1. Client initiates VPN Connection (Sends Domain Credentials: s.pengseang)
         ▼
   ===============================================================
   │ 🛡️ VPN SERVER (RRAS - Routing & Remote Access)              │
   │    IP: 192.168.1.10                                         │
   ===============================================================
         │
         │ 2. RADIUS Access-Request (UDP Port 1812)
         │    "Is user s.pengseang authorized to connect?"
         ▼
   ===============================================================
   │ 🔐 RADIUS SERVER (NPS - Network Policy Server)               │
   │    IP: 192.168.1.10 (Local or Central Server)               │
   │                                                             │
   │  ┌────────────────────────────────────────────────────────┐ │
   │  │ Checks Active Directory Domain (e6.local):             │ │
   │  │ 1. Password Verification (Kerberos / MS-CHAPv2)        │ │
   │  │ 2. Network Policy (Day/Time restrictions, Group rules)  │ │
   │  │ 3. Dial-in Permission (Allow Access vs NPS Policy)     │ │
   │  └────────────────────────────────────────────────────────┘ │
   ===============================================================
         │
         │ 3. RADIUS Access-Accept (UDP Port 1812)
         │    "Credentials verified! User is allowed."
         ▼
   ===============================================================
   │ 🛡️ VPN SERVER (RRAS)                                        │
   │    • Establishes Encrypted Tunnel                           │
   │    • Assigns Virtual Private IP: 192.168.1.221              │
   ===============================================================
         │
         │ 4. Encrypted Tunnel Established 🟢
         ▼
   [ Remote Client accesses Internal Shares, Databases & Web Servers! ]
```

---

### 🏬 Real-World Analogy: The Secure Corporate Building

Think of a **High-Security Corporate Headquarters**:

* **The Remote Worker:** An employee standing outside the building gate.
* **The VPN Server (RRAS):** The **Heavy Secure Front Door** and private tunnel into the building.
* **The RADIUS Server (NPS):** The **Chief Security Officer with the master badge database**.  
  When the employee knocks on the front door (VPN), the door guard doesn't make the decision. The door guard calls the Chief Security Officer (RADIUS / NPS): *"Employee `s.pengseang` wants to enter. Is their badge valid?"*  
  The Chief Security Officer checks the corporate directory (Active Directory), confirms their clearance, and tells the guard: *"Access Granted! Let them in."*

---

## 🧱 Core VPN Protocols Supported in Windows Server

| VPN Protocol | Port & Transport | Security Level | Enterprise Usage |
|:---|:---:|:---:|:---|
| **SSTP** (Secure Socket Tunneling Protocol) | TCP `443` (SSL/TLS) | 🔒 **Ultra High** | **#1 Choice for Windows.** Traverses firewalls seamlessly because it uses standard HTTPS Port 443! |
| **IKEv2** (Internet Key Exchange v2) | UDP `500`, `4500` | 🔒 **Ultra High** | Modern mobile VPN protocol; supports automatic reconnection when switching networks. |
| **L2TP / IPsec** | UDP `500`, `4500`, `1701` | 🔒 **High** | Cross-platform standard (iOS, Android, Mac, Windows); requires a pre-shared key (PSK). |
| **PPTP** (Point-to-Point Tunneling Protocol) | TCP `1723` + GRE | ⚠️ **Basic / Legacy** | Easiest to configure for offline labs and testing; fast setup without certificate requirements. |

---

## ⚙️ Step-by-Step Implementation Guide

### Phase 1: Install Remote Access (RRAS) & Network Policy Server (NPS) Roles

> [!IMPORTANT]
> 🧭 **The Simple Name Translation Map:**  
> Microsoft uses formal technical names in Server Manager rather than casual names. Here is what to look for:
> 
> | What YOU Call It 🗣️ | What MICROSOFT Calls It in Server Manager 🖥️ |
> |:---|:---|
> | **VPN Server** | 👉 **`Remote Access`** |
> | **RADIUS Server** | 👉 **`Network Policy and Access Services`** |
> 
> 📋 **Quick Visual Checklist (Only 2 Roles!):**
> ```text
>   [✓] Network Policy and Access Services  ──► (RADIUS Server)
>   [✓] Remote Access                       ──► (VPN Server)
>        ├── [✓] DirectAccess and VPN (RAS)
>        └── [✓] Routing
> ```

On **`pro-win-server` (`192.168.1.10`)**:

1. Open **Server Manager** ──► click **Manage** ──► select **Add Roles and Features**.
2. On **Installation Type**: Choose **Role-based or feature-based installation** ──► click **Next**.
3. On **Server Selection**: Select `WIN-J17IMHCEMA9.e6.local` (`192.168.1.10`) ──► click **Next**.
4. On **Server Roles**, select:
   * ✅ **Network Policy and Access Services** *(This is the RADIUS Server!)*
   * ✅ **Remote Access** *(This is the VPN Server!)*
5. Click **Next** through Features.
6. On **Remote Access Role Services**, check:
   * ✅ **DirectAccess and VPN (RAS)** *(When prompted, click **Add Features**)*
   * ✅ **Routing** *(Optional, enables LAN packet routing)*
   * ❌ **Web Application Proxy** *(Leave UNCHECKED)*

---

#### 🔍 Deep-Dive: What is the Difference Between These 3 Role Services?

| Role Service | Layer | What It Actually Does | Do We Need It for VPN? |
|:---|:---:|:---|:---:|
| **1. DirectAccess and VPN (RAS)** | Layer 3 (Network) | **The VPN Engine:** Encrypts and tunnels remote traffic into the internal network. Supports user-dialed VPN (SSTP, PPTP, L2TP, IKEv2) and seamless, always-on corporate DirectAccess. | ✅ **YES! MANDATORY!** *(Without this, there is no VPN!)* |
| **2. Routing** | Layer 3 (Network) | **The Software Router:** Enables IP packet forwarding between the VPN virtual adapter and your LAN. Supports static routes, RIP, NAT, and site-to-site branch office routing. | ✅ **YES! RECOMMENDED!** *(Allows VPN clients to talk to other servers on the LAN).* |
| **3. Web Application Proxy (WAP)** | Layer 7 (Application) | **Reverse Proxy for AD FS:** Sits in DMZ to pre-authenticate external HTTP users against Active Directory Federation Services (AD FS) before accessing internal web apps (SharePoint, Exchange). | ❌ **NO! DO NOT CHECK!** *(Requires AD FS; we already use IIS ARR / Cloudflare).* |

##### 🏢 Real-World Analogy:
* 🛡️ **DirectAccess & VPN (RAS) = The Armored Tunnel:** The secret, encrypted underground tunnel that lets an employee drive their car from home directly into the company parking lot.
* 🚦 **Routing = The Traffic Cop:** Once the employee is in the parking lot, the traffic cop directs their car to the right building (DNS, File Server, Oracle Database).
* 🚪 **Web Application Proxy = The Front Door Bouncer:** A bouncer standing at the public entrance checking badges for visitors accessing web portals (Exchange Outlook Web App, SharePoint).

---

7. Click **Next** ──► click **Install**!
8. When installation finishes, click **Close**.

---

### Phase 2: Configure Routing and Remote Access (RRAS) as a VPN Server

1. In **Server Manager**, click **Tools** (top right) ──► select **Routing and Remote Access**.
2. In the console tree, right-click your server name **`WIN-J17IMHCEMA9 (local)`** ──► select:  
   👉 **"Configure and Enable Routing and Remote Access"**.
3. The Setup Wizard opens ──► click **Next**.
4. On **Configuration**, select:  
   👉 **"Custom configuration"** ──► click **Next**.
5. Check:  
   ✅ **"VPN access"**  
   ✅ **"LAN routing"**  
   Click **Next** ──► click **Finish**!
6. When prompted: *"The Routing and Remote Access service is ready to use. Do you want to start the service?"* ──► click **Start service**!
7. The service will initialize and show a green up-arrow 🟢 next to your server name.

---

#### 🔍 Deep-Dive: Understanding the Wizard Options in Detail

##### 1️⃣ Screen 1: Why Choose "Custom Configuration" Over the Other 4 Options?

| Option | What It Does | Why Admins Avoid It / Why Custom is Better |
|:---|:---|:---|
| **Remote access (dial-up or VPN)** | Wizard-guided setup for VPN | ⚠️ **Requires 2 Physical Network Cards!** If your server only has 1 NIC, the wizard throws an error: *"Less than two network interfaces detected"*. |
| **Network address translation (NAT)** | Turns the server into an internet router | Replaces your home router. Not needed because your Huawei router already handles NAT. |
| **VPN access and NAT** | Combines VPN with NAT internet sharing | Clashes with existing DHCP/NAT setups on single-NIC server environments. |
| **Secure connection between two private networks** | Site-to-Site VPN | Connects two corporate branch offices together permanently (e.g. Phnom Penh office to Siem Reap office). |
| **Custom configuration** ⭐ | **Manual, granular feature selection** | 🏆 **The Enterprise Standard!** Works flawlessly with 1 network card, bypasses wizard assumptions, and gives you 100% control! |

---

##### 2️⃣ Screen 2: The 5 Custom Configuration Checkboxes Explained

| Checkbox | What It Does | Do We Check It? |
|:---|:---|:---:|
| **✅ VPN access** | Activates the core VPN server engine. Opens the tunnel listeners (SSTP, PPTP, L2TP) and manages virtual IP allocations. | **YES! MANDATORY!** *(Without this, it is not a VPN server).* |
| **❌ Dial-up access** | Enables legacy 1990s telephone line modems (POTS 56k dial-in). | **NO!** *(Obsolete hardware).* |
| **❌ Demand-dial connections** | Automatically dials a VPN connection to another branch office only when data needs to cross. | **NO!** *(Only used for Site-to-Site branch office routing).* |
| **❌ NAT** | Enables Windows software NAT translation. | **NO!** *(Your router and Cloudflare already do NAT).* |
| **✅ LAN routing** | Enables kernel IPv4 packet forwarding between the VPN virtual adapter (`192.168.1.221`) and your LAN (`192.168.1.10`) so VPN users can reach file shares, databases, and DNS. | **YES! RECOMMENDED!** *(Enables internal communication).* |

---

### Phase 3: Configure the VPN Client IP Address Pool

The VPN server needs a dedicated pool of IP addresses to assign to incoming remote clients:

1. In **Routing and Remote Access**, right-click **`WIN-J17IMHCEMA9 (local)`** ──► select **Properties**.
2. Click the **IPv4** tab.
3. Under **IPv4 address assignment**, select:  
   👉 **"Static address pool"**.
4. Click **Add...** and enter an IP range in your subnet that does not conflict with DHCP:
   * **Start IP address:** `192.168.1.220`
   * **End IP address:** `192.168.1.240`
   * *(Number of addresses will automatically calculate: 21)*
5. Click **OK** ──► Click **Apply** ──► Click **OK**!

---

#### 🔍 Deep-Dive: Why Static IP Pool is Essential (DHCP Disasters vs. Static Pool)

##### 1️⃣ What is this Step For?
When an employee connects to your VPN from home or a coffee shop, their laptop **MUST receive an internal IP address** (like `192.168.1.221`) so it can talk to your File Shares, Oracle Database, and DNS Server.

By default, Windows RRAS gives you **TWO ways** to hand out IP addresses to VPN users:
1. ❌ **Option A: DHCP (Dynamic Host Configuration Protocol) — The Default**
2. 🏆 **Option B: Static Address Pool — The Enterprise Best Practice**

This step switches your server from **Option A (DHCP)** to **Option B (Static Pool)**!

---

##### 2️⃣ Why Using DHCP for VPN Causes Disasters (The 3 Problems):

* 💥 **1. The "Error 733" Connection Crash:**  
  If the DHCP server is busy, or if the DHCP relay agent has a 2-second lag, remote clients trying to connect to the VPN will fail immediately with:  
  *`Error 733: A connection to the remote computer could not be established because the DHCP server did not respond.`*
* 🕳️ **2. DHCP IP Starvation:**  
  When RRAS starts in DHCP mode, it requests a block of **10 to 20 IP addresses in advance** from your DHCP server, even if ZERO users are connected! This steals IP addresses from real physical computers in the office, causing local desktops to run out of IPs!
* 🕵️ **3. "Logging Blindness" (Cybersecurity Nightmare):**  
  If an audit log records an event from `192.168.1.105` at 2:00 AM, the security team cannot tell if it was an on-site physical PC or a remote VPN worker from home, because both share the same random DHCP range!

---

##### 3️⃣ The 4 Super-Powers of Static Address Pool (`192.168.1.220 - 240`):

* 🛡️ **1. Guaranteed Zero IP Conflicts (Clean Subnet Architecture):**  
  ```text
  ┌─────────────────────────────────────────────────────────────┐
  │                 YOUR NETWORK IP SUBNET MAP                  │
  ├───────────────────┬─────────────────────────────────────────┤
  │ 192.168.1.1       │ Huawei Router (Default Gateway)         │
  │ 192.168.1.10      │ Windows Server (DC / DNS / Web / DB)    │
  │ 192.168.1.100-200 │ Local Office Desktops (DHCP Pool)       │
  │ 192.168.1.201-219 │ Network Printers & Switches             │
  │ 192.168.1.220-240 │ 🔒 DEDICATED REMOTE VPN WORKERS!        │
  └───────────────────┴─────────────────────────────────────────┘
  ```
  Because the ranges **never overlap**, it is mathematically impossible for a VPN user to collide with an office PC!
* 🚨 **2. Instant Threat Identification (Forensics):**  
  If your firewall or Oracle Database log shows a connection from `192.168.1.225`, the IT security team immediately knows without searching: *"That is a REMOTE VPN WORKER outside the office!"*
* 🧱 **3. Easy Firewall Security Policies (ACLs):**  
  You can write firewall rules specifically for remote workers (e.g. allow local desktops `.100-.200` to access payroll servers, but restrict remote VPN users `.220-.240`).
* ⚡ **4. Instant Connection Speed (Zero Lag):**  
  RRAS holds the 21 IP addresses in its own memory. When user `s.pengseang` connects, RRAS assigns the IP in **0.001 seconds** directly without waiting for any DHCP handshake!

---

### Phase 4: Configure Network Policy Server (NPS - RADIUS)

Now we configure the RADIUS Server to authenticate VPN users:

#### Step 4A: Register NPS in Active Directory
1. In **Server Manager**, click **Tools** ──► select **Network Policy Server**.
2. In the console tree, right-click **`NPS (Local)`** (at the very top) ──► select:  
   👉 **"Register server in Active Directory"**.
3. Click **OK** on the confirmation dialog. *(This authorizes NPS to read domain user passwords from Active Directory).*

> [!NOTE]
> 💡 **Why is "Register server in Active Directory" Greyed Out / Disabled?**  
> If the option is disabled or greyed out, **this is normal, expected, and good news!**  
> Because your server `WIN-J17IMHCEMA9` is an **Active Directory Domain Controller**, Windows automatically adds the server computer account into the **`RAS and IAS Servers`** security group during role installation.  
> Windows disables this option to prevent accidental double-registration. It means the server is **already 100% registered and authorized** to read domain user dial-in permissions from Active Directory! You can safely proceed directly to Step 4B!

#### Step 4B: Configure the Network Access Policy for VPN Users
1. In **Network Policy Server**, expand **Policies** ──► click **Network Policies**.
2. By default, there are two disabled policies: *"Connections to other access servers"* and *"Connections to Microsoft Routing and Remote Access server"*.
3. Right-click **Network Policies** ──► select **New**.
4. Name the policy: **`Allow_VPN_Access`** ──► **Type of network access server:** select **Remote Access Server (VPN-Dial up)** ──► click **Next**.

---

#### 🔍 Deep-Dive: What Does "Type of Network Access Server" (NAS) Mean?

In RADIUS protocol architecture (RFC 2865), a **Network Access Server (NAS)** is the **Gatekeeper Device** that intercepts remote users before they enter the internal network. This dropdown tells NPS which type of gatekeeper this policy applies to:

| Option | What It Is | When Is It Used? | Do We Choose It? |
|:---|:---|:---|:---:|
| **1. `Unspecified`** | **Wildcard / Any Gatekeeper** | Used for generic or 3rd-party equipment (Cisco Wi-Fi Access Points, Aruba switches, Fortinet firewalls). Matches *any* incoming RADIUS request. | ❌ No (Too broad; could accidentally affect other services). |
| **2. `Remote Desktop Gateway`** | **RDP over HTTPS (Step 5)** | Used specifically for **RD Gateway** (Terminal Server from Step 5) to control who can RDP through port 443. | ❌ No (This is for RDP desktop connections, not VPN tunnels). |
| **3. `Remote Access Server (VPN-Dial up)`** 🏆 | **Microsoft RRAS VPN Server (Step 6)** | Tells NPS to apply this policy **ONLY to incoming VPN connections** (SSTP, PPTP, L2TP) coming from RRAS! | 🏆 **YES! THIS IS THE ONE!** |

##### 🏢 Real-World Analogy:
* 🚪 **Unspecified:** A generic security rule that applies to any random door on campus.
* 🖥️ **Remote Desktop Gateway:** The security guard checking badges specifically at the Computer Terminal Room.
* 🛡️ **Remote Access Server (VPN-Dial up):** The security guard stationed specifically at the Secure Underground Tunnel (VPN)!

---

5. On **Specify Conditions**: Click **Add...** ──► select **User Groups** ──► click **Add Groups...** ──► type: **`Domain Users`** ──► click **OK** ──► click **Next**.
6. On **Specify Access Permission**: Select **Access granted** ──► click **Next**.
7. On **Configure Authentication Methods**:
   * Check ✅ **Microsoft Encrypted Authentication version 2 (MS-CHAP-v2)**
   * Check ✅ **Microsoft Encrypted Authentication (MS-CHAP)**
   * Click **Next**.
8. Click **Next** through Constraints and Settings ──► click **Finish**!

---

#### 🔍 Deep-Dive: What are "Constraints" in Network Policy Server (NPS)?

In RADIUS security, **Constraints** represent the **Limits and Operating Boundaries** of a connection. While Conditions verify *who* is connecting, Constraints dictate *under what terms* they are allowed to remain connected. If a single constraint is violated, NPS instantly rejects or terminates the connection.

| Constraint | What It Controls | Enterprise Security Purpose | Lab Recommendation |
|:---|:---|:---|:---:|
| **1. Idle Timeout** | Inactivity threshold | Automatically disconnects users if no network packets are sent/received for $X$ minutes. Prevents unattended workstations from remaining an open entry point and reclaims VPN IP pool addresses. | Keep Unchecked (Default) |
| **2. Session Timeout** | Maximum total session lifetime | Hard connection cut-off after $X$ hours regardless of user activity. Enforces periodic re-authentication to mitigate risks from lost or stolen devices. | Keep Unchecked (Default) |
| **3. Called Station ID** | Destination identifier (MAC/SSID/Phone) | Restricts access based on the phone number dialed or the specific BSSID/MAC address of the wireless access point. | Keep Unchecked (Default) |
| **4. Day and Time Restrictions** | Schedule calendar grid | Enforces strict working hour policies (e.g. Monday–Friday 08:00–17:00). Blocks off-hours and weekend access to counter brute-force attacks. | Keep Unchecked (Default) |
| **5. NAS Port Type** | Physical/virtual transport type | Restricts policies to specific media (e.g. `Virtual (VPN)`, `Wireless - IEEE 802.11`, `Ethernet`) to avoid cross-contamination of access rules. | Keep Unchecked (Default) |

> 💡 **Why Keep Unchecked for Testing?**  
> Leaving constraints at default disables timeouts and time locks, ensuring smooth testing at any time of day without artificial disconnections!

---

### Phase 5: Configure User Dial-in Permission in Active Directory

To ensure Active Directory lets NPS make the access decision:

1. Open **Active Directory Users and Computers (`dsa.msc`)**.
2. Double-click user **`s.pengseang`**.
3. Click the **Dial-in** tab.
4. Under **Network Access Permission**, select:  
   👉 **"Control access through NPS Network Policy"** *(or "Allow access")*.
5. Click **Apply** ──► click **OK**!

---

## 🧪 Comprehensive Client Testing Suite (from `pro-win-client`)

> [!TIP]
> 🎯 **System Engineering Golden Rule:** *Always test locally inside VMware first before exposing any server to the public Internet!*  
> Testing locally between `pro-win-client` (`192.168.1.100`) and `pro-win-server` (`192.168.1.10`) bypasses router port-forwarding headaches, ISP CGNAT restrictions, and external security risks while **100% proving** that the RRAS tunnel engine, RADIUS NPS authentication, Active Directory user policies, and virtual IP address leasing work flawlessly!  
> *(For the complete deep-dive on the 4 public testing obstacles and ISP CGNAT, see Section 10 of [`Step6_VPN_RADIUS_Deep_Dive_Concepts.md`](Step6_VPN_RADIUS_Deep_Dive_Concepts.md)).*

---

### 🔒 How LOCAL VPN Testing Works (The 4-Step Engine)

Even though `pro-win-client` is already on the same switch, when you test the VPN from `pro-win-client` to `192.168.1.10`, here is the exact sequence that happens:

```text
  💻 pro-win-client (192.168.1.100)
  Clicks "Connect" to 192.168.1.10 with user: E6\s.pengseang
        │
        │ 1. Client initiates VPN Handshake across the switch
        ▼
  🖥️ pro-win-server (RRAS VPN Engine)
        │
        │ 2. RRAS asks NPS (RADIUS) on UDP Port 1812:
        │    "Is user s.pengseang allowed to connect?"
        ▼
  👑 Active Directory & NPS Policy
        • Checks user: s.pengseang
        • Checks password: abc@123
        • Checks Dial-in Permission: "Allow Access"
        • RADIUS radios back: "ACCESS-ACCEPT! 🟢"
        │
        ▼
  🖥️ RRAS assigns a VIRTUAL IP from your static pool:
        • Leases: 192.168.1.221
        │
        ▼
  🎉 THE CLIENT NOW HAS TWO IP ADDRESSES!
```

#### 🔍 The Proof: Look at `ipconfig` on the Client!
After connecting, if you open CMD on `pro-win-client` and type `ipconfig`, you will see **TWO separate network cards**:

```cmd
C:\> ipconfig

Ethernet adapter Ethernet0:                 ◄── [Physical Local Card]
   IPv4 Address. . . . . . . . . . . : 192.168.1.100

PPP adapter Corporate_E6_VPN:               ◄── [VPN Encrypted Tunnel Card!]
   IPv4 Address. . . . . . . . . . . : 192.168.1.221 🟢
   Subnet Mask . . . . . . . . . . . : 255.255.255.255
```

#### 🏆 Why Testing Locally is so Powerful for University Labs:
Even though you are testing inside VMware, you are testing **100% of the real enterprise security engine**:
* ✅ The **Point-to-Point Tunneling (PPTP / SSTP)** encryption runs.
* ✅ The **RADIUS (NPS) UDP 1812 AAA protocol** runs.
* ✅ Active Directory authenticates **Domain User credentials**.
* ✅ The server dynamically assigns **Virtual Tunnel IPs (`192.168.1.221`)**.
* ✅ The server's RRAS console records **live bandwidth, connected user names, and connection duration**!

---

Execute these verification tests from **`pro-win-client` (`192.168.1.100`)**:

### 🧪 Test 1: Create the VPN Connection on Client

1. On `pro-win-client`, click **Start** ──► click **Settings** (Gear icon) ──► select **Network & Internet**.
2. In the left menu, select **VPN** ──► click **Add a VPN connection**.
3. Configure the fields:
   * **VPN provider:** `Windows (built-in)`
   * **Connection name:** `Corporate_E6_VPN`
   * **Server name or address:** `192.168.1.10` *(or `server1.e6.local`)*
   * **VPN type:** `Automatic` *(or `Point to Point Tunneling Protocol (PPTP)` / `SSTP`)*
   * **Type of sign-in info:** `User name and password`
   * **User name:** `E6\s.pengseang`
   * **Password:** `abc@123`
4. Click **Save**!

---

### 🧪 Test 2: Connect to the VPN & Verify Tunnel

1. Click on your new **`Corporate_E6_VPN`** ──► click **Connect**!
2. Status will change from *Connecting* ──► to 🟢 **Connected**!

---

### 🧪 Test 3: Verify Virtual IP Assignment & Tunnel Statistics

Open **Command Prompt** on `pro-win-client` and run:

```cmd
ipconfig
```

Expected Output:
```text
PPP adapter Corporate_E6_VPN:
   Connection-specific DNS Suffix  . : e6.local
   IPv4 Address. . . . . . . . . . . : 192.168.1.221
   Subnet Mask . . . . . . . . . . . : 255.255.255.255
   Default Gateway . . . . . . . . . : 0.0.0.0
```

* 🟢 **Status:** The client has been securely leased virtual IP **`192.168.1.221`** directly from your VPN static pool!

---

### 🧪 Test 4: Verify Active Remote Connections on Server

On **`pro-win-server`**, in the **Routing and Remote Access** console:
* Click on **`Remote Access Clients`**.
* You will see:
  * **User:** `E6\s.pengseang`
  * **Duration:** Active
  * **Assigned IP:** `192.168.1.221`
  * **Bytes In / Out:** Live encrypted traffic counters!

---

## 🔧 Troubleshooting & Known Issues

| Symptom / Error | Root Cause | Exact Resolution |
|:---|:---|:---|
| **"Error 800: Unable to establish the VPN connection"** | Server RRAS service is not started, or firewall blocks VPN ports. | In RRAS console, right-click server ──► All Tasks ──► Start. Ensure firewall allows TCP 1723 / TCP 443. |
| **"Error 691: The remote connection was denied because the user name and password combination"** | NPS policy did not match or User Dial-in permission is set to "Deny access". | In `dsa.msc`, check User Properties ──► Dial-in tab ──► set to "Control access through NPS Policy". Verify MS-CHAP-v2 is enabled in NPS. |
| **"Error 812: The connection was prevented because of a policy configured on your RAS/VPN server"** | No matching Network Policy in NPS. | In NPS ──► Network Policies ──► Ensure `Allow_VPN_Access` is at the top of the list and has status "Grant Access". |

---

## 📊 Summary of Master Server Roles Completed

| # | Server Role | Status | Documentation File |
|:---:|:---|:---:|:---|
| 1 | **DHCP & DNS Core Network** | ✅ Complete | [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md) |
| 2 | **File Server & FTP Storage** | ✅ Complete | [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md) |
| 3 | **Web Server (IIS + Next.js + PM2)** | ✅ Complete | [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md) |
| 4 | **Database Server (Oracle 19c & PostgreSQL)** | ✅ Complete | [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md) |
| 5 | **Terminal Server (Remote Desktop Services - RDS)** | ✅ Complete | [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md) |
| 6 | **VPN Server (RRAS) & RADIUS Server (NPS)** | 🚀 Ready to Execute | [`Step6_VPN_and_RADIUS_Server_Setup.md`](Step6_VPN_and_RADIUS_Server_Setup.md) |
