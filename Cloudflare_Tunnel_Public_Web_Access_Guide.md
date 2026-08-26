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
8. [Step 6: Configure as a 24/7 Permanent Background Service (Windows Task Scheduler ⭐)](#step-6-configure-as-a-247-permanent-background-service-windows-task-scheduler-)
   * [6.3 How to Manually Edit, Validate, and Update config.yml Anytime](#63-how-to-manually-edit-validate-and-update-configyml-anytime)
9. [Step 7: Test & Verify Globally (Phone 4G/5G & Worldwide)](#step-7-test--verify-globally-phone-4g5g--worldwide)
10. [Step 8: How to Stop / Disable Specific Domains & How to Stop All Servers](#step-8-how-to-stop--disable-specific-domains--how-to-stop-all-servers)
11. [Troubleshooting & Handy Maintenance Commands](#troubleshooting--handy-maintenance-commands)

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

---

### 🗺️ The Complete 7-Step Request Lifecycle: From Phone to Your VM

```text
  📱 1. USER ON PHONE (4G/5G in a coffee shop)
        Types: https://portfolio.seang.shop
        │
        ▼
  ☁️ 2. CLOUDFLARE EDGE DATA CENTER (Singapore)
        • Handles the green padlock SSL/TLS encryption 🔒
        • Checks its internal routing table:
          "Where does portfolio.seang.shop go?"
        • Finds: Tunnel ID 5d585308-fb32... (pro-win-tunnel)
        • Sees: "I have 4 open, active QUIC tunnels to Seang's server!"
        │
        ▼  (Encrypted QUIC packet flows down the existing tunnel)
  📦 3. YOUR HOME HUAWEI ROUTER (HG8545M)
        • Firewall allows the packet because YOUR SERVER initiated
          the connection from the inside (Outbound Established State)!
        • Router forwards the packet into your laptop.
        │
        ▼
  💻 4. YOUR PHYSICAL LAPTOP (Windows 11)
        • VMware Workstation Virtual Switch passes packet to the VM.
        │
        ▼
  ⚙️ 5. WINDOWS TASK SCHEDULER (Inside pro-win-server VM)
        • cloudflared.exe (running silently under SYSTEM) catches the packet.
        • Reads config.yml:
          - Changes header to: portfolio.e6.local
          - Forwards traffic to: http://portfolio.e6.local (port 80)
        │
        ▼
  🌐 6. IIS 10 WEB SERVER & NEXT.JS (Port 3000)
        • IIS Reverse Proxy receives the request.
        • Next.js prepares your portfolio page (HTML, CSS, images).
        │
        ▼
  📱 7. RESPONSE FLIES BACK ACROSS THE TUNNEL!
        • In less than 0.08 seconds (80 milliseconds), your portfolio
          displays beautifully on the user's phone screen!
```

---

### 🔍 The 3 "Secret Tricks" That Make This Magic Possible:

1. **The Outbound Tunnel Handshake:** Your home router blocks incoming strangers. But your server contacted Cloudflare **OUT** first. Because the connection started from **inside your house**, your router's firewall happily allows the return traffic!
2. **The HTTP Header Translation (IIS Binding Fix):** The public phone asks for `portfolio.seang.shop`, but your local IIS website only listens for `portfolio.e6.local`. `cloudflared` automatically rewrites the `Host` header to `portfolio.e6.local` before passing it to IIS!
3. **The 24/7 Engine (Windows Task Scheduler):** Runs `cloudflared.exe` in **Session 0** (the invisible background layer of Windows). If your laptop reboots or your VM restarts, the tunnel **starts automatically on boot** before anyone even logs in!

---

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

### 💡 Detailed Explanation of Step 1 Commands:

| Command & Parameter | What It Does & Why It Is Used |
|:---|:---|
| `New-Item -ItemType Directory -Path "C:\cloudflared" -Force` | **Creates the Home Folder:** Creates a clean, dedicated folder `C:\cloudflared\` on the server's primary drive. The `-Force` flag prevents errors if the folder already exists. |
| `Set-Location "C:\cloudflared"` | **Switches Directory:** Changes PowerShell's working directory (`cd`) to `C:\cloudflared\` so all subsequent downloads and commands run directly inside this folder. |
| `Invoke-WebRequest -Uri ... -OutFile ...` | **Downloads the Agent:** Downloads the official, pre-compiled Cloudflare Tunnel agent binary (`cloudflared.exe`) directly from Cloudflare's GitHub releases. The `-OutFile` parameter saves it as an executable ready to run. |

---

## Step 2: Authenticate with Domain (cloudflared login)

Connect your server to your Cloudflare account without needing API keys, credit cards, or passwords:

```powershell
.\cloudflared.exe tunnel login
```

### 💡 Detailed Explanation of Step 2 Command:

* **What it is used for:** Performs a secure, browser-based OAuth authentication handshake between your local Windows Server and Cloudflare's central management systems.
* **How it works behind the scenes:**
  1. `cloudflared` starts a temporary local HTTP listener on your server.
  2. It generates a unique URL and opens your default browser.
  3. You select your registered domain: **`seang.shop`** ──► click **Authorize**.
  4. Cloudflare signs a cryptographic certificate and sends it back to your server.
  5. The certificate is saved as:  
     `C:\Users\Administrator\.cloudflared\cert.pem`
* **Why this is critical:** This `cert.pem` file acts as your **cryptographic passport**. It grants this specific server permission to create and manage tunnels for `seang.shop` forever, without you ever having to type account passwords again!

---

## Step 3: Create the Named Tunnel (tunnel create)

Create the persistent tunnel entity on Cloudflare's global edge network:

```powershell
.\cloudflared.exe tunnel create pro-win-tunnel
```

### 🔍 Live Output:
```text
Tunnel credentials written to C:\Users\Administrator\.cloudflared\5d585308-fb32-48a1-b0c5-13f3b4a478b5.json.
cloudflared chose this file based on where your origin certificate was found. Keep this file secret.

Created tunnel pro-win-tunnel with id 5d585308-fb32-48a1-b0c5-13f3b4a478b5
```

### 💡 Detailed Explanation of Step 3 Command:

* **`tunnel create pro-win-tunnel`:** Tells Cloudflare to allocate a new virtual tunnel named `pro-win-tunnel`.
* **What happens behind the scenes:**
  1. Cloudflare assigns a **Globally Unique Identifier (UUID)** to your tunnel:  
     `5d585308-fb32-48a1-b0c5-13f3b4a478b5`
  2. A private credential file is created:  
     `C:\Users\Administrator\.cloudflared\<TUNNEL-ID>.json`
  3. This `.json` file contains a private encryption secret key. When the tunnel starts, it uses this key to authenticate directly to Cloudflare's edge data centers.

---

## Step 4: Route Public DNS to the Tunnel (tunnel route dns)

Connect your public subdomain to the tunnel automatically:

```powershell
.\cloudflared.exe tunnel route dns pro-win-tunnel portfolio.seang.shop
```

### 🔍 Live Output:
```text
INF Added CNAME portfolio.seang.shop which will route to this tunnel tunnelID=5d585308-fb32-48a1-b0c5-13f3b4a478b5
```

### 💡 Detailed Explanation of Step 4 Command:

* **What it is used for:** Automates DNS management so you do not have to touch the Cloudflare website DNS dashboard!
* **How it works:**  
  * Cloudflare injects a new **CNAME** record into your public DNS zone for `seang.shop`.
  * The record points:  
    `portfolio.seang.shop` ──► `5d585308-fb32-48a1-b0c5-13f3b4a478b5.cfargotunnel.com`
  * Cloudflare automatically enables the **Orange Cloud (Proxy)** 🟧. This ensures all public traffic passes through Cloudflare's DDoS protection and SSL certificate first, keeping your home IP 100% hidden!

---

## Step 5: Run the Tunnel (tunnel run)

Start the tunnel engine to begin bridging public traffic into your local server:

### Method A: Route through IIS Reverse Proxy (`portfolio.e6.local`) ⭐ *(What You Ran!)*

```powershell
.\cloudflared.exe tunnel run --url http://portfolio.e6.local --http-host-header portfolio.e6.local pro-win-tunnel
```

### Method B: Route Directly to Next.js (`localhost:3000`)

```powershell
.\cloudflared.exe tunnel run --url http://localhost:3000 pro-win-tunnel
```

### 💡 Detailed Breakdown of Every Flag in Step 5:

| Flag / Parameter | What It Does & Why It Is Essential |
|:---|:---|
| `tunnel run` | **Starts the Engine:** Instructs `cloudflared` to establish active outgoing tunnels to the nearest Cloudflare global edge servers. |
| `pro-win-tunnel` | **The Tunnel Name:** Identifies which registered tunnel to start using its stored JSON secret key. |
| `--url http://portfolio.e6.local` | **The Destination Service:** Tells Cloudflare where to send incoming web traffic inside your server. In this case, forward it to your local IIS site `http://portfolio.e6.local`! |
| `--http-host-header portfolio.e6.local` | **Host Header Rewriter (Crucial for IIS!):** When a visitor visits `https://portfolio.seang.shop`, their browser sends `Host: portfolio.seang.shop`. Since your IIS web server has site bindings listening specifically for `portfolio.e6.local`, this flag rewrites the HTTP header so IIS recognizes the request and displays your website! |

### 🔍 Live Output (Global Edge Connections):
```text
INF Precheck complete hard_fail=false suggested_protocol=quic
INF Registered tunnel connection connIndex=0 location=sin16 protocol=quic
INF Registered tunnel connection connIndex=1 location=sin15 protocol=quic
INF Registered tunnel connection connIndex=2 location=sin09 protocol=quic
INF Registered tunnel connection connIndex=3 location=sin02 protocol=quic
```

* 🟢 **Technical Meaning:** Your server has established **4 parallel, redundant QUIC (UDP 443) tunnels** to Cloudflare edge data centers in Singapore (`sin`). If one connection hiccups, traffic automatically switches to the others with zero downtime!

---

## Step 6: Configure as a 24/7 Permanent Background Service (Windows Task Scheduler ⭐)

Currently, if you close the PowerShell window, the tunnel stops. Follow these steps to make it run **permanently in the background 24/7**:

### 6.1 Create the Configuration File (`config.yml`)
In PowerShell, run:

```powershell
# Copy credentials into C:\cloudflared
Copy-Item "C:\Users\Administrator\.cloudflared\*" -Destination "C:\cloudflared\" -Force

# Create the clean configuration file
@"
tunnel: 5d585308-fb32-48a1-b0c5-13f3b4a478b5
credentials-file: C:\cloudflared\5d585308-fb32-48a1-b0c5-13f3b4a478b5.json

ingress:
  - hostname: portfolio.seang.shop
    service: http://portfolio.e6.local
    originRequest:
      httpHostHeader: portfolio.e6.local
  - service: http_status:404
"@ | Out-File -FilePath "C:\cloudflared\config.yml" -Encoding ascii
```

### 💡 Detailed Explanation of `config.yml`:

| Configuration Key | What It Does |
|:---|:---|
| `tunnel: 5d585308-...` | Identifies your tunnel UUID. |
| `credentials-file: ...` | Specifies the path to the private key JSON file required to authenticate. |
| `ingress:` | Defines the routing table rules for incoming requests. |
| `- hostname: portfolio.seang.shop` | Matches incoming traffic directed to `portfolio.seang.shop`. |
| `service: http://portfolio.e6.local` | Forwards matching requests to your local IIS web server. |
| `originRequest.httpHostHeader` | Injects the required IIS hostname header (`portfolio.e6.local`). |
| `- service: http_status:404` | Catch-all rule: any unmatched requests receive a clean 404 Not Found error. |

---

#### ❓ Deep-Dive: Why Did We Copy Files from `C:\Users\Administrator\.cloudflared\` to `C:\cloudflared\`?

> [!IMPORTANT]
> 🔐 **The Golden Rule of Windows System Administration:**  
> *"A background 24/7 service must NEVER depend on files trapped inside an individual user's personal profile folder!"*

##### 1. Where did Cloudflare put the files originally?
When you ran `tunnel login` and `tunnel create`, Cloudflare placed your secret files in your personal user profile folder:
📁 `C:\Users\Administrator\.cloudflared\`
* `cert.pem`
* `5d585308-fb32-48a1-b0c5-13f3b4a478b5.json`

##### 2. The Danger of Leaving Them in `C:\Users\Administrator\` ⚠️:
Our 24/7 background task is executed by **`NT AUTHORITY\SYSTEM`** (the Windows Operating System itself) so that it runs before anyone logs in. Leaving the files inside `C:\Users\Administrator\` causes 3 severe problems:
* **User Profile Unloading:** When you click *Sign Out* or switch users, Windows can unload and lock the `C:\Users\Administrator\` profile, cutting off the background service!
* **Permission Conflicts:** Windows security policies often block background system accounts from reading private files inside individual personal user directories.
* **Scattered Files:** Your program was in `C:\cloudflared\`, but its secret keys were hidden in `C:\Users\Administrator\.cloudflared\`. If someone moves or cleans up the Administrator folder, the tunnel breaks!

##### 3. The Solution: A Self-Contained "All-in-One" Folder 📦:
By copying everything into `C:\cloudflared\`, the entire Cloudflare Tunnel becomes **100% self-contained in one clean directory**:

```text
  📁 C:\cloudflared\
  ├── ⚙️ cloudflared.exe                                  (The Program)
  ├── 📄 config.yml                                       (The Routing Rules)
  ├── 🔑 5d585308-fb32-48a1-b0c5-13f3b4a478b5.json       (The Secret Key)
  └── 📜 cert.pem                                         (The Certificate)
```

**Benefits:**
* **The `SYSTEM` account** has 100% full, permanent access to `C:\cloudflared\`.
* **Zero permission issues:** Works whether Administrator is logged in, logged off, or the machine just rebooted.
* **Easy Backups:** If you ever want to backup your tunnel, you just copy **one single folder**: `C:\cloudflared\`!

---

### 6.2 Register the 24/7 Task via Windows Task Scheduler

> [!NOTE]
> 🔍 **Why Task Scheduler instead of `cloudflared service install`?**  
> On Windows Server 2022, `cloudflared service install` frequently fails with `StartServiceFailed` because Windows SCM expects an internal ServiceMain dispatcher, whereas `cloudflared` requires the `tunnel run` subcommand.  
> **Windows Task Scheduler** is the **100% bulletproof enterprise standard**: it runs the exact working command (`tunnel run`) silently under `NT AUTHORITY\SYSTEM` at system boot!

Run this in PowerShell:

```powershell
# 1. Define the action to run our proven working command
$action = New-ScheduledTaskAction -Execute "C:\cloudflared\cloudflared.exe" -Argument '--config "C:\cloudflared\config.yml" tunnel run'

# 2. Trigger: Run automatically at system startup (Before any user logs in!)
$trigger = New-ScheduledTaskTrigger -AtStartup

# 3. Principal: Run with highest privileges under the SYSTEM account
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# 4. Register and save the task in Windows
Register-ScheduledTask -TaskName "CloudflareTunnel247" -Action $action -Trigger $trigger -Principal $principal -Description "24/7 Cloudflare Tunnel for portfolio.seang.shop" -Force

# 5. Start the task immediately!
Start-ScheduledTask -TaskName "CloudflareTunnel247"

# 6. Verify status
Get-ScheduledTask -TaskName "CloudflareTunnel247"
```

### 🔍 Live Output:
```text
TaskPath       TaskName              State
--------       --------              -----
\              CloudflareTunnel247   Running
```

* 🎉 **Result:** The tunnel is now running 24/7 in the background! You can close PowerShell, log off, or restart the server—it will boot automatically!

---

### 💡 Detailed Breakdown of the 6 Scheduled Task Commands:

In Windows systems engineering, every scheduled task consists of **3 Core Building Blocks**:
* 🎯 **Action:** WHAT to execute (the executable binary and its arguments)
* ⏰ **Trigger:** WHEN to execute (boot, schedule, or event)
* 👤 **Principal:** WHO executes it (user identity and security privilege)

| Line # | Command & Parameter | Deep-Dive Technical Explanation |
|:---:|:---|:---|
| **1** | `New-ScheduledTaskAction`<br>`-Execute "C:\cloudflared\cloudflared.exe"`<br>`-Argument '--config "C:\cloudflared\config.yml" tunnel run'` | **The Action (WHAT to run):**<br>• `-Execute`: Defines the exact binary file path to launch.<br>• `-Argument`: Passes the command-line parameters that instruct `cloudflared` to load `C:\cloudflared\config.yml` and execute the `tunnel run` subcommand. |
| **2** | `New-ScheduledTaskTrigger`<br>`-AtStartup` | **The Trigger (WHEN to run):**<br>• `-AtStartup`: Instructs the Windows kernel to launch this task immediately when the server boots up, **BEFORE any user logs in or types a password**! This guarantees 24/7 uptime during unattended server reboots. |
| **3** | `New-ScheduledTaskPrincipal`<br>`-UserId "SYSTEM"`<br>`-LogonType ServiceAccount`<br>`-RunLevel Highest` | **The Principal (WHO runs it):**<br>• `-UserId "SYSTEM"`: Runs under the `NT AUTHORITY\SYSTEM` OS kernel account (unrestricted local access, no password, never expires).<br>• `-LogonType ServiceAccount`: Declares it as a background service daemon (no interactive desktop UI).<br>• `-RunLevel Highest`: Bypasses UAC elevation limits and runs with full administrative kernel rights. |
| **4** | `Register-ScheduledTask`<br>`-TaskName "CloudflareTunnel247"`<br>`-Action $action`<br>`-Trigger $trigger`<br>`-Principal $principal`<br>`-Force` | **The Registration (SAVE into Windows):**<br>• Combines the Action + Trigger + Principal and permanently writes the task into the Windows Task Scheduler database (`C:\Windows\System32\Tasks\CloudflareTunnel247`).<br>• `-Force`: Overwrites any previous configuration cleanly without errors. |
| **5** | `Start-ScheduledTask`<br>`-TaskName "CloudflareTunnel247"` | **Immediate Execution:**<br>• Instead of waiting for the next server reboot, this kicks off the task immediately in the background. |
| **6** | `Get-ScheduledTask`<br>`-TaskName "CloudflareTunnel247"` | **Status Verification:**<br>• Queries the Windows Task Scheduler engine and returns `State: Running`, confirming the daemon is actively bridging public traffic! |

---

#### 💾 Deep-Dive: Is This Script Stored Permanently in Windows?

> [!NOTE]
> **YES! 100% PERMANENT!**  
> Running `Register-ScheduledTask` does **NOT** store temporary state in RAM. It permanently writes configuration files to your hard drive and registers entries into the Windows Registry!

##### 1. Where is it Physically Stored?
* **On the Hard Disk (XML Blueprint):** `C:\Windows\System32\Tasks\CloudflareTunnel247`
* **In the Windows Registry:** `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\`
* **In the Windows GUI:** Press `Win + R` ──► type `taskschd.msc` ──► click **Task Scheduler Library** ──► you will see **`CloudflareTunnel247`** with `Status: Running`, `Triggers: At system startup`, and `User: SYSTEM`!

##### 2. How it Behaves Across Common Scenarios:

| Scenario | What Happens to Your 24/7 Tunnel? |
|:---|:---|
| **You close the PowerShell window** | 🟢 **Stays 100% Running!** (The task is completely decoupled from PowerShell). |
| **You log off / Sign out of Administrator** | 🟢 **Stays 100% Running!** (It runs under `SYSTEM`, not the Administrator profile). |
| **You restart the VM (`shutdown /r /t 0`)** | 🟢 **Starts automatically on boot** before any user types a password! |
| **You turn off your laptop and boot it next week** | 🟢 **Starts automatically as soon as the VM powers on!** |

##### 3. How to Remove the Task (If ever needed in the future):
```powershell
Unregister-ScheduledTask -TaskName "CloudflareTunnel247" -Confirm:$false
```

---

### 6.3 How to Manually Edit, Validate, and Update `config.yml` Anytime

When you want to edit your website routing, add new subdomains (e.g. `api.seang.shop`), or change ports, follow this 3-step workflow:

#### 1. Open the file in Notepad:
Press **`Win + R`** ──► type:
```cmd
notepad C:\cloudflared\config.yml
```
*(Make your edits and press `Ctrl + S` to save).*

#### ⚠️ YAML Formatting Rules:
* **Never use TAB keys!** Always use **2 spaces** for indentation.
* **Catch-All Rule:** The last line **MUST** always remain:  
  `- service: http_status:404`

#### 2. Validate for Syntax Errors:
Before restarting the tunnel, test that your YAML syntax is valid:
```powershell
C:\cloudflared\cloudflared.exe --config "C:\cloudflared\config.yml" tunnel ingress validate
```
* Expected output: 🟢 **`Validating rules from C:\cloudflared\config.yml... OK`**

#### 3. Restart the 24/7 Task to Apply Changes:
```powershell
# Restart the task
Stop-ScheduledTask -TaskName "CloudflareTunnel247"
Start-ScheduledTask -TaskName "CloudflareTunnel247"

# Verify it is running
Get-ScheduledTask -TaskName "CloudflareTunnel247"
```

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

## Step 8: How to Stop / Disable Specific Domains & How to Stop All Servers

Depending on your maintenance needs, here is how to stop specific websites or shut down all server services:

### 1️⃣ Scenario 1: Stop ONE Specific Domain (Keep other websites online)
If you have multiple subdomains running and you want to temporarily take down **only one** (e.g. `portfolio.seang.shop`):

1. Open `config.yml`:
   ```cmd
   notepad C:\cloudflared\config.yml
   ```
2. Comment out the rules for that specific domain with `#`:
   ```yaml
   ingress:
     # Temporarily disabled:
     # - hostname: portfolio.seang.shop
     #   service: http://portfolio.e6.local
     #   originRequest:
     #     httpHostHeader: portfolio.e6.local

     # Other services remain active:
     # - hostname: api.seang.shop
     #   service: http://localhost:5000

     - service: http_status:404
   ```
3. Restart the background task:
   ```powershell
   Stop-ScheduledTask -TaskName "CloudflareTunnel247"
   Start-ScheduledTask -TaskName "CloudflareTunnel247"
   ```
* 🟢 **Result:** Visitors to `portfolio.seang.shop` receive a clean `404 Not Found`, while other websites remain live!
* 👉 **To restore:** Remove the `#` comments and restart the task.

---

### 2️⃣ Scenario 2: Emergency Public Kill-Switch (Stop ALL Public Access Instantly)
If you want to immediately sever all public internet access to your server:

```powershell
# Stop the 24/7 tunnel immediately
Stop-ScheduledTask -TaskName "CloudflareTunnel247"
```
* 🟢 **Result:** All incoming internet traffic is instantly cut off. Public visitors see `Error 1033: Site Offline`.
* 👉 **To restore public access:**
  ```powershell
  Start-ScheduledTask -TaskName "CloudflareTunnel247"
  ```

---

### 3️⃣ Scenario 3: Stop Web & Application Servers (Local Maintenance)
If you want to stop the local web services without touching the tunnel:

```powershell
# Stop Next.js (PM2 Node.js process manager)
pm2 stop all

# Stop IIS 10 Web Server completely
iisreset /stop
```
* 🟢 **Result:** Cloudflare returns `Error 502: Bad Gateway` (informing visitors the server is undergoing maintenance).
* 👉 **To restart local web servers:**
  ```powershell
  pm2 start all
  iisreset /start
  ```

---

### 4️⃣ Scenario 4: Stop Database Servers (PostgreSQL & Oracle)
To pause database engines to free up RAM or perform maintenance:

```powershell
# Stop PostgreSQL 18 Service
Stop-Service postgresql*

# Stop Oracle 19c Database & TNS Listener
Stop-Service OracleService*
Stop-Service Oracle*TNSListener
```
* 👉 **To restart databases:**
  ```powershell
  Start-Service postgresql*
  Start-Service OracleService*
  Start-Service Oracle*TNSListener
  ```

---

### 5️⃣ Scenario 5: How to Stop / Restart the ENTIRE Server Gracefully
To cleanly shut down or reboot the Windows Server VM:

```powershell
# Gracefully restart the server VM
Restart-Computer -Force

# Gracefully shut down the server VM completely
Stop-Computer -Force
```

---

### 📊 Master Server Management Cheat-Sheet:

| Action | PowerShell Command |
|:---|:---|
| **Stop 1 domain** | Comment out domain in `C:\cloudflared\config.yml` ──► restart task |
| **Stop Public Tunnel (Kill-Switch)** | `Stop-ScheduledTask -TaskName "CloudflareTunnel247"` |
| **Start Public Tunnel** | `Start-ScheduledTask -TaskName "CloudflareTunnel247"` |
| **Stop Next.js (PM2)** | `pm2 stop all` |
| **Start Next.js (PM2)** | `pm2 start all` |
| **Stop IIS Web Server** | `iisreset /stop` |
| **Start IIS Web Server** | `iisreset /start` |
| **Stop PostgreSQL** | `Stop-Service postgresql*` |
| **Stop Oracle Database** | `Stop-Service OracleService*`, `Stop-Service Oracle*TNSListener` |
| **Reboot Entire Server** | `Restart-Computer -Force` |
| **Shutdown Entire Server** | `Stop-Computer -Force` |

---

## 11. Troubleshooting & Handy Maintenance Commands

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
