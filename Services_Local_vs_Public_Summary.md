# Windows Server Services: Local vs. Public Scope Summary

This document summarizes all 14 server roles and services you will deploy, explaining whether each service is designed for **LOCAL (Internal LAN)** or **PUBLIC (Internet)** users.

---

## Service Summary Matrix

| # | Service | Lab Setting | Real-World Usage | Scope Explanation |
|:---|:---|:---|:---|:---|
| **1** | **File Server (SMB)** | 🏠 **LOCAL** | 🏠 **LOCAL** | Shared folders (`\\server1.e6.local`) are kept strictly inside the company local network for data security. |
| **2** | **Web Server (IIS)** | 🏠 **LOCAL** | 🌐 **BOTH** | Hosts web apps. Internal company portals (Intranets) are Local; public websites are Public. |
| **3** | **Mail Server** | 🏠 **LOCAL** | 🌐 **BOTH** | Internal email between domain users (`user@e6.local`) is Local; sending to Gmail/Yahoo uses Public DNS/MX. |
| **4** | **FTP Server** | 🏠 **LOCAL** | 🌐 **BOTH** | Internal file transfers are Local; public file repositories (e.g. software downloads) are Public. |
| **5** | **VPN Server** | 🌐 **PUBLIC Door → LOCAL Net** | 🌐 **PUBLIC Door → LOCAL Net** | Listens on the Public Internet so remote workers can securely encrypt and enter the Local company LAN. |
| **6** | **RADIUS Server (NPS)** | 🏠 **LOCAL** | 🏠 **LOCAL** | Centralized AAA authentication for local corporate Wi-Fi, switches, and VPN connections. |
| **7** | **Terminal Server (RDS)** | 🏠 **LOCAL** | 🏠 **LOCAL / VPN** | Lets users log into remote desktop sessions to access internal company software. |
| **8** | **Load Balancing (NLB)** | 🏠 **LOCAL** | 🌐 **BOTH** | Distributes incoming traffic across multiple backend web servers (Local or Public). |
| **9** | **Failover Cluster** | 🏠 **LOCAL** | 🏠 **LOCAL** | High-availability cluster where multiple nodes share workload locally if one server fails. |
| **10** | **DHCP Server** | 🏠 **LOCAL** | 🏠 **LOCAL** | Automatically assigns private local IPs (`192.168.1.100 - .200`) to local clients. |
| **11** | **DNS Server** | 🏠 **LOCAL (+ Forwarder)**| 🏠 **LOCAL (+ Forwarder)**| Resolves internal domain names (`e6.local`) locally; forwards public sites (`google.com`) to 8.8.8.8. |
| **12** | **Proxy Server** | 🏠 **LOCAL** | 🏠 **LOCAL** | Middleman inside the local LAN that monitors, filters, and logs outbound web traffic to the internet. |
| **13** | **Backup Server** | 🏠 **LOCAL** | 🏠 **LOCAL** | Backs up server volumes, Active Directory, and databases to local disk storage. |
| **14** | **Database Server (PostgreSQL)**| 🏠 **LOCAL** | 🏠 **LOCAL** | Backend database kept hidden inside the local LAN behind web applications for security. |

---

## Why This Architecture is Enterprise Best Practice

In large enterprise companies (banks, tech corporations, hospitals), this design follows the **Defense-in-Depth (Castle & Moat)** security model.

```
🌐 PUBLIC INTERNET  ──►  [ Firewall / DMZ ]  ──►  🔒 INTERNAL LOCAL LAN
    (Untrusted)          - VPN Gateway            (Trusted Zone)
                         - Public Web             - Active Directory / DNS
                                                  - File & Database Servers
                                                  - DHCP & Radius Servers
```

### 1. Ransomware & Cyberattack Protection
- **WannaCry & SMB Attacks:** If SMB File Sharing (Port 445) is exposed to the public internet, hackers use automated bots to scan and infect your servers with ransomware within minutes.
- **Database Leaks:** Backend databases (PostgreSQL/Oracle) containing credit cards and customer records are kept **strictly inside the Local LAN** behind Web servers. A database should NEVER have a public IP.

### 2. Active Directory Security
- Your Domain Controller (`e6.local`) holds every employee's username and password hash.
- Keeping Active Directory local prevents attackers on the internet from brute-forcing admin passwords or running Kerberos attacks.

### 3. Preventing Man-in-the-Middle (Rogue DHCP)
- DHCP relies on network broadcasts (`DORA`). If DHCP were public, external attackers could respond with fake gateway IPs and intercept all company traffic.

---

## How Enterprise Companies Handle Remote Workers

When employees work from home or travel:
1. They launch a **VPN Client** (e.g. WireGuard, Cisco AnyConnect, FortiClient).
2. The **VPN Gateway** authenticates them against the **RADIUS (NPS)** server using Active Directory credentials + Multi-Factor Authentication (MFA).
3. Once authenticated, an encrypted tunnel bridges the employee directly into the **Internal Local LAN** (`192.168.1.x`), giving them secure access to File Servers, Databases, and Terminal Servers as if sitting at their office desk.

---

## The Difference Between DHCP and Active Directory Membership

| Action | What it does | Where the computer appears |
|:---|:---|:---|
| **1. Request DHCP IP** (`ipconfig /renew`) | Gives the client a temporary network address (`192.168.1.100`). | Appears in **DHCP Manager → Address Leases** |
| **2. Join Domain** (System Settings → Domain Join) | Registers the client computer into the Active Directory database as an official domain member. | Appears in **Active Directory Users and Computers → Computers** |

### Real-World Analogy:
- **Getting a DHCP IP** is like getting a **parking ticket at a parking lot**. It lets the computer stand on the network, but the company doesn't know who owns it yet.
- **Joining the Domain** is like **signing a job contract**. It registers the computer as an official device managed by your Windows Server.

---

## How to Make Your Client Computer Appear in Active Directory

Perform these steps on your **Client VM (`pro-win-client`)**:

1. Press `Win + R` → type `sysdm.cpl` → press **Enter** *(opens System Properties)*.
2. Under the **Computer Name** tab, click **Change...**
3. Under *Member of*, select **Domain** → type:
   ```text
   e6.local
   ```
4. Click **OK**.
5. When prompted for credentials, type:
   - **Username:** `E6\Administrator` (or `Administrator`)
   - **Password:** *(your domain admin password)*
6. Click **OK**. You will see a popup: *"Welcome to the e6.local domain!"*
7. Click **OK** and **Restart** the Client VM.

---

## Verify Active Directory Membership on Windows Server

After restarting the Client VM:

1. Open **Active Directory Users and Computers** on `pro-win-server` (`Server Manager → Tools → Active Directory Users and Computers`).
2. Expand `e6.local` → click **Computers**.
3. 🎉 You will now see your client computer (`CLIENT`) listed inside Active Directory!
