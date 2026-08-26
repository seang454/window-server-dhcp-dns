# Step 6: Hybrid Windows Server VPN (RRAS + NPS) & Cloudflare Zero-Trust Private Network Guide

**Environment:** Windows Server 2022 (VM inside Windows 11 Laptop)  
**Server Hostname:** `WIN-J17IMHCEMA9` (`192.168.1.10`)  
**Domain:** `e6.local` (Active Directory Domain Controller)  
**Permanent Cloudflare Tunnel ID:** `5d585308-fb32-48a1-b0c5-13f3b4a478b5` (`pro-win-tunnel`)  
**ISP Environment:** Ezecom Cambodia (CGNAT / No Static Public IP)  
**Target Solution:** Hybrid Underlay (Cloudflare WARP Tunnel) + Identity Overlay (Windows Server RRAS + NPS RADIUS)

---

## 📖 Table of Contents

1. [Architecture & The Hybrid Request Flow](#1-architecture--the-hybrid-request-flow)
2. [Why We Need Both: Underlay vs. Overlay](#2-why-we-need-both-underlay-vs-overlay)
3. [Lab Context & Credentials](#3-lab-context--credentials)
4. [Phase 1: Install Server Roles in Server Manager (VPN & RADIUS)](#phase-1-install-server-roles-in-server-manager-vpn--radius)
5. [Phase 2: Configure Windows Server VPN (RRAS) on Server](#phase-2-configure-windows-server-vpn-rras-on-server)
6. [Phase 3: Configure Static IPv4 Pool (192.168.1.220 - 192.168.1.240)](#phase-3-configure-static-ipv4-pool-1921681220---1921681240)
7. [Phase 4: Configure RADIUS Server (Network Policy Server - NPS)](#phase-4-configure-radius-server-network-policy-server---nps)
8. [Phase 5: Configure Active Directory Dial-in Permissions](#phase-5-configure-active-directory-dial-in-permissions)
9. [Phase 6: Cloudflare Zero-Trust Private Network Setup (Bypassing Ezecom CGNAT)](#phase-6-cloudflare-zero-trust-private-network-setup-bypassing-ezecom-cgnat)
10. [Phase 7: Remote Client Setup & Testing (Outside Coffee Shop / 4G)](#phase-7-remote-client-setup--testing-outside-coffee-shop--4g)
11. [Phase 8: Live Verification on Server (RRAS & Active Sessions)](#phase-8-live-verification-on-server-rras--active-sessions)
12. [Troubleshooting Common Issues & Error Codes](#troubleshooting-common-issues--error-codes)

---

## 1. Architecture & The Hybrid Request Flow

This architecture allows remote users (sitting at a coffee shop or anywhere in the world on 4G/5G) to connect to your **Windows Server VPN**, even though your home server is behind **Ezecom CGNAT** with no public IP and closed router ports!

```text
  ☕ 1. REMOTE CLIENT (Coffee shop on Wi-Fi or 4G/5G)
        • Laptop runs free Cloudflare WARP client.
        • User clicks "Connect".
        • WARP establishes an encrypted WireGuard tunnel to Cloudflare Edge.
        │
        ▼
  ☁️ 2. CLOUDFLARE EDGE (Singapore / Phnom Penh)
        • Destination packet addressed to: 192.168.1.10.
        • Cloudflare routes 192.168.1.0/24 down your active tunnel:
          Tunnel ID: 5d585308-fb32-48a1-b0c5-13f3b4a478b5 (pro-win-tunnel)
        │
        ▼
  📦 3. HOME ROUTER (Ezecom CGNAT Completely Bypassed!)
        • The packet enters your server VM because YOUR server initiated
          the outbound tunnel connection (Outbound Established State)!
        • ZERO open ports on Huawei router.
        │
        ▼
  🖥️ 4. WINDOWS SERVER 2022 (pro-win-server - 192.168.1.10)
        • Windows RRAS receives the incoming VPN handshake.
        • RRAS asks NPS (RADIUS) over UDP Port 1812:
          "Is user E6\s.pengseang authorized to connect?"
        • Active Directory verifies credentials and checks:
          "Dial-in Permission = Allow Access" 🟢
        │
        ▼
  🎉 5. SECURE ENTERPRISE SESSION ESTABLISHED!
        • RRAS leases virtual IP: 192.168.1.221 from your static pool.
        • Client can now access File Shares (\\192.168.1.10\finance),
          Oracle Database (port 1521), and Remote Desktop (mstsc)!
        • Active Directory logs the login in Windows Security Audit Logs.
```

---

## 2. Why We Need Both: Underlay vs. Overlay

| Layer | Technology | Role & Purpose |
|:---|:---|:---|
| **Transport Underlay (Bypass)** | **Cloudflare Tunnel + WARP** | Solves the network barrier. Bypasses Ezecom CGNAT, eliminates router port-forwarding, hides server IP, and blocks external DDoS attacks. |
| **Security Overlay (Governance)** | **Windows RRAS + NPS (RADIUS)** | Solves the enterprise compliance requirement. Evaluates Active Directory domain credentials, enforces group policies, assigns private subnet IP addresses, and logs audit sessions. |

---

## 3. Lab Context & Credentials

| Parameter | Value |
|:---|:---|
| **Domain Name** | `e6.local` (NetBIOS: `E6`) |
| **Domain Controller / Server** | `WIN-J17IMHCEMA9` (`192.168.1.10`) |
| **Subnet** | `192.168.1.0/24` (Subnet Mask: `255.255.255.0`) |
| **Default Gateway** | `192.168.1.1` (Huawei HG8545M router) |
| **VPN Static IP Pool** | `192.168.1.220` to `192.168.1.240` (21 addresses) |
| **Active Tunnel ID** | `5d585308-fb32-48a1-b0c5-13f3b4a478b5` |
| **Domain Admin** | `E6\Administrator` / `abc@123` |
| **Test Domain User** | `E6\s.pengseang` / `abc@123` |

---

## Phase 1: Install Server Roles in Server Manager (VPN & RADIUS)

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

On **`pro-win-server`** (`192.168.1.10`):

### 1.1 Open Add Roles and Features Wizard:
1. Open **Server Manager**.
2. Click **Manage** (top right corner) ──► select **Add Roles and Features**.
3. On the **Before You Begin** screen ──► click **Next**.
4. Select **Role-based or feature-based installation** ──► click **Next**.
5. Select server **`WIN-J17IMHCEMA9`** (`192.168.1.10`) ──► click **Next**.

### 1.2 Select the 2 Server Roles:
Under the **Server Roles** list, check these **TWO roles**:
* ✅ **Network Policy and Access Services**  
  *(A popup will appear: click **Add Features**)*  
  👉 *This installs the RADIUS / NPS Server!*
* ✅ **Remote Access**  
  👉 *This installs the VPN / RRAS Server!*

Click **Next** ──► click **Next** past Features.

### 1.3 Select Role Services for Remote Access:
1. Click **Next** past the *Network Policy and Access Services* overview.
2. Click **Next** past the *Remote Access* overview.
3. On the **Role Services** screen for Remote Access, check:
   * ✅ **DirectAccess and VPN (RAS)**  
     *(A popup will appear: click **Add Features**)*
   * ✅ **Routing** *(Enables LAN routing and packet forwarding)*
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

### 1.4 Install:
1. Click **Next** ──► review the confirmation screen.
2. Click **Install**! *(Installation takes ~1–2 minutes)*.
3. Once the progress bar reaches **"Installation succeeded"** ──► click **Close**!

---

## Phase 2: Configure Windows Server VPN (RRAS) on Server

On **`pro-win-server`** (`192.168.1.10`):

### 2.1 Open Routing and Remote Access Console
1. Press **`Win + R`** ──► type:
   ```cmd
   rrasmgmt.msc
   ```
2. Press **Enter**.
3. In the left navigation pane, locate your server:  
   **`WIN-J17IMHCEMA9 (local)`**  
   *(Notice the red downward arrow 🔴 indicating the service is unconfigured).*

### 2.2 Launch the Configuration Wizard
1. **Right-click** on **`WIN-J17IMHCEMA9 (local)`** ──► select **Configure and Enable Routing and Remote Access**.
2. On the **Welcome** page ──► click **Next**.
3. On the **Configuration** page:
   * Select: 🔘 **Custom configuration**
   * Click **Next**.
4. On the **Custom Configuration** page, check:
   * ✅ **VPN access**
   * ✅ **LAN routing**
   * Click **Next**.
5. Click **Finish**!
6. A prompt will appear:  
   *"The Routing and Remote Access service is ready to start. Do you want to start the service?"*  
   👉 Click **Start service**!

* 🟢 **Result:** The red down arrow 🔴 turns into a **green up arrow 🟢**! The RRAS VPN engine is now active!

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

## Phase 3: Configure Static IPv4 Pool (`192.168.1.220` - `192.168.1.240`)

By default, RRAS tries to lease IPs using DHCP. In enterprise environments, allocating a dedicated **Static Address Pool** prevents IP collisions and ensures VPN clients are easily identifiable in network logs.

### 3.1 Configure the Static IP Pool in RRAS
1. In `rrasmgmt.msc`, **right-click** on **`WIN-J17IMHCEMA9 (local)`** ──► select **Properties**.
2. Click on the **IPv4** tab.
3. Under **IPv4 address assignment**, select:  
   🔘 **Static address pool**
4. Click the **Add...** button:
   * **Start IPv4 address:** `192.168.1.220`
   * **End IPv4 address:** `192.168.1.240`
   * **Number of addresses:** `21` *(calculated automatically)*
5. Click **OK**.
6. Click **Apply** ──► click **OK**.

> [!NOTE]
> 💡 **Why this range?**  
> Your DHCP scope distributes `192.168.1.100 - 192.168.1.200`.  
> Placing VPN clients at `192.168.1.220 - 192.168.1.240` guarantees that remote VPN users never conflict with local office desktop leases!

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

## Phase 4: Configure RADIUS Server (Network Policy Server - NPS)

Network Policy Server (NPS) acts as the centralized **AAA (Authentication, Authorization, and Accounting)** engine.

### 4.1 Register NPS in Active Directory
1. Press **`Win + R`** ──► type:
   ```cmd
   nps.msc
   ```
2. Press **Enter**.
3. Right-click on **`NPS (Local)`** at the top of the left tree ──► select **Register server in Active Directory**.
4. Click **OK** on the authorization prompt ──► click **OK** on the confirmation.

> [!NOTE]
> 💡 **Why is "Register server in Active Directory" Greyed Out / Disabled?**  
> If the option is disabled or greyed out, **this is normal, expected, and good news!**  
> Because your server `WIN-J17IMHCEMA9` is an **Active Directory Domain Controller**, Windows automatically adds the server computer account into the **`RAS and IAS Servers`** security group during role installation.  
> Windows disables this option to prevent accidental double-registration. It means the server is **already 100% registered and authorized** to read domain user dial-in permissions from Active Directory! You can safely proceed directly to Step 4.2!

---

### 4.2 Create the VPN Authorization Policy
1. In `nps.msc`, expand **Policies** in the left menu ──► click **Network Policies**.
2. In the right pane, **right-click** in blank space ──► select **New**.
3. **Policy Name:** Type `Allow_VPN_Access`  
   * **Type of network access server:** Select `Remote Access Server (VPN-Dial up)`  
   * Click **Next**.

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

4. **Specify Conditions:** Click **Add...**:
   * Select **User Groups** ──► click **Add...**.
   * Click **Add Groups...** ──► type:
     ```text
     Domain Users
     ```
   * Click **Check Names** ──► click **OK** ──► click **Next**.
5. **Specify Access Permission:**
   * Select 🔘 **Access granted**  
   * Click **Next**.
6. **Configure Authentication Methods:**
   * Uncheck all boxes except:
     * ✅ **Microsoft Encrypted Authentication version 2 (MS-CHAP-v2)**
   * Click **Next**.
7. **Configure Constraints:** Click **Next** (keep defaults).

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

8. **Configure Settings:** Click **Next** (keep defaults).

---

#### 🔍 Deep-Dive: What are "Settings" in Network Policy Server (NPS)?

When NPS grants access (`RADIUS Access-Accept`), it attaches specific attributes and instructions directing the VPN server on how to establish and secure the client's connection.

| Setting Area | Sub-Category | Purpose & Enterprise Usage | Default Configuration |
|:---|:---|:---|:---:|
| **RADIUS Attributes** | **Standard** | RFC 2865 standard attributes. Automatically includes: <br>• `Framed-Protocol = PPP` (encapsulates data inside a PPP tunnel). <br>• `Service-Type = Framed` (delivers full Layer 3 IP network routing). | Pre-configured ✅ |
| **RADIUS Attributes** | **Vendor Specific (VSA)** | Hardware-specific vendor attributes (e.g. Cisco-AVPair, MikroTik bandwidth rate-limiting `10M/10M`). | Unconfigured (Optional) |
| **Routing & Remote Access** | **Multilink & BAP** | Bandwidth Allocation Protocol — dynamically aggregates multiple dial-in lines or modems into a single high-bandwidth trunk. | Unconfigured |
| **Routing & Remote Access** | **IP Filters** | Inbound/Outbound packet firewall filters applied directly to the user session (e.g. restrict user to Web port 80/443 only). | Unconfigured |
| **Routing & Remote Access** | **Encryption** | Enforces encryption level (Basic, Strong 128-bit, Strongest 256-bit AES / 3DES). | Strong/Strongest Allowed ✅ |
| **Routing & Remote Access** | **IP Settings** | Determines whether the VPN server allocates IP from the static pool or if the client may request a static IP. | Server Assigns (Pool) ✅ |

> 💡 **Why Keep Defaults?**  
> The default attributes (`Framed-Protocol = PPP`, `Service-Type = Framed`) and default encryption provide the standard, high-security enterprise baseline for Windows RRAS without requiring manual adjustments.

---

9. Click **Finish**!

### 4.3 Set Policy Processing Order
1. Click on your newly created policy **`Allow_VPN_Access`**.
2. Click **Move Up** in the right Actions pane until it is at **Processing Order: 1** (above any default deny rules).

---

## Phase 5: Configure Active Directory Dial-in Permissions

Active Directory stores the individual dial-in authorization flag on each user account.

### 5.1 Set Dial-in Permission for User `s.pengseang`
1. Press **`Win + R`** ──► type:
   ```cmd
   dsa.msc
   ```
2. Press **Enter** to open Active Directory Users and Computers.
3. Browse to **`e6.local ──► Users`** (or your organizational OU).
4. Double-click user **`s.pengseang`**.
5. Click on the **Dial-in** tab.
6. Under **Network Access Permission**, select:  
   🔘 **Control access through NPS Network Policy**  
   *(Or select **Allow access**)*.
7. Click **Apply** ──► click **OK**.

---

## Phase 6: Cloudflare Zero-Trust Private Network Setup (Bypassing Ezecom CGNAT)

Now we connect your local server network to Cloudflare's global edge so outside users can reach `192.168.1.10` over Ezecom without any router port-forwarding!

### 🖥️ Part 1: On `pro-win-server` (The 1-Minute Step)

Since you **already have `cloudflared.exe` installed and running 24/7**, you only need to run **one single command**!

Open PowerShell as Administrator on `pro-win-server` and run:

```powershell
# 1. Add your local network route to your permanent tunnel:
C:\cloudflared\cloudflared.exe tunnel route ip add 192.168.1.0/24 5d585308-fb32-48a1-b0c5-13f3b4a478b5

# 2. Verify the route is registered:
C:\cloudflared\cloudflared.exe tunnel route ip show
```

#### 🔍 Expected Output:
```text
NETWORK          TUNNEL ID                              CREATED AT
192.168.1.0/24   5d585308-fb32-48a1-b0c5-13f3b4a478b5   2026-08-27...
```
* 🟢 **Result:** That's it for the server! Your server is now broadcasting its private network (`192.168.1.0/24`) to Cloudflare Edge!

---

### ☁️ Part 2: On Cloudflare Zero Trust Dashboard (Web Browser)

Open your browser on your physical laptop and go to:  
👉 **[one.dash.cloudflare.com](https://one.dash.cloudflare.com/)** *(Sign in with your Cloudflare account)*

#### 1. Check Your Tunnel:
1. In the left menu, click **Networks** ──► **Tunnels**.
2. Click on **`pro-win-tunnel`**.
3. Under the **Private Network** tab, you will see:  
   👉 **`192.168.1.0/24`** with status **Healthy 🟢**!

#### 2. Configure Split Tunnels (Crucial Step ⚠️):
By default, Cloudflare WARP ignores local IPs like `192.168.x.x`. We need to tell WARP to route `192.168.1.0/24` into the tunnel!
1. Go to **Settings** (gear icon at bottom left) ──► **WARP Client**.
2. Under **Profile settings**, click **Default** ──► scroll down to **Split Tunnels**.
3. You will see a list of IP ranges that are excluded.
4. Find **`192.168.0.0/16`** ──► click the **trash can / Delete 🗑️** icon next to it!
5. Click **Save**!  
   *(Now, any request to `192.168.1.10` will fly directly into your tunnel!)*

#### 3. Add Device Enrollment Rule (Allow your email to connect):
1. Still in **Settings** ──► **WARP Client**.
2. Under **Device enrollment**, click **Manage** ──► click **Rules** tab.
3. Click **Add a rule**:
   * **Rule name:** `Allow-My-Devices`
   * **Rule action:** `Allow`
   * **Selector:** `Emails`
   * **Value:** Type your email: `pengseangsim210@gmail.com`
4. Click **Save**!

---

## Phase 7: Remote Client Setup & Testing (Outside Coffee Shop / 4G)

Now, on any computer or smartphone outside your home (or connected to 4G mobile data):

### 📱 Part 3: On the Remote Laptop / Phone (The Client)

#### 1. Download WARP:
Download the free **Cloudflare WARP (1.1.1.1)** app from **[1.1.1.1](https://1.1.1.1/)** (available for Windows, Mac, iOS, Android).

#### 2. Connect to Your Team:
1. Open the **1.1.1.1** app.
2. Click the **Gear icon (Settings)** ──► **Preferences** (or **Account**).
3. Click **Login with Cloudflare Zero Trust**.
4. Type your Cloudflare team name (shown in your dashboard URL, e.g. `seang-lab`).
5. Enter your email: `pengseangsim210@gmail.com`.
6. Cloudflare will email you a **6-digit PIN code** ──► type it in!
7. Flip the big switch to **Connected 🟢**!

---

### 🧪 The Big Test (Outside Your Home!):

#### 🧪 Test 1: Ping Your Server Across Ezecom CGNAT!
Open Command Prompt on that outside laptop and run:

```cmd
ping 192.168.1.10
```

* 🟢 **Expected Output:**
  ```text
  Reply from 192.168.1.10: bytes=32 time=35ms TTL=128
  ```
  *(BOOM! You just pinged your home server across Ezecom CGNAT from the outside world!)*

---

#### 🧪 Test 2: Connect via Remote Desktop (RDP)
1. Open **Remote Desktop Connection** (`mstsc`).
2. **Computer:** `192.168.1.10`
3. **User:** `E6\s.pengseang`  
4. **Password:** `abc@123`
5. 🖥️ **Result:** Your server desktop opens from anywhere in the world across Ezecom CGNAT!

---

### 7.3 Connect to the Windows Server RRAS VPN (The Identity Overlay)
Now establish the official Windows Server RRAS connection:

1. Click **Start** ──► **Settings** ──► **Network & Internet** ──► **VPN**.
2. Click **Add a VPN connection**:
   * **VPN provider:** `Windows (built-in)`
   * **Connection name:** `E6_Corporate_VPN`
   * **Server name or address:** `192.168.1.10`
   * **VPN type:** `Point to Point Tunneling Protocol (PPTP)` or `Automatic`
   * **Type of sign-in info:** `User name and password`
   * **User name:** `E6\s.pengseang`
   * **Password:** `abc@123`
3. Click **Save**.
4. Click on **`E6_Corporate_VPN`** ──► click **Connect**!

* 🟢 **Status:** The state transitions from *Connecting* ──► to **Connected**!

---

### 7.4 Verify Leased IP on Client:
Open Command Prompt on the client and run:

```cmd
ipconfig
```

Expected Output:
```text
PPP adapter E6_Corporate_VPN:
   Connection-specific DNS Suffix  . : e6.local
   IPv4 Address. . . . . . . . . . . : 192.168.1.221
   Subnet Mask . . . . . . . . . . . : 255.255.255.255
```

---

## Phase 8: Live Verification on Server (RRAS & Active Sessions)

On **`pro-win-server`**, verify the active remote connection:

### 8.1 Inspect Live Sessions in RRAS Console:
1. Open `rrasmgmt.msc`.
2. Expand **`WIN-J17IMHCEMA9 (local)`** ──► click **Remote Access Clients**.
3. In the center pane, you will see your active session:
   * **Client Name:** `E6\s.pengseang`
   * **Duration:** `00:04:15`
   * **Number of Ports:** `1`
   * **Assigned IP:** `192.168.1.221`

### 8.2 Inspect Live RADIUS Authentication in PowerShell:
```powershell
Get-WinEvent -LogName "Security" -FilterXPath "*[System[(EventID=6272 or EventID=6278)]]" -MaxEvents 3 | Format-List TimeCreated, Message
```
* Shows event `6272`: *"Network Policy Server granted access to a user (E6\s.pengseang)"*!

---

## Troubleshooting Common Issues & Error Codes

| Error Code / Symptom | Root Cause | Solution |
|:---|:---|:---|
| **Error 800 / 807** (Unable to establish connection) | WARP is disconnected, or RRAS service stopped. | Verify WARP shows Connected. Run `Get-Service RemoteAccess` on server. |
| **Error 691** (User authentication failure) | Wrong username/password, or Dial-in disabled. | Check credentials (`E6\s.pengseang`). In `dsa.msc`, verify Dial-in is set to "Allow access" or "Control through NPS". |
| **Error 812** (Policy denied connection) | NPS policy conditions or authentication mismatch. | In `nps.msc`, verify `Allow_VPN_Access` has **MS-CHAP-v2** checked and is at **Processing Order: 1**. |
| **No Virtual IP Assigned** | Static address pool is exhausted or missing. | In `rrasmgmt.msc` properties ──► IPv4 tab ──► verify pool `192.168.1.220 - 192.168.1.240` is present. |
