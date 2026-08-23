# Step 3: Local vs. Public Server Testing Setup Guide

**Windows Server 2022 on VMware Workstation**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  

---

## Overview

In network engineering, servers are accessed in two ways:
1. **Local Access (Internal LAN):** Clients inside `192.168.1.0/24` access servers directly (`http://server1.e6.local`).
2. **Public Access (Simulated Internet Access):** External users on the internet access the server via **Port Forwarding (NAT)** or **VPN**.

This guide provides step-by-step instructions to configure and test **BOTH** Local and Public access for Web (IIS) and FTP servers.

## IP Address Breakdown Matrix

| Machine / Device | Type of IP Address | Example IP Value | Scope & Function |
|:---|:---|:---|:---|
| 🖥️ **Windows Server VM** | **Private VM IP** | `192.168.1.10` | Lives inside VMware `VMnet8` internal virtual network. Hosts AD, DNS, DHCP, IIS & FTP services. |
| 💻 **Physical Laptop (Host)** | **Private LAN IP** | `192.168.100.4` | Lives on Home Wi-Fi LAN. Runs VMware Workstation and receives Port Forwarded traffic from Router. |
| 🌐 **Home Router WAN** | **Public / CGNAT IP** | `203.144.76.136` | Assigned by ISP. The single public IP address representing your entire house on the global Internet. |
| 🐧 **Fedora Machine (4G)** | **Mobile Data IP** | `10.x.x.x` (Cellular) | Independent machine on external 4G/5G mobile network trying to access your server from outside. |

```
                        LOCAL ACCESS (Internal LAN)
   ┌───────────────────┐                          ┌───────────────────┐
   │ Client VM         │ ───────────────────────► │ Windows Server    │
   │ 192.168.1.100     │ Direct LAN Access        │ 192.168.1.10      │
   └───────────────────┘ http://server1.e6.local  └───────────────────┘
                                                            ▲
                                                            │
                        PUBLIC ACCESS (Simulated Internet)  │ Forward Port
   ┌───────────────────┐                          ┌─────────┴─────────┐
   │ Physical Host PC  │ ───────────────────────► │ VMware NAT Router │
   │ (Simulates Public │ http://localhost:8080    │ Port Forwarding   │
   │ Internet User)    │                          │ Host 8080 ──► .10:80
   └───────────────────┘                          └───────────────────┘
```

## Part B: Public Internet Access Setup (Method B - True Public Test)

To allow anyone anywhere in the world to access your FTP server over the Internet, traffic must pass through 3 layers:

```
 [ External Device (4G/5G) ]
             │
             ▼  Public IP:2121
 ┌───────────────────────────────┐
 │ 1. Home Wi-Fi Router (NAT)    │  Forward Port 2121 ──► Laptop IP
 └───────────┬───────────────────┘
             │
             ▼  Laptop IP:2121
 ┌───────────────────────────────┐
 │ 2. Laptop Firewall & VMware   │  Forward Port 2121 ──► VM 192.168.1.10:21
 └───────────┬───────────────────┘
             │
             ▼  VM IP:21
 ┌───────────────────────────────┐
 │ 3. Windows Server (FTP Role)  │  Serves welcome.txt to client
 └───────────────────┘
```

---

### 100% Windows GUI Step-by-Step Implementation Guide (Method B):

#### Step 1: Configure VMware NAT Port Forwarding (VMware UI)
1. On Physical Laptop, open **VMware Workstation**.
2. Click menu bar: **Edit → Virtual Network Editor...**
3. Click **Change Settings** button *(click Yes on Windows UAC prompt)*.
4. Select **VMnet8 (NAT)** row → click **NAT Settings...** button.
5. Click **Add...** button:
   - **Host Port:** `2121`
   - **Type:** `TCP`
   - **Virtual machine IP address:** `192.168.1.10`
   - **Virtual machine port:** `21`
   - **Description:** `Public FTP`
6. Click **OK → Apply → OK**.

#### Step 2: Open Port 2121 on Laptop Firewall (Windows Defender Firewall UI)
1. Press `Win + R` → type **`wf.msc`** → press **Enter** *(opens Windows Defender Firewall with Advanced Security)*.
2. Click **Inbound Rules** on the left panel.
3. On the **far-right Actions panel**, click **`New Rule...`**
4. **Rule Type:** Select **Port** → click **Next**.
5. **Protocol and Ports:** Select **TCP** → type **`2121`** in *Specific local ports* → click **Next**.
6. **Action:** Select **Allow the connection** → click **Next**.
7. **Profile:** Check all 3 (✅ **Domain**, ✅ **Private**, ✅ **Public**) → click **Next**.
8. **Name:** Type `Allow VMware Public FTP Port 2121` → click **Finish** (icon turns green 🟢).

#### Step 3: Find Laptop Wi-Fi IP Address (Windows Settings UI)
1. Click the **Wi-Fi / Network Icon** on your Windows Taskbar (near the clock).
2. Click **Properties** (or open **Windows Settings → Network & internet → Wi-Fi**).
3. Scroll down to the bottom properties section.
4. Locate **IPv4 address** (e.g., `192.168.1.50` or `192.168.0.50`).

#### Step 4: Configure Port Forwarding on Home Router (Web Browser UI)
1. Open Google Chrome or Microsoft Edge on your laptop.
2. Type router gateway address: `192.168.1.1` (or `192.168.0.1`) → press **Enter**.
3. Log into router admin panel (credentials on sticker on bottom of router).
4. Click **Advanced → Forward Rules → IPv4 Port Mapping**.
5. Click **New**:
   - **Enable Port Mapping:** Check ✅
   - **Mapping Name:** `Public_FTP`
   - **Internal Host:** *(Your Laptop Wi-Fi IP from Step 3)*
   - **External Port:** `2121`
   - **Internal Port:** `2121`
   - **Protocol:** `TCP`
6. Click **Apply**.

#### Step 5: Find Public IP & Test from Mobile Phone (UI)
1. Open browser on laptop → search Google for *"what is my ip"* → copy your **Public IP** (e.g. `203.144.x.x`).
2. Disconnect mobile phone from home Wi-Fi *(enable 4G/5G mobile data)*.
3. Open phone browser or FTP App → type: `ftp://<YOUR_PUBLIC_IP>:2121`
4. Log in with `E6\Administrator` and your password!

## Complete ngrok FTP Packet Flow Diagram & Trace

```
                         COMPLETE NGROK FTP PACKET FLOW
                         
  [ External User (Fedora / Mobile 4G) ]
                    │
                    ▼  1. Request sent over Public Internet: 0.tcp.ap.ngrok.io:26238
  🌐 ngrok Global Edge Server (Cloud Data Center)
                    │
                    ▼  2. Encrypted Tunnel to ngrok agent process
  💻 Physical Laptop Host (listening on localhost:2121)
                    │
                    ▼  3. VMware NAT Port Forwarding (Host 2121 ──► VM 21)
  🔄 VMware Virtual Switch (VMnet8)
                    │
                    ▼  4. Inbound TCP Port 21
  🖥️ Windows Server VM (192.168.1.10:21)
                    │
                    ▼  5. IIS FTP Server reads C:\inetpub\ftproot\welcome.txt
  🎉 Response travels back through tunnel to External Client!
```

### Step-by-Step Packet Journey:
1. **Client Request:** Remote user on Fedora or phone types `curl ftp://0.tcp.ap.ngrok.io:26238/welcome.txt -u "E6\Administrator"`.
2. **ngrok Cloud Edge:** ngrok's public data center receives traffic on `0.tcp.ap.ngrok.io:26238` and routes it into your private ngrok tunnel.
3. **Physical Laptop Host:** The `ngrok.exe` background process on your physical laptop receives the packet and hands it off to `localhost:2121`.
4. **VMware NAT Engine:** VMware Workstation takes traffic on Host Port `2121` and translates it to VM IP `192.168.1.10:21`.
5. **Windows Server VM:** IIS FTP Server validates Active Directory credentials (`E6\Administrator`) and serves `welcome.txt` back to the user!

---

## FTPS (FTP over SSL/TLS) Packet Flow via ngrok

```
                       FTPS OVER SSL/TLS PACKET FLOW
                       
  [ External Client (Fedora / Phone / FileZilla) ]
                    │
                    ▼  1. Encrypted TLS Request: 0.tcp.ap.ngrok.io:26238
  🌐 ngrok Global Edge Server (Cloud Data Center)
                    │
                    ▼  2. Encrypted Tunnel to ngrok agent process
  💻 Physical Laptop Host (listening on localhost:2121)
                    │
                    ▼  3. VMware NAT Port Forwarding (Host 2121 ──► VM 21)
  🔄 VMware Virtual Switch (VMnet8)
                    │
                    ▼  4. Inbound TLS Connection (Port 21/990)
  🖥️ Windows Server VM (192.168.1.10:21)
                    │  - Decrypts TLS using SSL Certificate
                    │  - Authenticates E6\Administrator against Active Directory
                    ▼  
  🎉 Serves encrypted files back to Client!
```

### Key Differences between Plain FTP and FTPS:
- **Plain FTP (Port 21):** Passwords and data sent in clear text. Requires dynamic data ports (`1024-65535`).
- **FTPS (Port 990 / 21 TLS):** Passwords and data encrypted using TLS certificates. Supports SSL session reuse over control channel.

> **Recommended Enterprise Solution for CGNAT & Remote Workers: Tailscale Mesh VPN ⭐**
> - **Why it's recommended:** Home ISPs use CGNAT (`100.64.0.0/10`), blocking inbound public router ports across different networks.
> - **How Tailscale solves it:** Tailscale uses WireGuard encrypted mesh networking to connect external devices (e.g. Fedora laptop on 4G) directly to the Windows Server VM over any network globally without needing public IPs, router port forwarding, or monthly ISP fees.

> **Internal Port vs. External Port Explained:**
> 
> | Term | Where it exists | Real-World Analogy | Purpose & Example |
> |:---|:---|:---|:---|
> | **External Port** | **Public Internet Side** | **Building Street Number** | The port that users on the Internet type to reach your router (e.g. `ftp://<PUBLIC_IP>:2121`). |
> | **Internal Port** | **Local Network Side** | **Room / Desk Extension** | The port on your local computer/VMware host where the service is actually listening (e.g. Port `2121`). |
>
> * **Port Translation (PAT):** The router automatically translates incoming requests from External Port 2121 to Internal Port 2121 on your laptop!

> **Safety & Network Impact FAQ:**
> - **Will this disrupt current Wi-Fi or connected devices?** NO! Port forwarding only routes specific incoming traffic on Port 2121. All existing Wi-Fi devices, phones, TVs, and internet browsing remain 100% unaffected.
> - **Is it dangerous?** Using a non-standard port (`2121`) protected by domain credentials (`E6\Administrator`) keeps the lab safe. When you complete your testing, simply delete or disable the Port Mapping rule in the router.

   ```text
   ftp://<YOUR_PUBLIC_IP>:2121
   ```
4. Log in with `E6\Administrator` and your password!

---

## Part A: Local Network Testing (Internal LAN)

Local testing verifies that client computers on the same subnet (`192.168.1.0/24`) can access services directly.

### A1. Install Web Server (IIS) Role on Server (`pro-win-server`)
1. Open **Server Manager** → **Manage → Add Roles and Features**.
2. Select **Server Roles** → check ✅ **Web Server (IIS)**.
3. Click **Add Features → Next → Next → Install**.
4. Wait for completion → click **Close**.

---

### A2. Test Web Server Locally (From `pro-win-client`)
1. Open **Internet Explorer** or **Edge** on `pro-win-client`.
2. Type in address bar:
   ```text
   http://server1.e6.local
   ```
   *(or `http://192.168.1.10`)*
3. **Result:** You will see the default **Windows IIS Welcome Page**! ✅

---

### A3. Test FTP Server Locally (From `pro-win-client`)
1. Open **Command Prompt** on `pro-win-client`.
2. Connect to local FTP:
   ```cmd
   ftp server1.e6.local
   ```
3. Enter credentials `Administrator` and password.
4. Type `dir` → **Result:** Successfully lists files! ✅

---

## Part B: Public Access Simulation (Port Forwarding via VMware NAT)

Since private IP addresses (`192.168.1.10`) cannot be reached directly from the public internet, enterprise companies and VMware use **Port Forwarding (NAT)** to route external public traffic to internal servers.

### B1. Configure VMware NAT Port Forwarding Rules

1. On your **Physical Host PC**, open **VMware Workstation**.
2. Click **Edit → Virtual Network Editor**.
3. Click **Change Settings** (Administrator permission).
4. Click **VMnet8 (NAT)** → click **NAT Settings...**
5. Under *Port Forwarding*, click **Add...**:

#### Rule 1: Web Server Public Access (Forward Host Port 8080 to Server Port 80)
- **Host Port:** `8080`
- **Type:** `TCP`
- **Virtual Machine IP Address:** `192.168.1.10`
- **Virtual Machine Port:** `80`
- **Description:** `Public Web Access`
- Click **OK**.

#### Rule 2: FTP Server Public Access (Forward Host Port 2121 to Server Port 21)
- **Host Port:** `2121`
- **Type:** `TCP`
- **Virtual Machine IP Address:** `192.168.1.10`
- **Virtual Machine Port:** `21`
- **Description:** `Public FTP Access`
- Click **OK**.

6. Click **OK → Apply → OK**.

---

### B2. Enable Windows Server Firewall Rules

Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
# Enable HTTP Web Port 80
Enable-NetFirewallRule -DisplayGroup "World Wide Web Services (HTTP)"

# Enable FTP Port 21
Enable-NetFirewallRule -DisplayGroup "FTP Server"
```

---

### B3. Test Public Access (From Physical Host PC)

Your **Physical Host PC** acts as an external user on the public internet connecting to the public gateway (`localhost` / Host IP).

#### Test 1: Public Web Server Access
1. Open Chrome, Edge, or Firefox on your **Physical Host PC** (outside VMware).
2. Type in address bar:
   ```text
   http://localhost:8080
   ```
3. 🎉 **Result:** The **Windows IIS Welcome Page** from your Windows Server VM loads on your physical computer!
4. **How it works:** Your request hit `localhost:8080` on your host PC, and VMware NAT forwarded the traffic straight into `192.168.1.10:80` inside the VM!

---

#### Test 2: Public FTP Server Access
1. Open Command Prompt on your **Physical Host PC**.
2. Connect via public forwarded port:
   ```cmd
   ftp localhost 2121
   ```
3. Type User: `Administrator` and your password.
4. 🎉 **Result:** `230 User logged in, proceed.`
5. Type `dir` to list files on your Windows Server VM!

---

## Part C: Secure Public Access via VPN (Virtual Private Network)

In enterprise networks, opening public ports directly can be risky. The **best enterprise practice** for public access is **VPN**:

```
Public Remote Worker ──► [ VPN Gateway (Port 443) ] ──► Encrypted Tunnel ──► Local Server (192.168.1.10)
```

1. **Public Remote Worker** connects over public internet to your server's **VPN Gateway**.
2. **RADIUS (NPS)** verifies user identity against Active Directory.
3. An **Encrypted Tunnel** drops the worker safely into the **Local LAN (`192.168.1.x`)**.
4. The worker accesses File Server (`\\server1.e6.local`), IIS Web, and Databases securely!

---

## Summary Matrix: Local vs. Public Testing

| Access Type | Test Location | URL / Address Used | Mechanism Used |
|:---|:---|:---|:---|
| **Local Web (IIS)** | Client VM (`pro-win-client`) | `http://server1.e6.local` | Direct Local LAN (Port 80) |
| **Local FTP** | Client VM (`pro-win-client`) | `ftp://server1.e6.local` | Direct Local LAN (Port 21) |
| **Local SMB File Share**| Client VM (`pro-win-client`) | `\\server1.e6.local\CompanyData` | Direct Local LAN (Port 445) |
| **Public Web (IIS)** | Physical Host PC | `http://localhost:8080` | VMware NAT Port Forwarding (8080 ──► 80) |
| **Public FTP** | Physical Host PC | `ftp localhost 2121` | VMware NAT Port Forwarding (2121 ──► 21) |
| **Public VPN Access** | Remote Internet Client | VPN Tunnel | RADIUS (NPS) Encrypted Tunnel |
