# Step 3: Web Server (IIS) & Next.js + TypeScript Deployment Guide

**Windows Server 2022 on VMware Workstation**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  
**Server Hostname: server1.e6.local**  
**Portfolio Website Domain: portfolio.e6.local**  
**Application Architecture: Next.js 16 (TypeScript) + Standalone Node.js + PM2 + IIS Reverse Proxy (ARR)**  

---

## 📖 Deep-Dive Concepts & Theory

### 1. What is a Web Server (IIS)?
Internet Information Services (IIS) is Microsoft's enterprise web server software built into Windows Server. It hosts corporate websites, web applications, REST APIs, and intranet portals.

### 2. Microsoft IIS vs. Next.js Architecture
- **IIS is not a Next.js runtime:** IIS natively executes ASP.NET and serves static files; it relies on Node.js to execute server-side JavaScript logic (`RESEND_API_KEY`, API routes, server actions).
- **PM2 Process Manager:** Runs `node server.js` on internal TCP Port `3000` in the background 24/7, auto-restarting on crash or server reboot.
- **IIS Reverse Proxy (ARR + URL Rewrite):** IIS sits in front on Port 80/443, handling public domain routing (`portfolio.e6.local`), SSL certificates, and security headers, forwarding requests internally to `http://localhost:3000`.

---

## 📊 Architectural Comparison: `iisnode` vs. `PM2` for Next.js

| Feature | 📦 Microsoft `iisnode` | ⚡ `PM2` (Process Manager 2) ⭐ |
|:---|:---|:---|
| **Communication Protocol** | Uses legacy **Windows Named Pipes** (`\\.\pipe\`). | Uses standard **TCP Network Sockets** (`http://localhost:3000`). |
| **Next.js 15/16 Standalone Compatibility** | ❌ **Incompatible** (Next.js 16 `server.js` requires TCP sockets; fails on Named Pipes with HTTP 500.1001). | ✅ **100% Compatible** (Native support for Next.js 16 standalone, API Routes, Resend emails, & SSR). |
| **Process Control & Monitoring** | Managed inside IIS Application Pools (`w3wp.exe`). | Managed via live CLI dashboard (`pm2 status`, `pm2 logs`, `pm2 monit`). |
| **Server Reboot Auto-Start** | Managed via IIS Service. | Managed via `pm2 save` & `pm2-startup install`. |
| **Industry Status** | Legacy extension (unmaintained since 2018). | **Active global industry standard** for Node.js production servers. |

---

## 🔄 Master Deployment Flowchart: PM2 + IIS Reverse Proxy

```
                        MASTER DEPLOYMENT FLOWCHART
                        
 [ PHASE 1: DEV MACHINE (VS Code) ]
   1. Set `output: "standalone"` in `next.config.ts`
   2. Run `npm run build` ──► Generates `.next/standalone/`
            │
            ▼
 [ PHASE 2: SERVER PREPARATION (pro-win-server) ]
   1. Install Node.js LTS (v24.19.0)
   2. Install IIS Extensions: URL Rewrite 2.1 & ARR 3.0
   3. Enable Proxy in IIS ARR (Server Proxy Settings ──► Enable proxy)
            │
            ▼
 [ PHASE 3: FILE ASSEMBLY (C:\inetpub\portfolio\) ]
   Copy 4 items into C:\inetpub\portfolio\:
   ├── 📄 server.js + node_modules/   (From .next/standalone/)
   ├── 📄 .env                        (Your Resend API Key & Secrets)
   ├── 📁 public/                     (cv.pdf & images)
   └── 📁 .next/static/               (Compiled CSS/JS static assets)
            │
            ▼
 [ PHASE 4: EXECUTION & REVERSE PROXY ]
   1. Start 24/7 Node Server via PM2: `pm2 start server.js --name "Portfolio"` (Port 3000)
   2. Create IIS Site: `Portfolio` (Port 80, Host name: `portfolio.e6.local`)
   3. Add IIS Reverse Proxy Rule: Port 80 ──► `http://localhost:3000`
   4. Add DNS Host Record: `portfolio.e6.local` ──► `192.168.1.10`
   5. Open Firewall Port 80: `netsh advfirewall firewall add rule ...`
            │
            ▼
 🎉 SUCCESS! Next.js API Routes, Resend Emails & Portfolio Live 24/7!
```

---

## 🚀 Step-by-Step Implementation Guide

### Phase 1: Dev Machine Setup (`next.config.ts`)

Open `next.config.ts` in your Next.js project and ensure it contains:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: "standalone",
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
```

Run in VS Code terminal:
```bash
npm run build
```

---

### Phase 2: Copy Files to `C:\inetpub\portfolio\` on Server

Assemble these 4 items inside `C:\inetpub\portfolio\` on `pro-win-server`:

```text
 📁 C:\inetpub\portfolio\
  ├── 📄 server.js               (From .next/standalone/server.js)
  ├── 📄 .env                    (Your Resend API Keys & Secrets)
  ├── 📄 web.config              (IIS Reverse Proxy & Security Rules)
  ├── 📁 public/                 (Contains cv.pdf & public images)
  ├── 📁 .next/
  │    ├── 📁 static/            (From .next/static/)
  │    └── 📁 server/            (From .next/standalone/.next/server/)
  └── 📁 node_modules/           (From .next/standalone/node_modules/)
```

#### Production-Ready `C:\inetpub\portfolio\web.config`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <!-- 1. IIS Reverse Proxy Rule to Next.js (Port 3000) -->
        <rewrite>
            <rules>
                <rule name="ReverseProxyInboundRule1" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Rewrite" url="http://localhost:3000/{R:1}" />
                </rule>
            </rules>
        </rewrite>

        <!-- 2. Security: Block public access to .env or node_modules -->
        <security>
            <requestFiltering>
                <hiddenSegments>
                    <add segment="node_modules" />
                    <add segment=".env" />
                </hiddenSegments>
            </requestFiltering>
        </security>
    </system.webServer>
</configuration>
```

---

### Phase 3: Start Next.js 24/7 Background Process via PM2

Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
# 1. Install PM2 & Windows Startup Service Helper
npm install -g pm2
npm install -g pm2-windows-startup

# 2. Register PM2 as a Windows System Service
pm2-startup install

# 3. Grant IIS Folder Permissions
icacls C:\inetpub\portfolio /grant "IIS_IUSRS":(OI)(CI)F /T
icacls C:\inetpub\portfolio /grant "IUSR":(OI)(CI)F /T

# 4. Launch Next.js Standalone Server
cd C:\inetpub\portfolio
pm2 start server.js --name "Portfolio"

# 5. Save Process List for Auto-Start on Windows Reboot
pm2 save
```

#### How `pm2-windows-startup` Works Behind the Scenes:
- **`npm install -g pm2-windows-startup`**: Installs the Windows Service wrapper tool for PM2.
- **`pm2-startup install`**: Registers a new official Windows Background Service named `pm2` inside Windows Services (`services.msc`).
- **`pm2 save`**: Saves your running website (`Portfolio`) into a permanent configuration file (`~/.pm2/dump.pm2`).

#### The Auto-Boot Timeline:
```text
 🔌 1. Windows Server VM Powers On / Reboots
       │
       ▼  2. Windows launches background services (services.msc)
 ⚙️ `pm2-windows-startup` Service Launches Automatically
       │
       ▼  3. Reads saved process list (~/.pm2/dump.pm2)
 ⚡ Restores 'Portfolio' Next.js Server (localhost:3000)
       │
       ▼  4. IIS Reverse Proxy routes traffic
 🎉 Website is live 24/7 on boot before anyone even logs into Windows!
```

---

### Phase 4: IIS Reverse Proxy & DNS Setup

#### 1. Enable IIS Proxy (ARR Extension)
1. Open **IIS Manager** on `pro-win-server`.
2. Click server name at top left (**`WIN-J17IMHCEMA9`**).
3. Double-click **Application Request Routing Cache**.
4. In right panel, click **Server Proxy Settings...** → check ✅ **Enable proxy** → click **Apply**.

#### 2. Unlock IIS Handlers Section
Run in Command Prompt (Admin) on `pro-win-server`:
```cmd
%windir%\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/handlers
```

#### 3. Create Website in IIS Manager
1. In **IIS Manager**, right-click **Sites** → select **Add Website...**
2. Fill in:
   - **Site name:** `Portfolio`
   - **Physical path:** `C:\inetpub\portfolio`
   - **Port:** `80` (or `8081`)
   - **Host name:** `portfolio.e6.local`
3. Click **OK**.

#### 4. Add Reverse Proxy Rule
1. Click **Portfolio** site → double-click **URL Rewrite**.
2. Click **Add Rule(s)...** → select **Reverse Proxy**.
3. Inbound server name: `localhost:3000` → click **OK**.

#### 5. Add DNS Record for `portfolio.e6.local`
1. Open **DNS Manager** (**Server Manager → Tools → DNS**).
2. Expand `WIN-J17IMHCEMA9` → **Forward Lookup Zones** → right-click **`e6.local`**.
3. Select **New Host (A or AAAA)...** → Name: `portfolio` | IP: `192.168.1.10` → click **Add Host**.

#### 6. Open Firewall Port 80
Run in PowerShell (Admin) on `pro-win-server`:
```powershell
netsh advfirewall firewall add rule name="Allow World Wide Web HTTP Port 80" dir=in action=allow protocol=TCP localport=80
```

---

## 🌐 Testing Matrix

| Client Location | Test URL / Command | Expected Result |
|:---|:---|:---|
| **Client VM (`pro-win-client`)** | `http://portfolio.e6.local` | Full React Next.js Portfolio loads, Resend API works, CV downloads! |
| **Physical Laptop (hosts file)** | `http://portfolio.e6.local` (after adding `192.168.100.4 portfolio.e6.local` in `hosts`) | Portfolio website renders cleanly on physical laptop browser! |
| **Public Internet (ngrok)** | `ngrok http 127.0.0.1:8080` → `https://xxxx.ngrok-free.app` | Accessible from any mobile phone or computer worldwide 24/7! |

---

## 🛠️ Troubleshooting Guide

### 1. Error: `HTTP 502 Bad Gateway`
- **Cause:** Node.js standalone server is not running on Port 3000.
- **Fix:** Run `pm2 start server.js --name "Portfolio"` inside `C:\inetpub\portfolio\`. Check status with `pm2 status`.

### 2. Error: `DNS_PROBE_FINISHED_NXDOMAIN` on Physical Laptop
- **Cause:** Physical laptop DNS points to Home Wi-Fi router instead of VM DNS (`192.168.1.10`).
- **Fix:** Open `C:\Windows\System32\drivers\etc\hosts` on physical laptop as Admin, add line: `192.168.100.4 portfolio.e6.local`.

### 3. Error: `HTTP 500.19 - 0x80070021`
- **Cause:** Handlers section locked at IIS server level.
- **Fix:** Run `%windir%\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/handlers` on server.

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
