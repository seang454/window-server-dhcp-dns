# Cloudflare Tunnel: Complete Public Web Access Guide

**Windows Server 2022 (VM inside Windows 11 Laptop)**  
**Target Services:** Next.js Application (`localhost:3000`) & IIS Reverse Proxy (`localhost:80`)  
**Domain:** `e6.local` (Internal) ──► `portfolio.yourdomain.com` (Public Worldwide)  
**Security:** Zero-Trust Encrypted Outbound Tunnel (No Port Forwarding, No Public IP Required)

---

## 📖 Table of Contents

1. [Architecture & How It Works](#1-architecture--how-it-works)
2. [Prerequisites](#2-prerequisites)
3. [Step 1: Get a Domain & Add It to Cloudflare](#step-1-get-a-domain--add-it-to-cloudflare)
4. [Step 2: Open Cloudflare Zero Trust & Create Tunnel](#step-2-open-cloudflare-zero-trust--create-tunnel)
5. [Step 3: Install cloudflared on pro-win-server (Windows Server 2022)](#step-3-install-cloudflared-on-pro-win-server-windows-server-2022)
6. [Step 4: Configure Public Hostname in Cloudflare](#step-4-configure-public-hostname-in-cloudflare)
7. [Step 5: Test & Verify from Any Phone or Laptop Worldwide](#step-5-test--verify-from-any-phone-or-laptop-worldwide)
8. [Step 6: Exposing Multiple Services on 1 Tunnel](#step-6-exposing-multiple-services-on-1-tunnel)
9. [Troubleshooting & Maintenance Commands](#troubleshooting--maintenance-commands)

---

## 1. Architecture & How It Works

```text
  👤 Any User in the World (Classmate, Teacher, Recruiter, Phone on 4G/5G)
           │
           │ 1. HTTPS Request: https://portfolio.yourdomain.com
           ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │  ☁️ CLOUDFLARE GLOBAL EDGE NETWORK (Over 300 Data Centers)       │
  │  • Automatic Free SSL/TLS Certificate (Green Padlock 🔒)        │
  │  • Enterprise DDoS Mitigation (Blocks bots & hackers)           │
  │  • Web Application Firewall (WAF)                               │
  │  • Edge Caching for ultra-fast loading speed                    │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                     2. Outbound Encrypted Tunnel
                        (TLS over TCP Port 443 / QUIC)
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
  │     │ VMware Virtual Switch (Bridged or NAT)                    │
  │     ▼                                                           │
  │  ┌───────────────────────────────────────────────────────────┐  │
  │  │  🖥️ pro-win-server (Windows Server 2022 VM - 192.168.1.10)│  │
  │  │                                                           │  │
  │  │  ⚡ cloudflared.exe (Windows Service running 24/7)         │  │
  │  │     Receives traffic from tunnel                          │  │
  │  │     │                                                     │  │
  │  │     ├─► http://localhost:3000 (Next.js Application)       │  │
  │  │     └─► http://localhost:80   (IIS 10 Web Server)         │  │
  │  └───────────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────────┘
```

### 💡 Why Cloudflare Tunnel is Revolutionary:
1. **Zero Public IP Needed:** You do NOT need to know your home IP or buy a static IP from your ISP.
2. **Bypasses ISP CGNAT:** Works even if your ISP (Smart, Metfone, Ezecom, SINET) shares your IP with 100 houses!
3. **No Open Ports on Router:** Your Huawei router firewall stays completely closed. Hackers on the Internet cannot scan your home network!
4. **Free Enterprise SSL:** Cloudflare automatically manages HTTPS certificates for free.

---

## 2. Prerequisites

Before starting, ensure you have:

| Requirement | Description | Cost |
|:---|:---|:---:|
| **Cloudflare Account** | Free account at [cloudflare.com](https://cloudflare.com) | **$0** (Free) |
| **A Domain Name** | Any domain (e.g. `yourname.com`, `pengseang.tech`, etc.) registered via Namecheap, Porkbun, or Cloudflare Registrar | **~$5 – $10/year** |
| **`pro-win-server` VM** | Running Windows Server 2022 with Internet access | Free (Lab) |
| **Next.js Application** | Running on `localhost:3000` via PM2 (from Step 3) | Free (Lab) |

---

## Step 1: Get a Domain & Add It to Cloudflare

If you already have a domain on Cloudflare, skip to [Step 2](#step-2-open-cloudflare-zero-trust--create-tunnel).

### 1.1 Buy a Cheap Domain (if you don't have one)
* Go to [porkbun.com](https://porkbun.com) or [namecheap.com](https://namecheap.com).
* Search for an inexpensive domain (e.g. `yourname.xyz` or `yourname.top` for ~$2, or `yourname.com` for ~$9/year).
* Purchase the domain.

### 1.2 Add Domain to Cloudflare
1. Log into your free account at [dash.cloudflare.com](https://dash.cloudflare.com).
2. Click **Add a domain** (or **Add a Site**).
3. Type your domain name (e.g. `yourdomain.com`) ──► click **Continue**.
4. Select the **Free Plan ($0)** ──► click **Continue**.
5. Cloudflare will scan your existing DNS records ──► click **Continue**.
6. Cloudflare gives you **2 Nameservers**, for example:
   * `amy.ns.cloudflare.com`
   * `brad.ns.cloudflare.com`

### 1.3 Update Nameservers at Your Domain Registrar
1. Open the website where you bought your domain (e.g. Namecheap / Porkbun / GoDaddy).
2. Go to **Domain Management** ──► **Nameservers**.
3. Change from *"Default Nameservers"* to **"Custom Nameservers"**.
4. Paste the 2 Cloudflare nameservers ──► click **Save**.
5. Return to Cloudflare and click **Check nameservers now**.
6. Within 5–15 minutes, Cloudflare will display: 🟢 **"Great news! Cloudflare is now protecting your site"**!

---

## Step 2: Open Cloudflare Zero Trust & Create Tunnel

1. Open a browser and go to:  
   👉 [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
2. If this is your first time:
   * Enter a unique **Team Name** (e.g. `e6-server-lab`) ──► click **Next**.
   * Choose the **Free Plan ($0/month)** ──► complete the free checkout (no credit card required).
3. In the left navigation menu, click:  
   **Networks** ──► select **Tunnels** (or **Access** ──► **Tunnels**).
4. Click the blue button: **Create a tunnel** (or **Add a tunnel**).
5. Select connector type: **Cloudflared** ──► click **Next**.
6. Enter a name for your tunnel:
   ```text
   Tunnel Name: pro-win-server-tunnel
   ```
7. Click **Save tunnel**.

---

## Step 3: Install cloudflared on pro-win-server (Windows Server 2022)

Cloudflare will now display the **Install and run a connector** page.

### 3.1 Choose the Windows Environment
* Click the **Windows** tab.
* Choose **64-bit**.

### 3.2 Run the Single Installation Command in PowerShell
Cloudflare gives you an exact command containing your **secret tunnel token**:

```powershell
# Example of the Cloudflare command (copy YOUR exact command from the dashboard!):
winget install --id Cloudflare.cloudflared
```

Or the **Direct Service Install Command** provided on the page:

```cmd
cloudflared.exe service install eyJhIjoiYmMyY2Q3...<YOUR-UNIQUE-TUNNEL-TOKEN>...
```

#### 🛠️ Manual Method (Fast & Reliable on Windows Server):
If `winget` is not installed on Windows Server 2022:

1. Inside **`pro-win-server`**, open PowerShell as Administrator.
2. Create a folder for Cloudflare:
   ```powershell
   New-Item -ItemType Directory -Path "C:\cloudflared" -Force
   Set-Location "C:\cloudflared"
   ```
3. Download the official `cloudflared` Windows binary:
   ```powershell
   Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "C:\cloudflared\cloudflared.exe"
   ```
4. Copy the install command from your Cloudflare dashboard and paste it into PowerShell:
   ```powershell
   C:\cloudflared\cloudflared.exe service install <YOUR_TOKEN_FROM_DASHBOARD>
   ```
5. Start the Windows Service:
   ```powershell
   Start-Service cloudflared
   ```
6. Verify the service is running:
   ```powershell
   Get-Service cloudflared
   ```
   * Output should show: `Status: Running`!

### 3.3 Check Cloudflare Dashboard
Look at your browser on the Cloudflare dashboard:
* Under **Connectors**, you will see:  
  🟢 **Status: HEALTHY** (Connected from your Windows Server)!
* Click **Next**!

---

## Step 4: Configure Public Hostname in Cloudflare

Now tell Cloudflare which public URL points to your local Next.js / IIS server!

In the **Public Hostname** tab, configure the following:

```text
  ┌────────────────────────────────────────────────────────────────────────┐
  │  PUBLIC HOSTNAME SETTINGS                                              │
  │                                                                        │
  │  Subdomain:   portfolio                                                │
  │  Domain:      yourdomain.com  (select from dropdown)                   │
  │  Path:        (leave empty)                                            │
  │                                                                        │
  │  SERVICE SETTINGS                                                      │
  │  Type:        HTTP                                                     │
  │  URL:         localhost:3000   (for Next.js Standalone app)            │
  │               OR                                                       │
  │               localhost:80     (for IIS Reverse Proxy website)         │
  └────────────────────────────────────────────────────────────────────────┘
```

1. Click **Save hostname**!
2. Cloudflare **automatically creates the DNS CNAME record** pointing `portfolio.yourdomain.com` to your tunnel!

---

## Step 5: Test & Verify from Any Phone or Laptop Worldwide

### 🧪 Test 1: Mobile Phone Test (4G/5G Cellular Data)
1. Turn **OFF Wi-Fi** on your smartphone (use Mobile Data 4G/5G so you are completely outside your home network).
2. Open Chrome or Safari.
3. Type:
   ```text
   https://portfolio.yourdomain.com
   ```
4. 🟢 **Result:**
   * Green padlock appears (valid SSL certificate)!
   * Your Next.js portfolio website opens instantly from your Windows Server VM!

---

### 🧪 Test 2: Verify Tunnel Status via PowerShell on Server
On `pro-win-server`, run:

```powershell
# Check cloudflared service status
Get-Service cloudflared

# View live cloudflared log events in Windows Event Viewer
Get-EventLog -LogName Application -Source "cloudflared" -Newest 10 | Format-Table TimeGenerated, Message -Wrap
```

---

## Step 6: Exposing Multiple Services on 1 Tunnel

You can host **multiple websites and services** through the exact same single tunnel connector!

In Cloudflare Zero Trust ──► **Tunnels** ──► Click your tunnel ──► **Configure** ──► **Public Hostnames** ──► **Add a public hostname**:

| Public Hostname | Service Type | Local URL | What It Serves |
|:---|:---:|:---|:---|
| `portfolio.yourdomain.com` | `HTTP` | `localhost:3000` | Next.js Portfolio Application |
| `www.yourdomain.com` | `HTTP` | `localhost:80` | IIS 10 Web Server Root |
| `api.yourdomain.com` | `HTTP` | `localhost:5000` | Backend REST API |
| `ftp-web.yourdomain.com` | `HTTP` | `localhost:8080` | Web File Manager |

Cloudflare automatically routes each subdomain to the correct local port inside your Windows Server!

---

## Troubleshooting & Maintenance Commands

| Issue | Root Cause | Solution |
|:---|:---|:---|
| **Error 502: Bad Gateway** | Next.js or IIS is not running on the specified local port. | Verify app is running on server: `curl http://localhost:3000` or `pm2 status`. Start the app if stopped. |
| **Error 1033: Cloudflare Tunnel error** | The `cloudflared` service on `pro-win-server` is stopped or server lost internet. | Restart service in PowerShell: `Restart-Service cloudflared`. Check internet connectivity. |
| **Tunnel Status: INACTIVE / DOWN** | Machine was rebooted and service did not auto-start. | Set service to Automatic: `Set-Service -Name cloudflared -StartupType Automatic` then `Start-Service cloudflared`. |
| **DNS Resolution Error** | Nameservers were not updated at registrar. | Ensure domain registrar has Cloudflare nameservers saved and active. |

### 🛠️ Useful Management Commands:

```powershell
# Restart the Cloudflare Tunnel Service
Restart-Service cloudflared

# Stop the Tunnel (instantly takes your site offline)
Stop-Service cloudflared

# Start the Tunnel (brings site back online)
Start-Service cloudflared

# Check current cloudflared version
C:\cloudflared\cloudflared.exe --version

# Update cloudflared to the latest version
C:\cloudflared\cloudflared.exe update
```

---

## 📊 Summary Comparison: Cloudflare Tunnel vs. Router Port Forwarding

| Feature | Router Port Forwarding (Old) | Cloudflare Tunnel (Modern Zero-Trust) ⭐ |
|:---|:---:|:---:|
| **Cost** | Free | **100% Free** |
| **Requires Static Public IP?** | 🔴 Yes (Fails on dynamic IP) | 🟢 **No (Zero IP needed!)** |
| **Works behind ISP CGNAT?** | 🔴 **Fails 100%** | 🟢 **Works 100% seamlessly** |
| **Open Ports on Home Router?** | 🔴 Yes (Vulnerable to port scans) | 🟢 **Zero open ports (Firewall closed)** |
| **DDoS Attack Protection?** | 🔴 None (Home router can crash) | 🟢 **Enterprise Cloudflare DDoS Defense** |
| **SSL/TLS Certificate?** | 🟡 Must configure certbot manually | 🟢 **Automatic Free Cloudflare SSL** |
| **Works with VMware VMs?** | 🟡 Complex NAT port mapping | 🟢 **Runs right inside VM out-of-the-box** |
