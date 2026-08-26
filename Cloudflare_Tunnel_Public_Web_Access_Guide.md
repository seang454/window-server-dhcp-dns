# Cloudflare Tunnel: Complete Public Web Access Guide (CLI Workflow)

**Windows Server 2022 (VM inside Windows 11 Laptop)**  
**Server Hostname:** `WIN-J17IMHCEMA9` (`192.168.1.10`)  
**Target Services:** Next.js Application (`localhost:3000`) & IIS Reverse Proxy (`http://portfolio.e6.local` on port 80)  
**Registered Domain:** `seang.shop`  
**Public Website URL:** `https://portfolio.seang.shop`  
**Security:** Zero-Trust Encrypted Outbound Tunnel (No Port Forwarding, No Public IP, No Credit Card Required)

---

## 📖 Table of Contents

1. [Architecture & How It Works](#1-architecture--how-it-works)
2. [Prerequisites](#2-prerequisites)
3. [Step 1: Download cloudflared CLI on Windows Server](#step-1-download-cloudflared-cli-on-windows-server)
4. [Step 2: Authenticate with Domain (cloudflared login)](#step-2-authenticate-with-domain-cloudflared-login)
5. [Step 3: Create the Named Tunnel (tunnel create)](#step-3-create-the-named-tunnel-tunnel-create)
6. [Step 4: Route Public DNS to the Tunnel (tunnel route dns)](#step-4-route-public-dns-to-the-tunnel-tunnel-route-dns)
7. [Step 5: Run the Tunnel (tunnel run)](#step-5-run-the-tunnel-tunnel-run)
8. [Step 6: Configure as a 24/7 Permanent Windows Service](#step-6-configure-as-a-247-permanent-windows-service)
9. [Step 7: Test & Verify Globally (Phone 4G/5G & Worldwide)](#step-7-test--verify-globally-phone-4g5g--worldwide)
10. [Troubleshooting & Handy Maintenance Commands](#troubleshooting--handy-maintenance-commands)

---

## 1. Architecture & How It Works

```text
  👤 Any User Worldwide (Phone on 4G/5G, Classmate, Recruiter)
           │
           │ 1. HTTPS Request: https://portfolio.seang.shop
           ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  ☁️ CLOUDFLARE GLOBAL EDGE NETWORK (Singapore / Global PoPs)     │
  │  • Automatic Free SSL/TLS Certificate (Green Padlock 🔒)        │
  │  • Enterprise DDoS Mitigation (Blocks bots & hackers)           │
  │  • QUIC Protocol / HTTP/3 for ultra-low latency                 │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                     2. Outbound Encrypted Tunnel
                        (QUIC / TLS over TCP Port 443)
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  📦 YOUR HOME HUAWEI ROUTER (HG8545M)                           │
  │  • Firewall stays 100% CLOSED!                                  │
  │  • ZERO Port Forwarding needed!                                 │
  │  • Works 100% even with ISP CGNAT!                              │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  💻 YOUR PHYSICAL LAPTOP (Windows 11)                           │
  │     Running VMware Workstation                                  │
  │     │                                                           │
  │     │ VMware Virtual Switch                                     │
  │     ▼                                                           │
  │  ┌───────────────────────────────────────────────────────────┐  │
  │  │  🖥️ pro-win-server (Windows Server 2022 VM - 192.168.1.10)│  │
  │  │                                                           │  │
  │  │  ⚡ cloudflared.exe (Tunnel ID: 5d585308-fb32-...)         │  │
  │  │     Receives traffic from tunnel                          │  │
  │  │     │                                                     │  │
  │  │     ├─► http://portfolio.e6.local (IIS Reverse Proxy)     │  │
  │  │     └─► http://localhost:3000     (Next.js Standalone)    │  │
  │  └───────────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────────┘
```

### 💡 Why the CLI Command Workflow is Superior:
1. **Bypasses Credit Card Verification:** The Cloudflare Zero Trust web UI requires a credit card / billing address on checkout even for the free plan. The **CLI workflow requires ZERO payment info**!
2. **Zero Public IP Needed:** Uses a secure tunnel identifier (`<TUNNEL-ID>.cfargotunnel.com`) instead of an IP address.
3. **Bypasses ISP CGNAT:** Works seamlessly on any ISP (Smart, Metfone, Ezecom, SINET).
4. **No Open Ports on Router:** Your Huawei router firewall stays completely closed.

---

## 2. Prerequisites

| Requirement | Value in Your Lab |
|:---|:---|
| **Domain Name** | `seang.shop` (Managed by Cloudflare DNS) |
| **Server VM** | `pro-win-server` (`192.168.1.10`, Windows Server 2022) |
| **Web Server / Application** | Next.js running on port 3000 / IIS on port 80 (`portfolio.e6.local`) |
| **User Account** | `Administrator` (PowerShell elevated prompt) |

---

## Step 1: Download cloudflared CLI on Windows Server

Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
# 1. Create a dedicated directory
New-Item -ItemType Directory -Path "C:\cloudflared" -Force
Set-Location "C:\cloudflared"

# 2. Download the official Cloudflare tunnel binary
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "C:\cloudflared\cloudflared.exe"
```

---

## Step 2: Authenticate with Domain (cloudflared login)

Connect your server to your Cloudflare account without needing API keys or passwords:

```powershell
.\cloudflared.exe tunnel login
```

### 🔍 What happens:
1. PowerShell displays:
   ```text
   A browser window should have opened at the following URL:
   https://dash.cloudflare.com/argotunnel?aud=...
   ```
2. Your default browser opens the Cloudflare authorization page.
3. Select your domain: **`seang.shop`** ──► click **Authorize**!
4. PowerShell automatically detects authorization and outputs:
   ```text
   INF You have successfully logged in.
   If you wish to copy your credentials to a server, they have been saved to:
   C:\Users\Administrator\.cloudflared\cert.pem
   ```

---

## Step 3: Create the Named Tunnel (tunnel create)

Create the persistent tunnel entity on Cloudflare:

```powershell
.\cloudflared.exe tunnel create pro-win-tunnel
```

### 🔍 Live Output:
```text
Tunnel credentials written to C:\Users\Administrator\.cloudflared\5d585308-fb32-48a1-b0c5-13f3b4a478b5.json.
cloudflared chose this file based on where your origin certificate was found. Keep this file secret.

Created tunnel pro-win-tunnel with id 5d585308-fb32-48a1-b0c5-13f3b4a478b5
```

* 🔑 **Tunnel Name:** `pro-win-tunnel`
* 🆔 **Tunnel ID:** `5d585308-fb32-48a1-b0c5-13f3b4a478b5`
* 📄 **Credentials File:** `C:\Users\Administrator\.cloudflared\<TUNNEL-ID>.json`

---

## Step 4: Route Public DNS to the Tunnel (tunnel route dns)

Create the public DNS record automatically:

```powershell
.\cloudflared.exe tunnel route dns pro-win-tunnel portfolio.seang.shop
```

### 🔍 Live Output:
```text
INF Added CNAME portfolio.seang.shop which will route to this tunnel tunnelID=5d585308-fb32-48a1-b0c5-13f3b4a478b5
```

* Cloudflare automatically creates a **CNAME** in your DNS table:  
  `portfolio.seang.shop` ──► `5d585308-fb32-48a1-b0c5-13f3b4a478b5.cfargotunnel.com` (Proxied 🟧).

---

## Step 5: Run the Tunnel (tunnel run)

### Method A: Route through IIS Reverse Proxy (`portfolio.e6.local`)
If your site uses the IIS reverse proxy configured in Step 3:

```powershell
.\cloudflared.exe tunnel run --url http://portfolio.e6.local --http-host-header portfolio.e6.local pro-win-tunnel
```

### Method B: Route Directly to Next.js (`localhost:3000`)
If you want Cloudflare to talk straight to the Node.js/PM2 application:

```powershell
.\cloudflared.exe tunnel run --url http://localhost:3000 pro-win-tunnel
```

### 🔍 Live Output (Active Global Connections):
```text
INF Precheck complete hard_fail=false suggested_protocol=quic
INF Registered tunnel connection connIndex=0 location=sin16 protocol=quic
INF Registered tunnel connection connIndex=1 location=sin15 protocol=quic
INF Registered tunnel connection connIndex=2 location=sin09 protocol=quic
INF Registered tunnel connection connIndex=3 location=sin02 protocol=quic
```

* 🟢 **Status:** Tunnel is 100% active, load-balanced across 4 Cloudflare edge servers in Singapore (`sin`) over the QUIC protocol!

---

## Step 6: Configure as a 24/7 Permanent Windows Service

Currently, if you close the PowerShell window, the tunnel stops. Follow these steps to make it run **permanently in the background as a Windows Service**:

### 6.1 Create the Configuration File (`config.yml`)
In PowerShell, run:

```powershell
@"
tunnel: 5d585308-fb32-48a1-b0c5-13f3b4a478b5
credentials-file: C:\Users\Administrator\.cloudflared\5d585308-fb32-48a1-b0c5-13f3b4a478b5.json

ingress:
  - hostname: portfolio.seang.shop
    service: http://portfolio.e6.local
    originRequest:
      httpHostHeader: portfolio.e6.local
  - service: http_status:404
"@ | Out-File -FilePath "C:\cloudflared\config.yml" -Encoding ascii
```

*(Note: If routing directly to Next.js, change `service: http://localhost:3000` and remove `originRequest`)*

### 6.2 Install and Start the Windows Service
```powershell
# Install the Windows Service pointing to your config file
C:\cloudflared\cloudflared.exe --config "C:\cloudflared\config.yml" service install

# Start the service
Start-Service cloudflared

# Verify it is running 24/7
Get-Service cloudflared
```

Output:
```text
Status   Name               DisplayName
------   ----               -----------
Running  cloudflared        Cloudflare Tunnel
```

* 🎉 **Result:** Even if you restart the server VM or log off, the tunnel **starts automatically on boot**!

---

## Step 7: Test & Verify Globally (Phone 4G/5G & Worldwide)

### 🧪 Test 1: Smartphone Test (4G/5G Cellular Data)
1. Turn **OFF Wi-Fi** on your phone (use Mobile Data 4G/5G so you are completely outside your home network).
2. Open Chrome or Safari.
3. Browse to:
   ```text
   https://portfolio.seang.shop
   ```
4. 🟢 **Expected Result:**
   * Valid SSL certificate (green padlock 🔒).
   * Your Next.js portfolio website loads immediately from your Windows Server VM!

---

### 🧪 Test 2: DNS Resolution Check from CMD
From any computer on the Internet, run:

```cmd
nslookup portfolio.seang.shop
```

Output:
```text
Non-authoritative answer:
Name:    portfolio.seang.shop
Addresses:  104.21.x.x, 172.67.x.x
Aliases:    5d585308-fb32-48a1-b0c5-13f3b4a478b5.cfargotunnel.com
```

* Shows Cloudflare Anycast IPs protecting your real server IP!

---

## 10. Troubleshooting & Handy Maintenance Commands

| Issue | Root Cause | Solution |
|:---|:---|:---|
| **Error 502 Bad Gateway** | IIS or Next.js is not running locally. | Verify app: `curl http://localhost:3000` or `pm2 status`. Start the app. |
| **Error 1033 Cloudflare Tunnel Error** | `cloudflared` process stopped or lost internet. | Restart service: `Restart-Service cloudflared`. |
| **Origin Web Server Error (404/Host Not Found)** | IIS binding does not match hostname. | Ensure `--http-host-header portfolio.e6.local` is included in the run command/config. |

### 🛠️ Useful Management Commands:

```powershell
# Check service status
Get-Service cloudflared

# Restart the service
Restart-Service cloudflared

# Stop the tunnel (takes site offline instantly)
Stop-Service cloudflared

# Start the tunnel (brings site online)
Start-Service cloudflared

# View live tunnel logs
Get-EventLog -LogName Application -Source "cloudflared" -Newest 10 | Format-Table TimeGenerated, Message -Wrap
```
