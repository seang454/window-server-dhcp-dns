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

---

## Architecture Diagram

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
