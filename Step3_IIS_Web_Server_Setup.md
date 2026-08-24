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

## 🚀 Step-by-Step Detailed Configuration Guide

---

### Step 1: Configure `next.config.ts` for Standalone Output

#### 🎯 Objective & Purpose
To instruct Next.js to compile a lightweight, self-contained standalone server package containing Node.js server entry points and required dependencies.

#### 🛠️ What it is for
Projects containing API routes, environment variables (`.env`), Resend email integrations, and dynamic backend logic cannot be compiled into static HTML (`output: 'export'`). Setting `output: "standalone"` instructs Next.js to package a standalone Node.js server bundle inside `.next/standalone/`.

#### ⚙️ Configuration Steps
1. Open `next.config.ts` in your Next.js project root in VS Code.
2. Replace contents with:
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
3. Open VS Code terminal (`Ctrl + ~`) and run:
```bash
npm run build
```

#### ✅ Expected Verification Result
Terminal displays `✓ Exporting...` and `✓ Finalizing page optimization`. The directory `.next/standalone/` is created inside your project folder.

---

### Step 2: Assemble Production Files in `C:\inetpub\portfolio\`

#### 🎯 Objective & Purpose
To assemble the exact compiled production bundle on `pro-win-server` so Node.js can execute `server.js` with access to static assets, images, and `.env` secrets.

#### 🛠️ What it is for
- `server.js`: Node.js entry point script.
- `.env`: Contains `RESEND_API_KEY`, secrets, and site URLs.
- `public/`: Contains static images and `cv.pdf`.
- `.next/static/`: Contains compiled React CSS/JS bundles.
- `web.config`: Instructs IIS how to handle reverse proxy routing and security filtering.

#### ⚙️ Configuration Steps
1. On `pro-win-server`, open File Explorer → navigate to `C:\inetpub\`.
2. Create new folder named `portfolio` (`C:\inetpub\portfolio\`).
3. Copy these 4 items into `C:\inetpub\portfolio\`:
   - Everything inside `.next/standalone/` ──► `C:\inetpub\portfolio\`
   - `.next/static/` folder ──► `C:\inetpub\portfolio\.next\static\`
   - `public/` folder ──► `C:\inetpub\portfolio\public\`
   - `.env` file ──► `C:\inetpub\portfolio\.env`
4. Create `C:\inetpub\portfolio\web.config` with:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="ReverseProxyInboundRule1" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Rewrite" url="http://localhost:3000/{R:1}" />
                </rule>
            </rules>
        </rewrite>
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

#### ✅ Expected Verification Result
`C:\inetpub\portfolio\` contains `server.js`, `web.config`, `.env`, `public/`, `.next/`, and `node_modules/`.

---

### Step 3: Install Node.js LTS & Enable PM2 24/7 Background Auto-Start

#### 🎯 Objective & Purpose
To run Next.js `server.js` silently in the background 24/7 as a Windows System Service that automatically launches when Windows Server reboots.

#### 🛠️ What it is for
- Node.js LTS: JavaScript runtime environment.
- PM2: Enterprise process manager that monitors `server.js`, auto-restarts on crash, and manages background tasks.
- `pm2-windows-startup`: Registers PM2 into Windows Services (`services.msc`) so `server.js` launches on Windows boot before user login.
- `icacls`: Grants IIS Application Pool workers (`IIS_IUSRS`) write access to server directories.

#### ⚙️ Configuration Steps
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

#### ✅ Expected Verification Result
Running `pm2 status` displays process `Portfolio` with status `online` on Port 3000.

---

### Step 4: Configure IIS Application Request Routing (ARR) Proxy

#### 🎯 Objective & Purpose
To enable IIS's Reverse Proxy engine to receive incoming web requests on Port 80/443 and route them internally to Node.js on `http://localhost:3000`.

#### 🛠️ What it is for
IIS ARR acts as the front-end web gateway. It handles domain name bindings (`portfolio.e6.local`), SSL certificates, and security filtering, while forwarding dynamic requests to Node.js.

#### ⚙️ Configuration Steps
1. Install **URL Rewrite 2.1** and **ARR 3.0** extensions on `pro-win-server`.
2. Open **IIS Manager** → click server name (`WIN-J17IMHCEMA9`).
3. Double-click **Application Request Routing Cache**.
4. In right panel, click **Server Proxy Settings...** → check ✅ **Enable proxy** → click **Apply**.
5. Unlock IIS Handlers section via Command Prompt (Admin):
```cmd
%windir%\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/handlers
```

#### ✅ Expected Verification Result
IIS Manager shows Proxy enabled, and `appcmd` displays `unlocked section "system.webServer/handlers"`.

---

### Step 5: Create IIS Web Site & Reverse Proxy Rules

#### 🎯 Objective & Purpose
To create the `Portfolio` site in IIS Manager bound to domain `portfolio.e6.local` on Port 80 and forward incoming requests to `http://localhost:3000`.

#### 🛠️ What it is for
Host Headers allow multiple websites (`server1.e6.local`, `portfolio.e6.local`) to share standard Port 80 without port conflicts.

#### ⚙️ Configuration Steps
1. In **IIS Manager**, right-click **Sites** → select **Add Website...**
   - **Site name:** `Portfolio`
   - **Physical path:** `C:\inetpub\portfolio`
   - **Port:** `80`
   - **Host name:** `portfolio.e6.local`
2. Click **OK**.
3. Select **Portfolio** site → double-click **URL Rewrite**.
4. Click **Add Rule(s)...** → select **Reverse Proxy**.
5. Inbound server name: `localhost:3000` → click **OK**.

#### ✅ Expected Verification Result
`Portfolio` website appears under Sites in IIS Manager, bound to `http *:80:portfolio.e6.local`.

---

### Step 6: Create DNS Host A Record & Configure Firewall

#### 🎯 Objective & Purpose
To allow all computers on the network to resolve `portfolio.e6.local` → `192.168.1.10` and permit HTTP Port 80 traffic through Windows Firewall.

#### 🛠️ What it is for
- DNS A Record: Translates domain name `portfolio.e6.local` into Server IP `192.168.1.10`.
- Firewall Rule: Opens inbound TCP Port 80 so client computers can reach IIS.

#### ⚙️ Configuration Steps
1. Open **DNS Manager** (**Server Manager → Tools → DNS**).
2. Expand `WIN-J17IMHCEMA9` → **Forward Lookup Zones** → right-click **`e6.local`**.
3. Select **New Host (A or AAAA)...** → Name: `portfolio` | IP: `192.168.1.10` → click **Add Host**.
4. Open PowerShell (Admin) and run:
```powershell
netsh advfirewall firewall add rule name="Allow World Wide Web HTTP Port 80" dir=in action=allow protocol=TCP localport=80
```

#### ✅ Expected Verification Result
Running `nslookup portfolio.e6.local` on client VM resolves to `192.168.1.10`.

---

## 🌐 Testing Matrix

| Client Location | Test URL / Command | Objective & Verification |
|:---|:---|:---|
| **Client VM (`pro-win-client`)** | `http://portfolio.e6.local` | Verifies internal domain resolution, IIS Reverse Proxy, Node.js execution, Resend API, & CV download! |
| **Physical Laptop (hosts file)** | `http://portfolio.e6.local` (with `192.168.100.4 portfolio.e6.local` in `hosts`) | Verifies host-to-VM network bridge and website rendering! |
| **Public Internet (ngrok)** | `ngrok http 127.0.0.1:8080` → `https://xxxx.ngrok-free.app` | Verifies worldwide public access from mobile phones or external networks! |

---

## 🛠️ Troubleshooting Guide

### 1. Error: `HTTP 502 Bad Gateway`
- **Objective / Cause:** Node.js standalone server is not running on Port 3000.
- **Fix:** Run `pm2 start server.js --name "Portfolio"` inside `C:\inetpub\portfolio\`. Check status with `pm2 status`.

### 2. Error: `DNS_PROBE_FINISHED_NXDOMAIN` on Physical Laptop
- **Objective / Cause:** Physical laptop DNS points to Home Wi-Fi router instead of VM DNS (`192.168.1.10`).
- **Fix:** Open `C:\Windows\System32\drivers\etc\hosts` on physical laptop as Admin, add line: `192.168.100.4 portfolio.e6.local`.

### 3. Error: `HTTP 500.19 - 0x80070021`
- **Objective / Cause:** Handlers section locked at IIS server level.
- **Fix:** Run `%windir%\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/handlers` on server.

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
