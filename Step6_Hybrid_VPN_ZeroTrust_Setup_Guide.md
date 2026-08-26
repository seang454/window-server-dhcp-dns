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
4. [Phase 1: Configure Windows Server VPN (RRAS) on Server](#phase-1-configure-windows-server-vpn-rras-on-server)
5. [Phase 2: Configure Static IPv4 Pool (192.168.1.220 - 192.168.1.240)](#phase-2-configure-static-ipv4-pool-1921681220---1921681240)
6. [Phase 3: Configure RADIUS Server (Network Policy Server - NPS)](#phase-3-configure-radius-server-network-policy-server---nps)
7. [Phase 4: Configure Active Directory Dial-in Permissions](#phase-4-configure-active-directory-dial-in-permissions)
8. [Phase 5: Route Private Subnet Through Cloudflare Tunnel (Ezecom CGNAT Bypass)](#phase-5-route-private-subnet-through-cloudflare-tunnel-ezecom-cgnat-bypass)
9. [Phase 6: Remote Client Setup & Testing (Outside Coffee Shop / 4G)](#phase-6-remote-client-setup--testing-outside-coffee-shop--4g)
10. [Phase 7: Live Verification on Server (RRAS & Active Sessions)](#phase-7-live-verification-on-server-rras--active-sessions)
11. [Troubleshooting Common Issues & Error Codes](#troubleshooting-common-issues--error-codes)

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

## Phase 1: Configure Windows Server VPN (RRAS) on Server

On **`pro-win-server`** (`192.168.1.10`):

### 1.1 Open Routing and Remote Access Console
1. Press **`Win + R`** ──► type:
   ```cmd
   rrasmgmt.msc
   ```
2. Press **Enter**.
3. In the left navigation pane, locate your server:  
   **`WIN-J17IMHCEMA9 (local)`**  
   *(Notice the red downward arrow 🔴 indicating the service is unconfigured).*

### 1.2 Launch the Configuration Wizard
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

## Phase 2: Configure Static IPv4 Pool (`192.168.1.220` - `192.168.1.240`)

By default, RRAS tries to lease IPs using DHCP. In enterprise environments, allocating a dedicated **Static Address Pool** prevents IP collisions and ensures VPN clients are easily identifiable in network logs.

### 2.1 Configure the Static IP Pool in RRAS
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

## Phase 3: Configure RADIUS Server (Network Policy Server - NPS)

Network Policy Server (NPS) acts as the centralized **AAA (Authentication, Authorization, and Accounting)** engine.

### 3.1 Register NPS in Active Directory
1. Press **`Win + R`** ──► type:
   ```cmd
   nps.msc
   ```
2. Press **Enter**.
3. Right-click on **`NPS (Local)`** at the top of the left tree ──► select **Register server in Active Directory**.
4. Click **OK** on the authorization prompt ──► click **OK** on the confirmation.

### 3.2 Create the VPN Authorization Policy
1. In `nps.msc`, expand **Policies** in the left menu ──► click **Network Policies**.
2. In the right pane, **right-click** in blank space ──► select **New**.
3. **Policy Name:** Type `Allow_VPN_Access`  
   * **Type of network access server:** Select `Remote Access Server (VPN-Dial up)`  
   * Click **Next**.
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
8. **Configure Settings:** Click **Next** (keep defaults).
9. Click **Finish**!

### 3.3 Set Policy Processing Order
1. Click on your newly created policy **`Allow_VPN_Access`**.
2. Click **Move Up** in the right Actions pane until it is at **Processing Order: 1** (above any default deny rules).

---

## Phase 4: Configure Active Directory Dial-in Permissions

Active Directory stores the individual dial-in authorization flag on each user account.

### 4.1 Set Dial-in Permission for User `s.pengseang`
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

## Phase 5: Route Private Subnet Through Cloudflare Tunnel (Ezecom CGNAT Bypass)

Now we connect your local server network to Cloudflare's global edge so outside users can reach `192.168.1.10` over Ezecom without any router port-forwarding!

### 5.1 Add Private Subnet Route via PowerShell
On **`pro-win-server`**, open PowerShell as Administrator and run:

```powershell
# Instruct Cloudflare Tunnel to route the 192.168.1.0/24 subnet
C:\cloudflared\cloudflared.exe tunnel route ip add 192.168.1.0/24 5d585308-fb32-48a1-b0c5-13f3b4a478b5
```

### 5.2 Verify the Active Route:
```powershell
C:\cloudflared\cloudflared.exe tunnel route ip show
```

Expected Output:
```text
NETWORK          TUNNEL ID                              CREATED AT
192.168.1.0/24   5d585308-fb32-48a1-b0c5-13f3b4a478b5   2026-08-27...
```

* 🟢 **Result:** Cloudflare Edge now officially routes packets destined for `192.168.1.x` directly down into your server VM!

---

## Phase 6: Remote Client Setup & Testing (Outside Coffee Shop / 4G)

Execute this from your **physical laptop, phone, or remote machine outside your home**:

### 6.1 Install & Connect Cloudflare WARP (The Underlay Bridge)
1. Download and install **Cloudflare WARP** (1.1.1.1 app) from [1.1.1.1](https://1.1.1.1/).
2. Open the WARP app ──► click the **Gear icon** ──► **Account** ──► **Login with Cloudflare Zero Trust**.
3. Enter your team organization name.
4. Flip the big switch to **Connected** 🟢!

### 6.2 Test Underlay Network Reachability
Open Command Prompt / Terminal on the remote machine:

```cmd
ping 192.168.1.10
```

* 🟢 **Expected Output:**
  ```text
  Reply from 192.168.1.10: bytes=32 time=28ms TTL=128
  ```
  *(Congratulations! You just pinged your home server across Ezecom CGNAT from the outside world!)*

---

### 6.3 Connect to the Windows Server VPN (The Identity Overlay)
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

### 6.4 Verify Leased IP on Client:
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

## Phase 7: Live Verification on Server (RRAS & Active Sessions)

On **`pro-win-server`**, verify the active remote connection:

### 7.1 Inspect Live Sessions in RRAS Console:
1. Open `rrasmgmt.msc`.
2. Expand **`WIN-J17IMHCEMA9 (local)`** ──► click **Remote Access Clients**.
3. In the center pane, you will see your active session:
   * **Client Name:** `E6\s.pengseang`
   * **Duration:** `00:04:15`
   * **Number of Ports:** `1`
   * **Assigned IP:** `192.168.1.221`

### 7.2 Inspect Live RADIUS Authentication in PowerShell:
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
