# Step 6: VPN Server (RRAS) & RADIUS Server (NPS) — Complete Deep-Dive Concept Guide

**Windows Server 2022 on VMware Workstation**  
**Domain:** `e6.local`  
**Server:** `WIN-J17IMHCEMA9` (`pro-win-server` at `192.168.1.10`)  
**Client:** `CLIENT` (`pro-win-client` at `192.168.1.100`)

---

## 📖 Table of Contents

1. [What is a VPN Server (RRAS)?](#1-what-is-a-vpn-server-rras)
2. [What is a RADIUS Server (NPS)?](#2-what-is-a-radius-server-nps)
3. [Objective & Purpose of Each Server](#3-objective--purpose-of-each-server)
4. [What Are They Used For? (Real-World Use Cases)](#4-what-are-they-used-for-real-world-use-cases)
5. [Advantages of VPN + RADIUS](#5-advantages-of-vpn--radius)
6. [What Happens WITH vs WITHOUT Them](#6-what-happens-with-vs-without-them)
7. [How Each One Works Internally (Deep Technical Breakdown)](#7-how-each-one-works-internally-deep-technical-breakdown)
8. [How VPN and RADIUS Work Together (Combined Flow)](#8-how-vpn-and-radius-work-together-combined-flow)
9. [Full Abbreviation & Terminology Glossary](#9-full-abbreviation--terminology-glossary)

---

## 1. What is a VPN Server (RRAS)?

### 📝 Full Name Breakdown:
* **VPN** = **V**irtual **P**rivate **N**etwork
* **RRAS** = **R**outing and **R**emote **A**ccess **S**ervice (the Windows Server component that implements VPN)

### 🎯 Definition:
A VPN Server is a piece of software running on Windows Server that creates **secure, encrypted network tunnels** over the public Internet. It allows remote users (employees working from home, traveling, or in coffee shops) to connect to the company's **internal private network** (`192.168.1.0/24`) as if they were physically sitting inside the office and plugged into the office network switch with an Ethernet cable.

### 🏨 Simple Analogy: The Secret Underground Tunnel
Imagine your company office is a **fortified castle** surrounded by walls:
* The employees inside the castle (office) can freely access all rooms (servers, databases, file shares).
* Employees **outside** the castle (working from home) **cannot** reach any room because the castle walls (firewall/NAT) block them.
* A **VPN Server** builds a **secret underground encrypted tunnel** from the employee's home, through the dangerous public Internet, directly into the castle!
* Once inside the tunnel, the employee can access every room as if they were physically inside the castle!

---

## 2. What is a RADIUS Server (NPS)?

### 📝 Full Name Breakdown:
* **RADIUS** = **R**emote **A**uthentication **D**ial-**I**n **U**ser **S**ervice (Industry standard protocol, RFC 2865 / 2866)
* **NPS** = **N**etwork **P**olicy **S**erver (Microsoft's implementation of the RADIUS standard built into Windows Server)
* **AAA** = **A**uthentication, **A**uthorization, **A**ccounting (The 3 security pillars that RADIUS provides)

### 🎯 Definition:
A RADIUS Server is the **central security brain and gatekeeper** for the entire enterprise network. Instead of every VPN server, Wi-Fi access point, and network switch independently storing and checking user passwords, they ALL forward authentication requests to **ONE central RADIUS Server**. The RADIUS Server checks user credentials against **Active Directory** and responds with either **"Access-Accept"** (allow the user) or **"Access-Reject"** (block the user).

### 🏨 Simple Analogy: The Master Security Control Room
Imagine a large company headquarters with:
* 3 entrance doors (VPN servers)
* 10 Wi-Fi access points
* 5 restricted floor gates (firewalls)

**WITHOUT a RADIUS Server:** Each door, each Wi-Fi router, and each gate has its own separate guest list. When a new employee joins, the IT admin must add their name to **18 different guest lists**! When someone quits, they must delete the name from **18 different places**!

**WITH a RADIUS Server:** There is **ONE Master Security Control Room** (the RADIUS Server). All 18 doors and gates radio the control room: *"Employee `s.pengseang` is requesting access. Should I let them in?"* The control room checks the **single master list** (Active Directory) and radios back: *"Access Granted!"* or *"Access Denied!"*

---

## 3. Objective & Purpose of Each Server

### 🛡️ VPN Server (RRAS) — Objectives:

| Objective | Description |
|:---|:---|
| **Secure Remote Access** | Allow employees to work remotely from anywhere in the world and access internal company resources securely. |
| **Data Encryption** | Encrypt ALL network traffic between the remote client and the office so that hackers on public Wi-Fi cannot read passwords, emails, or database queries. |
| **Network Extension** | Extend the company's private LAN (`192.168.1.0/24`) to remote workers by assigning them a virtual internal IP address (e.g. `192.168.1.221`). |
| **Bypass Geographic Restrictions** | Remote workers appear as if they are physically inside the office network, bypassing firewalls and NAT restrictions. |
| **Cost Reduction** | Eliminates the need for expensive dedicated leased lines between branch offices; uses the public Internet instead. |

### 🔐 RADIUS Server (NPS) — Objectives:

| Objective | Description |
|:---|:---|
| **Centralized Authentication** | ONE single point validates ALL network login requests (VPN, Wi-Fi, wired LAN) against Active Directory. |
| **Centralized Authorization** | Define WHO can access WHAT, WHEN, and HOW through Network Policies (e.g. "Only the Engineering group can use VPN on weekdays"). |
| **Centralized Accounting** | Log and audit EVERY connection: who connected, when, how long, how much data was transferred, and when they disconnected. |
| **Compliance & Auditing** | Meets enterprise compliance requirements (ISO 27001, HIPAA, PCI-DSS) by maintaining a centralized audit trail. |
| **Simplified Administration** | Add or remove employee access in ONE place (Active Directory) instead of configuring dozens of network devices individually. |

---

## 4. What Are They Used For? (Real-World Use Cases)

### 🛡️ VPN Server (RRAS) — Real-World Use Cases:

#### Use Case 1: Work From Home (WFH) During COVID-19
During the COVID-19 pandemic, millions of office workers had to work from home. Companies used VPN servers to let employees securely connect to:
* Internal file shares (`\\server\accounting\reports`)
* Internal databases (Oracle, PostgreSQL)
* Internal web applications (ERP, CRM)
* Internal email servers

Without VPN, these internal resources are **invisible** from the public Internet!

#### Use Case 2: Branch Office Interconnection (Site-to-Site VPN)
A company with offices in Phnom Penh and Siem Reap uses a **Site-to-Site VPN tunnel** between the two office servers. Employees in Siem Reap can access the Phnom Penh file server as if both offices were on the same local network!

#### Use Case 3: Traveling Sales Team
Sales representatives visiting clients in different cities connect to the company VPN from hotel Wi-Fi to access the internal CRM system and customer database securely.

#### Use Case 4: IT Administrator Remote Server Management
System administrators connect via VPN from home at 2 AM to fix a critical server issue, using RDP through the VPN tunnel to manage the Domain Controller.

---

### 🔐 RADIUS Server (NPS) — Real-World Use Cases:

#### Use Case 1: Enterprise Wi-Fi Authentication (WPA2-Enterprise / 802.1X)
In large companies, Wi-Fi access points do NOT use a simple shared password. Instead:
* Employee connects to Wi-Fi ──► Wi-Fi AP asks RADIUS Server (NPS) ──► NPS checks Active Directory ──► Grants or Denies access!
* When an employee is fired, IT disables their AD account ──► They are **instantly blocked from ALL Wi-Fi** across every building, every floor, every access point!

#### Use Case 2: VPN Authentication (Our Lab Setup!)
* Remote client connects to VPN Server (RRAS) ──► RRAS sends RADIUS request to NPS ──► NPS validates `s.pengseang`'s password against Active Directory ──► Access Granted!

#### Use Case 3: Network Switch Port Authentication (802.1X Wired)
In high-security environments (banks, government), even plugging an Ethernet cable into a wall port requires RADIUS authentication. Unknown devices are quarantined!

#### Use Case 4: Time-Based Access Control
A university configures NPS to only allow student Wi-Fi access between 7 AM – 10 PM. After 10 PM, all student accounts are automatically blocked!

---

## 5. Advantages of VPN + RADIUS

### 🛡️ VPN Server Advantages:

| Advantage | Explanation |
|:---|:---|
| 🔒 **End-to-End Encryption** | All data traveling between the remote employee and the office is encrypted (AES-256 / SSL/TLS). Even if a hacker intercepts the Wi-Fi traffic, they see only **scrambled unreadable data**! |
| 🌍 **Access From Anywhere** | Employees can connect from any country, any hotel, any airport. As long as they have Internet, they can reach the office network. |
| 💰 **Cost Savings** | No need to purchase expensive MPLS dedicated leased lines between offices. VPN uses the existing cheap public Internet! |
| 🏠 **Enables Work From Home** | Critical for business continuity (pandemics, natural disasters, office renovations). |
| 🛡️ **Network Isolation** | VPN users only access what the administrator permits. Unauthorized traffic is blocked by the VPN firewall rules. |

### 🔐 RADIUS Server (NPS) Advantages:

| Advantage | Explanation |
|:---|:---|
| 🎯 **Single Point of Control** | Manage ALL network access (VPN + Wi-Fi + Wired) from ONE console. No need to log into 50 different routers! |
| 👤 **Active Directory Integration** | Leverages existing domain user accounts. No separate password databases to maintain! |
| 📋 **Network Policies** | Create granular rules: "Allow VPN only for the `Engineering` group during weekdays" or "Block VPN for `Intern` accounts after 6 PM". |
| 📊 **Accounting & Audit Logs** | Every login attempt is logged with timestamp, duration, bytes transferred, and reason for acceptance/rejection. |
| ⚡ **Instant Employee Termination** | When HR fires an employee and IT disables their AD account, they are **instantly locked out** of VPN, Wi-Fi, wired LAN, and every RADIUS-protected resource simultaneously! |

---

## 6. What Happens WITH vs WITHOUT Them

### 🛡️ VPN Server: WITH vs WITHOUT

```
WITHOUT VPN ❌ (The Dangerous Nightmare):
══════════════════════════════════════════════════════════════════════════

  👤 Employee at Home                           🏢 Company Office Network
  (Public IP: 103.45.67.89)                     (Private: 192.168.1.0/24)
       │                                              │
       │  "I want to access \\server\finance\"         │
       ▼                                              ▼
  ┌──────────┐                                ┌──────────────────┐
  │  Laptop  │ ─── Public Internet ───────── │ Company Firewall │
  └──────────┘     (UNENCRYPTED!)              └──────────────────┘
       │                                              │
       │  ❌ BLOCKED! The firewall does NOT            │
       │     allow random Internet IPs to              │
       │     access internal file shares!              │
       │                                              │
       │  🔓 Even if it COULD connect, all            │
       │     traffic (passwords, files, emails)        │
       │     travels UNENCRYPTED through               │
       │     the public Internet!                      │
       │                                              │
       │  👀 Hackers on the same coffee shop           │
       │     Wi-Fi can intercept and read              │
       │     EVERYTHING with Wireshark!                │
       ▼                                              │
  ❌ CANNOT WORK FROM HOME!                           │
  ❌ CANNOT ACCESS INTERNAL RESOURCES!                │
  ❌ PASSWORDS EXPOSED ON PUBLIC NETWORKS!            │


WITH VPN ✅ (The Secure Enterprise Solution):
══════════════════════════════════════════════════════════════════════════

  👤 Employee at Home                           🏢 Company Office Network
  (Public IP: 103.45.67.89)                     (Private: 192.168.1.0/24)
       │                                              │
       ▼                                              ▼
  ┌──────────┐    ╔══════════════════════╗    ┌──────────────────┐
  │  Laptop  │════║ ENCRYPTED VPN TUNNEL ║════│ VPN Server (RRAS)│
  │          │    ║ (AES-256 / SSL/TLS)  ║    │ 192.168.1.10     │
  └──────────┘    ╚══════════════════════╝    └──────────────────┘
       │                                              │
  Virtual IP assigned: 192.168.1.221                  │
       │                                              │
       │  ✅ Laptop is now INSIDE the office!          │
       │  ✅ Can access \\server\finance\              │
       │  ✅ Can access Oracle DB on port 1521         │
       │  ✅ Can access PostgreSQL on port 5432        │
       │  ✅ Can RDP into servers via mstsc             │
       │  ✅ ALL traffic is 100% ENCRYPTED!            │
       │  ✅ Hackers see only scrambled gibberish!      │
       ▼                                              │
  🟢 FULL SECURE ACCESS TO ENTIRE OFFICE NETWORK!     │
```

---

### 🔐 RADIUS Server: WITH vs WITHOUT

```
WITHOUT RADIUS ❌ (The Administrative Nightmare):
══════════════════════════════════════════════════════════════════════════

                    Each device has its OWN separate user database!
                    
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ VPN Server 1 │  │ VPN Server 2 │  │ Wi-Fi AP #1  │  │ Wi-Fi AP #2  │
  │              │  │              │  │              │  │              │
  │ Users:       │  │ Users:       │  │ Users:       │  │ Users:       │
  │ • s.pengseang│  │ • s.pengseang│  │ • s.pengseang│  │ • s.pengseang│
  │ • s.pengsorng│  │ • s.pengsorng│  │ • s.pengsorng│  │ • s.pengsorng│
  │ • alice      │  │ • alice      │  │ • alice      │  │ • alice      │
  │ • john       │  │ • john       │  │ • john       │  │ • john       │
  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
  
  ⚠️ Employee "alice" is FIRED today!
  IT Admin must now:
   1. Log into VPN Server 1 ──► Delete alice
   2. Log into VPN Server 2 ──► Delete alice
   3. Log into Wi-Fi AP #1  ──► Delete alice
   4. Log into Wi-Fi AP #2  ──► Delete alice
   5. Log into 16 more devices ──► Delete alice from EACH one!
   
  ❌ If IT forgets even ONE device, alice still has secret access!
  ❌ If alice changes password, IT must update 20 devices!
  ❌ No central audit log of who connected where and when!


WITH RADIUS ✅ (The Centralized Enterprise Solution):
══════════════════════════════════════════════════════════════════════════

                    ALL devices ask ONE central RADIUS Server!
                    
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ VPN Server 1 │  │ VPN Server 2 │  │ Wi-Fi AP #1  │  │ Wi-Fi AP #2  │
  │              │  │              │  │              │  │              │
  │ No local     │  │ No local     │  │ No local     │  │ No local     │
  │ user database│  │ user database│  │ user database│  │ user database│
  │              │  │              │  │              │  │              │
  │ "Ask RADIUS!"│  │ "Ask RADIUS!"│  │ "Ask RADIUS!"│  │ "Ask RADIUS!"│
  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
         │                 │                 │                 │
         └────────────┬────┴─────────┬───────┘                 │
                      │              │                         │
                      ▼              ▼                         ▼
              ┌──────────────────────────────────────────────────┐
              │  🔐 RADIUS SERVER (NPS)                          │
              │  Central Security Brain                          │
              │                                                  │
              │  Checks Active Directory (e6.local):             │
              │  ┌───────────────────────────────┐               │
              │  │ ✅ s.pengseang ──► ALLOWED     │               │
              │  │ ✅ s.pengsorng ──► ALLOWED     │               │
              │  │ ❌ alice       ──► DISABLED!   │               │
              │  │ ✅ john        ──► ALLOWED     │               │
              │  └───────────────────────────────┘               │
              └──────────────────────────────────────────────────┘
              
  ✅ Employee "alice" is FIRED today!
  IT Admin simply:
   1. Opens Active Directory (dsa.msc) ──► Disables alice's account
   2. DONE! alice is INSTANTLY blocked from ALL VPN servers,
      ALL Wi-Fi access points, ALL network switches, EVERYTHING!
      
  ✅ ONE place to manage ALL users!
  ✅ ONE place to audit ALL connections!
  ✅ ONE password change applies EVERYWHERE!
```

---

## 7. How Each One Works Internally (Deep Technical Breakdown)

### 🛡️ How VPN Server (RRAS) Works Step-by-Step:

```
  INTERNAL VPN SERVER ENGINE BREAKDOWN
  
  Step 1: LISTENING
  ════════════════
  The RRAS service (svchost.exe / rasman.dll) opens these listening ports:
  • TCP 1723  ──► PPTP Tunnel Listener
  • TCP 443   ──► SSTP Tunnel Listener (SSL/TLS)
  • UDP 500   ──► IKEv2 / L2TP Key Exchange
  • UDP 4500  ──► IKEv2 / L2TP NAT Traversal
  • UDP 1701  ──► L2TP Data Channel
  
  Step 2: CLIENT CONNECTS
  ═══════════════════════
  Remote employee (s.pengseang) opens Windows VPN client and clicks "Connect".
  The client establishes a TCP/UDP connection to the server on Port 443 (SSTP) 
  or Port 1723 (PPTP).
  
  Step 3: SSL/TLS HANDSHAKE (Encryption Negotiation)
  ══════════════════════════════════════════════════
  Client and Server perform a cryptographic handshake:
  • Exchange encryption algorithms (AES-128 / AES-256)
  • Exchange session keys using Diffie-Hellman or RSA
  • Result: A shared symmetric encryption key that ONLY they know!
  • From this point forward, EVERY byte traveling in BOTH directions
    is encrypted with AES-256. Even the ISP cannot read it!
  
  Step 4: AUTHENTICATION (Username / Password Verification)
  ═══════════════════════════════════════════════════════════
  Inside the encrypted tunnel, the client sends:
  • Username: E6\s.pengseang
  • Password: abc@123 (encrypted with MS-CHAPv2 challenge-response)
  
  The VPN server forwards this to the RADIUS Server (NPS) via UDP Port 1812.
  (See RADIUS section below for details)
  
  Step 5: IP ADDRESS ASSIGNMENT
  ════════════════════════════
  After RADIUS approves the user, the VPN server assigns a virtual IP:
  • From the Static Address Pool: 192.168.1.220 – 192.168.1.240
  • Client receives: 192.168.1.221
  • This IP is a REAL internal LAN IP! The client is now on the LAN!
  
  Step 6: ROUTING & DATA FORWARDING
  ═════════════════════════════════
  The VPN server creates a virtual network interface (PPP adapter) and
  routes all traffic between the client's virtual IP and the LAN:
  
  Client (192.168.1.221) ──► VPN Tunnel ──► Server (192.168.1.10) ──► LAN
  
  The client can now access:
  • File Shares:  \\192.168.1.10\software
  • Databases:    192.168.1.10:1521 (Oracle) / :5432 (PostgreSQL)
  • Web Server:   http://portfolio.e6.local
  • RDP:          mstsc → 192.168.1.10:3389
```

---

### 🔐 How RADIUS Server (NPS) Works Step-by-Step:

```
  INTERNAL RADIUS / NPS ENGINE BREAKDOWN
  
  Step 1: LISTENING
  ════════════════
  The NPS service (ias.exe / iassrv.dll) listens on:
  • UDP Port 1812  ──► RADIUS Authentication Requests
  • UDP Port 1813  ──► RADIUS Accounting Logs
  
  Step 2: RECEIVES RADIUS ACCESS-REQUEST FROM VPN SERVER
  ═════════════════════════════════════════════════════
  The VPN Server (RRAS) sends a RADIUS packet (Access-Request) containing:
  ┌─────────────────────────────────────────────────────────┐
  │ RADIUS Access-Request Packet (UDP Port 1812)            │
  │                                                         │
  │ • Code:           1 (Access-Request)                    │
  │ • User-Name:      E6\s.pengseang                        │
  │ • User-Password:  <MS-CHAPv2 encrypted hash>            │
  │ • NAS-IP-Address: 192.168.1.10 (VPN Server IP)          │
  │ • NAS-Port-Type:  Virtual (VPN Connection)               │
  │ • Shared-Secret:  <Pre-configured between RRAS and NPS> │
  └─────────────────────────────────────────────────────────┘
  
  Step 3: SHARED SECRET VALIDATION
  ════════════════════════════════
  NPS first validates the RADIUS shared secret:
  • The VPN Server and NPS Server share a preconfigured password
    (called the "shared secret") that proves the VPN server is
    legitimate and not a rogue device!
  • If the shared secret does not match ──► Packet is SILENTLY DROPPED!
  
  Step 4: ACTIVE DIRECTORY PASSWORD VERIFICATION
  ══════════════════════════════════════════════
  NPS contacts Active Directory (via LDAP / Kerberos):
  • Looks up user: s.pengseang in domain e6.local
  • Verifies: Is the account active? (Account active: Yes)
  • Verifies: Has the account expired? (Account expires: Never)
  • Verifies: Is the password correct? (MS-CHAPv2 challenge-response)
  • Verifies: Is the account locked out? (Lockout threshold check)
  
  Step 5: NETWORK POLICY EVALUATION
  ═════════════════════════════════
  NPS evaluates its ordered list of Network Policies:
  ┌─────────────────────────────────────────────────────────┐
  │ Policy: "Allow_VPN_Access"                              │
  │                                                         │
  │ Conditions:                                             │
  │   ✅ User is member of "Domain Users" group? ──► YES!   │
  │   ✅ Connection type is "VPN"?               ──► YES!   │
  │   ✅ Time is within allowed hours?           ──► YES!   │
  │                                                         │
  │ Result: ALL CONDITIONS MET ──► ACCESS GRANTED!          │
  └─────────────────────────────────────────────────────────┘
  
  Step 6: SENDS RADIUS ACCESS-ACCEPT BACK TO VPN SERVER
  ═══════════════════════════════════════════════════════
  NPS sends a RADIUS packet (Access-Accept) back to RRAS:
  ┌─────────────────────────────────────────────────────────┐
  │ RADIUS Access-Accept Packet (UDP Port 1812)             │
  │                                                         │
  │ • Code:                2 (Access-Accept)                │
  │ • Framed-IP-Address:   192.168.1.221 (Assigned IP)      │
  │ • Session-Timeout:     28800 (8 hours max session)      │
  │ • MS-MPPE-Send-Key:    <Encryption key for tunnel>      │
  └─────────────────────────────────────────────────────────┘
  
  Step 7: ACCOUNTING LOG ENTRY
  ═══════════════════════════
  NPS writes an accounting log (UDP Port 1813):
  ┌─────────────────────────────────────────────────────────┐
  │ RADIUS Accounting Record                                │
  │                                                         │
  │ • Timestamp:      2026-08-26 18:30:00                   │
  │ • User:           E6\s.pengseang                        │
  │ • Event:          Accounting-Start (Session began)      │
  │ • Assigned IP:    192.168.1.221                         │
  │ • NAS-IP:         192.168.1.10 (VPN Server)             │
  │ • Auth-Type:      MS-CHAPv2                             │
  └─────────────────────────────────────────────────────────┘
```

---

## 8. How VPN and RADIUS Work Together (Combined Flow)

Here is the **complete end-to-end flow** when user `s.pengseang` connects from home:

```
  COMPLETE VPN + RADIUS CONNECTION TIMELINE
  ══════════════════════════════════════════
  
  TIME         EVENT
  ─────        ─────────────────────────────────────────────────────
  18:30:00     👤 s.pengseang opens Windows VPN client on pro-win-client
               Clicks "Connect" to 192.168.1.10
               
  18:30:01     🔐 SSL/TLS Handshake begins (SSTP on TCP 443)
               Client and Server negotiate AES-256 encryption
               
  18:30:02     🔑 Encrypted tunnel established!
               Client sends credentials inside tunnel:
               Username: E6\s.pengseang
               Password: abc@123 (MS-CHAPv2 encrypted)
               
  18:30:02     🛡️ VPN Server (RRAS) receives credentials
               RRAS does NOT validate the password itself!
               RRAS creates RADIUS Access-Request packet
               RRAS sends packet to NPS via UDP Port 1812
               
  18:30:03     🔐 RADIUS Server (NPS) receives Access-Request
               NPS validates the shared secret (legitimate VPN server?)
               NPS contacts Active Directory (e6.local)
               NPS verifies: s.pengseang exists? ──► YES ✅
               NPS verifies: Account active? ──► YES ✅
               NPS verifies: Password correct? ──► YES ✅
               NPS checks Network Policy "Allow_VPN_Access":
                 - Member of Domain Users? ──► YES ✅
                 - Connection type = VPN? ──► YES ✅
               NPS Decision: ACCESS GRANTED!
               
  18:30:03     🔐 NPS sends RADIUS Access-Accept back to RRAS
               Includes assigned IP: 192.168.1.221
               
  18:30:04     🛡️ VPN Server (RRAS) receives Access-Accept
               RRAS assigns virtual IP 192.168.1.221 to client
               RRAS creates PPP virtual network adapter
               RRAS establishes routing between client and LAN
               
  18:30:04     🟢 VPN CONNECTION ESTABLISHED!
               Client now has IP: 192.168.1.221
               Client can access entire 192.168.1.0/24 network!
               
  18:30:05     📊 NPS writes Accounting-Start log entry
               "s.pengseang connected at 18:30:04 from IP 103.45.67.89"
               
  ─── s.pengseang works for 4 hours: accessing files, databases, RDP ───
               
  22:30:00     👤 s.pengseang clicks "Disconnect" on VPN client
               
  22:30:01     🛡️ RRAS terminates the tunnel
               Releases IP 192.168.1.221 back to the pool
               
  22:30:01     📊 NPS writes Accounting-Stop log entry:
               "s.pengseang disconnected at 22:30:01"
               "Duration: 4 hours 0 minutes"
               "Bytes In: 245 MB | Bytes Out: 52 MB"
```

---

## 9. Full Abbreviation & Terminology Glossary

| Abbreviation | Full Name | What It Is |
|:---|:---|:---|
| **VPN** | Virtual Private Network | Encrypted tunnel over the public Internet to access a private network. |
| **RRAS** | Routing and Remote Access Service | Windows Server component that implements VPN server and IP routing. |
| **RADIUS** | Remote Authentication Dial-In User Service | Industry-standard protocol (RFC 2865) for centralized network authentication. |
| **NPS** | Network Policy Server | Microsoft's implementation of RADIUS built into Windows Server. |
| **AAA** | Authentication, Authorization, Accounting | The 3 security pillars of centralized network access control. |
| **SSTP** | Secure Socket Tunneling Protocol | VPN protocol using SSL/TLS on TCP Port 443 (Microsoft proprietary). |
| **PPTP** | Point-to-Point Tunneling Protocol | Legacy VPN protocol on TCP Port 1723 (fast but less secure). |
| **L2TP** | Layer 2 Tunneling Protocol | VPN protocol combined with IPsec for strong encryption. |
| **IKEv2** | Internet Key Exchange version 2 | Modern VPN protocol supporting fast reconnection on network changes. |
| **IPsec** | Internet Protocol Security | Suite of cryptographic protocols for encrypting IP-level traffic. |
| **MS-CHAPv2** | Microsoft Challenge Handshake Authentication Protocol v2 | Password verification protocol that never sends the actual password; uses challenge-response hashing. |
| **GRE** | Generic Routing Encapsulation | Protocol 47; used by PPTP to encapsulate tunneled data packets. |
| **NAS** | Network Access Server | The device (VPN server / Wi-Fi AP) that forwards RADIUS requests. |
| **PAC** | Privilege Attribute Certificate | Kerberos ticket data containing user SIDs and group memberships. |
| **PSK** | Pre-Shared Key | A shared secret password used by L2TP/IPsec for mutual authentication. |
| **802.1X** | IEEE 802.1X Port-Based Network Access Control | Standard for authenticating wired/wireless devices via RADIUS. |
| **RFC 2865** | RADIUS Protocol Specification | The original IETF standard defining the RADIUS protocol. |
| **RFC 2866** | RADIUS Accounting Specification | The IETF standard defining RADIUS accounting logging. |
