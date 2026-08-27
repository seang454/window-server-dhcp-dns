# Step 7: Mail Server (hMailServer / SMTP, POP3, IMAP) — Complete Hands-On Lab Setup Guide

**Windows Server 2022 on VMware Workstation**  
**Domain:** `e6.local`  
**Server:** `WIN-J17IMHCEMA9` (`pro-win-server` at `192.168.1.10`)  
**Client:** `CLIENT` (`pro-win-client` at `192.168.1.100`)  
**Mail Hostname:** `mail.e6.local`  
**Email Domain:** `@e6.local`

---

## 📖 Table of Contents

1. [Lab Topology & Architecture Overview](#1-lab-topology--architecture-overview)
2. [Phase 1: Configure DNS Infrastructure for Mail (A, MX, PTR Records)](#phase-1-configure-dns-infrastructure-for-mail-a-mx-ptr-records)
3. [Phase 2: Install hMailServer on the Server](#phase-2-install-hmailserver-on-the-server)
4. [Phase 3: Configure Domain & Mailboxes in hMailServer](#phase-3-configure-domain--mailboxes-in-hmailserver)
5. [Phase 4: Configure Windows Defender Firewall for Mail Ports](#phase-4-configure-windows-defender-firewall-for-mail-ports)
6. [Phase 5: Client Setup on `pro-win-client` (Thunderbird / Windows Mail)](#phase-5-client-setup-on-pro-win-client-thunderbird--windows-mail)
7. [Phase 6: Live Verification & Testing (The Lab Exam Checklist)](#phase-6-live-verification--testing-the-lab-exam-checklist)
8. [Phase 7: Advanced Command-Line Test (Raw SMTP via Telnet)](#phase-7-advanced-command-line-test-raw-smtp-via-telnet)
9. [Phase 8: Troubleshooting Common Mail Server Errors](#phase-8-troubleshooting-common-mail-server-errors)

---

## 1. Lab Topology & Architecture Overview

```text
  ========================================================================================
                          ENTERPRISE MAIL SYSTEM ARCHITECTURE
  ========================================================================================

  💻 pro-win-client (192.168.1.100)                  🖥️ pro-win-server (192.168.1.10)
  ┌───────────────────────────────┐                  ┌──────────────────────────────────┐
  │ MUA: Mozilla Thunderbird      │                  │ hMailServer Windows Service      │
  │ Account: s.pengseang@e6.local │                  │ ├── SMTP Server (Port 25, 587)   │
  └───────────────┬───────────────┘                  │ ├── IMAP Server (Port 143, 993)  │
                  │                                  │ ├── POP3 Server (Port 110, 995)  │
                  │ 1. Sends email (SMTP:25)         │ └── Storage: C:\Mail\e6.local\   │
                  ├─────────────────────────────────►│                                  │
                  │                                  │ 2. Stores message in mailbox     │
                  │ 3. Syncs Inbox (IMAP:143)        │    administrator@e6.local        │
                  │◄─────────────────────────────────┤                                  │
                  │                                  └─────────────────┬────────────────┘
                  │                                                    │
  💻 Admin Workstation                                                 │
  ┌───────────────────────────────┐                                    │
  │ Account:                      │◄───────────────────────────────────┘
  │ administrator@e6.local        │  4. Admin reads email instantly!
  └───────────────────────────────┘

  🌐 DNS Records (in e6.local zone on 192.168.1.10):
  • A Record:   mail.e6.local ──► 192.168.1.10
  • MX Record:  e6.local      ──► Priority 10 ──► mail.e6.local
  • PTR Record: 192.168.1.10  ──► mail.e6.local
  ========================================================================================
```

---

## Phase 1: Configure Complete DNS Infrastructure for Mail (A, MX, PTR, SPF, DMARC, DKIM)

Before installing any mail software, **all 6 DNS records must be created** so servers know where to route emails, how to verify sender identity, and how to block spoofing.

---

### 1.1 Create the Host A Record (`mail.e6.local`)
Resolves the mail hostname into the server's physical IP address:

1. Press **`Win + R`** ──► type:
   ```cmd
   dnsmgmt.msc
   ```
2. Press **Enter** to open **DNS Manager**.
3. Expand: `WIN-J17IMHCEMA9` ──► **Forward Lookup Zones** ──► click **`e6.local`**.
4. Right-click empty white space ──► select **New Host (A or AAAA)...**:
   * **Name:** `mail`
   * **FQDN:** Automatically becomes `mail.e6.local`
   * **IP address:** `192.168.1.10`
   * Check: ✅ **Create associated pointer (PTR) record**
5. Click **Add Host** ──► click **OK**!

---

### 1.2 Create the MX (Mail Exchanger) Record
Tells the world where to deliver incoming emails for `@e6.local`:

1. In the same `e6.local` zone, right-click empty white space.
2. Select **Mail Exchanger (MX)...**:
   * **Host or child domain:** Leave **BLANK** *(means the entire `@e6.local` domain)*.
   * **Fully qualified domain name (FQDN) of mail server:**  
     Type: 👉 **`mail.e6.local.`** *(or click Browse and select your `mail` A record)*.
   * **Mail server priority:** `10`
3. Click **OK**!

---

### 1.3 Verify & Create the Reverse PTR Record (rDNS / FCrDNS)
Proves the IP `192.168.1.10` authentically belongs to `mail.e6.local`:

1. In DNS Manager, expand **Reverse Lookup Zones**.
2. Click on: **`1.168.192.in-addr.arpa`** *(or your reverse zone)*.
3. Look for IP **`192.168.1.10`**:
   * If already present, ensure it points to: **`mail.e6.local.`**
   * If missing: Right-click empty space ──► **New Pointer (PTR)...**:
     * **Host IP Number:** `10`
     * **Host name:** `mail.e6.local.`
     * Click **OK**!

---

### 1.4 Create the SPF (Sender Policy Framework) Record
Whitelists your server IP so impostors cannot send fake emails claiming to be from `@e6.local`:

1. In **Forward Lookup Zones** ──► click **`e6.local`**.
2. Right-click empty white space ──► select **Other New Records...**.
3. Select **Text (TXT)** in the list ──► click **Create Record...**:
   * **Record name:** Leave **BLANK** *(applies to `@e6.local` root)*.
   * **Text:**
     ```text
     v=spf1 mx ip4:192.168.1.10 -all
     ```
4. Click **OK** ──► click **Done**!

---

### 1.5 Create the DMARC Policy Record
Enforces policy and requests daily delivery and spoofing reports:

1. In the `e6.local` zone, right-click empty space ──► select **Other New Records...**.
2. Select **Text (TXT)** ──► click **Create Record...**:
   * **Record name:** `_dmarc`
   * **FQDN:** Automatically becomes `_dmarc.e6.local`
   * **Text:**
     ```text
     v=DMARC1; p=none; rua=mailto:administrator@e6.local; pct=100
     ```
   *(Note: `p=none` is testing/monitoring mode. For production strict blocking, use `p=reject`)*.
3. Click **OK** ──► click **Done**!

---

### 1.6 Create the DKIM (DomainKeys Identified Mail) Record
Publishes the public cryptographic key so recipients can verify digital signatures:

*(Note: The exact RSA public key string is generated in Phase 3 inside hMailServer. Once generated, add it here)*:

1. In the `e6.local` zone, right-click empty space ──► select **Other New Records...**.
2. Select **Text (TXT)** ──► click **Create Record...**:
   * **Record name:** `s1._domainkey`
   * **FQDN:** Automatically becomes `s1._domainkey.e6.local`
   * **Text:**
     ```text
     v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
     ```
3. Click **OK** ──► click **Done**!

---

### ⚡ Fast Track: Automated 1-Click PowerShell DNS Setup
Instead of clicking through the GUI, you can create all DNS mail records in **2 seconds** by running this script in PowerShell as Administrator on **`pro-win-server`**:

```powershell
# 1. Create Host A Record:
Add-DnsServerResourceRecordA -ZoneName "e6.local" -Name "mail" -IPv4Address 192.168.1.10 -CreatePtr -ErrorAction SilentlyContinue

# 2. Create MX Record (Priority 10):
Add-DnsServerResourceRecordMX -ZoneName "e6.local" -Name "@" -MailExchange "mail.e6.local" -Preference 10 -ErrorAction SilentlyContinue

# 3. Create SPF TXT Record:
Add-DnsServerResourceRecord -ZoneName "e6.local" -Txt -Name "@" -DescriptiveText "v=spf1 mx ip4:192.168.1.10 -all" -ErrorAction SilentlyContinue

# 4. Create DMARC TXT Record:
Add-DnsServerResourceRecord -ZoneName "e6.local" -Txt -Name "_dmarc" -DescriptiveText "v=DMARC1; p=none; rua=mailto:administrator@e6.local; pct=100" -ErrorAction SilentlyContinue

# 5. Flush and verify:
Clear-DnsClientCache
Resolve-DnsName e6.local -Type MX
Resolve-DnsName e6.local -Type TXT
Resolve-DnsName _dmarc.e6.local -Type TXT
```

---

### 1.7 Verify Complete DNS Setup in PowerShell:
Run these verification commands to ensure every single record resolves:

```powershell
# Verify A:
Resolve-DnsName mail.e6.local | Format-Table Name, Type, IPAddress

# Verify MX:
Resolve-DnsName e6.local -Type MX | Format-Table Name, Type, Preference, NameExchange

# Verify SPF:
Resolve-DnsName e6.local -Type TXT | Select-Object -ExpandProperty Strings

# Verify DMARC:
Resolve-DnsName _dmarc.e6.local -Type TXT | Select-Object -ExpandProperty Strings
```

🟢 **Expected Output:** All 4 records return successfully with exact parameters!

---

## Phase 2: Install hMailServer on the Server

**hMailServer** is the premier free, open-source email server for Windows Server, supporting SMTP, POP3, and IMAP.

### 2.1 Download hMailServer:
On **`pro-win-server`**, open PowerShell as Administrator and run:

```powershell
# Download hMailServer into C:\software:
Invoke-WebRequest -Uri "https://www.hmailserver.com/download/file/576" -OutFile "C:\software\hMailServer_Setup.exe" -UserAgent "Mozilla/5.0"
```
*(Or download directly from [hmailserver.com](https://www.hmailserver.com/download) on your laptop browser and place in `C:\software`)*.

---

### 2.2 Run the Installer:
1. Double-click **`C:\software\hMailServer_Setup.exe`**.
2. Click **Next** ──► Accept Agreement ──► **Next**.
3. Destination: `C:\Program Files (x86)\hMailServer` ──► Click **Next**.
4. **Select Components:**
   * ✅ **Server**
   * ✅ **Administrative tools**
   * Click **Next**.
5. **Select Database Type:**
   * Select: 🔘 **`Use built-in database engine (Microsoft SQL Server Compact / SQLite)`**  
     *(Fastest, easiest, zero external database setup needed!)*
   * Click **Next**.
6. **Set Master Administrator Password:**
   * Enter a secure password for the hMailServer Admin console:  
     👉 **`abc@123`**
   * Confirm: **`abc@123`**
   * Click **Next** ──► Click **Install**!
7. Check: ✅ **Run hMailServer Administrator** ──► click **Finish**!

---

## Phase 3: Configure Domain & Mailboxes in hMailServer

### 3.1 Connect to Administrator Console:
1. When the login box appears, select **`localhost`** ──► click **Connect**.
2. Type password: **`abc@123`** ──► click **OK**.

---

### 3.2 Add Your Email Domain (`e6.local`):
1. In the left tree, click on **`Domains`**.
2. Click the **`Add...`** button on the right:
   * **Domain:** `e6.local`
   * **Status:** ✅ **Enabled**
3. Click **Save** at the bottom right!

---

### 3.3 Create the 2 Mailbox Accounts:
Under your new domain `e6.local`:
1. Expand **`Domains`** ──► expand **`e6.local`** ──► click on **`Accounts`**.

#### 👤 Account 1: `administrator@e6.local`
2. Click **`Add...`**:
   * **Address:** `administrator`
   * **Password:** `abc@123`
   * **Maximum size (MB):** `1000`
   * **Status:** ✅ **Enabled**
   * Click **Save**!

#### 👤 Account 2: `s.pengseang@e6.local`
3. Click **`Add...`**:
   * **Address:** `s.pengseang`
   * **Password:** `abc@123`
   * **Maximum size (MB):** `1000`
   * **Status:** ✅ **Enabled**
   * Click **Save**!

---

### 3.4 Configure Anti-Relay & Authentication Rules:
In the left tree:
1. Click **`Settings`** ──► **`Advanced`** ──► **`IP Ranges`**.
2. Click on **`My computer`** (`127.0.0.1`):
   * Ensure **Allow connections** (SMTP, POP3, IMAP) are all checked.
3. Click on **`Internet`** (`0.0.0.0 - 255.255.255.255`):
   * Under **Require SMTP authentication**:
     * Check: ✅ **Local to external email addresses**
     * Check: ✅ **External to external email addresses**  
     *(⚠️ This prevents your server from becoming an "Open Relay" spam bot!)*
4. Click **Save**!

---

## Phase 4: Configure Windows Defender Firewall for Mail Ports

We must allow client computers to communicate over SMTP, POP3, and IMAP.

Run this single command block in PowerShell as Administrator on **`pro-win-server`**:

```powershell
# Open SMTP (25, 587):
New-NetFirewallRule -DisplayName "Mail Server - SMTP (25, 587)" -Direction Inbound -Protocol TCP -LocalPort 25, 587 -Action Allow

# Open IMAP (143, 993):
New-NetFirewallRule -DisplayName "Mail Server - IMAP (143, 993)" -Direction Inbound -Protocol TCP -LocalPort 143, 993 -Action Allow

# Open POP3 (110, 995):
New-NetFirewallRule -DisplayName "Mail Server - POP3 (110, 995)" -Direction Inbound -Protocol TCP -LocalPort 110, 995 -Action Allow
```

🟢 **Result:** All 6 email ports are now open and ready!

---

## Phase 5: Client Setup on `pro-win-client` (Thunderbird / Windows Mail)

Now switch to your client machine: **`pro-win-client` (`192.168.1.100`)**.

You can use **Mozilla Thunderbird**, **Microsoft Outlook**, or **Windows Mail**.

### 5.1 Using Mozilla Thunderbird (Recommended & Free):
1. Open **Thunderbird** on `pro-win-client`.
2. Go to: **Account Settings ──► Add Mail Account**:
   * **Your full name:** `Pengseang Sim`
   * **Email address:** `s.pengseang@e6.local`
   * **Password:** `abc@123`
   * Check: ✅ **Remember password**
3. Click **Configure manually...**:

| Setting | Incoming Server (Receiving) | Outgoing Server (Sending) |
|:---|:---|:---|
| **Protocol** | **IMAP** | **SMTP** |
| **Server Hostname** | `mail.e6.local` *(or `192.168.1.10`)* | `mail.e6.local` *(or `192.168.1.10`)* |
| **Port** | `143` | `25` *(or `587`)* |
| **Connection Security** | `None` *(or STARTTLS)* | `None` *(or STARTTLS)* |
| **Authentication** | `Normal password` | `Normal password` |
| **Username** | `s.pengseang@e6.local` | `s.pengseang@e6.local` |

4. Click **Re-test** ──► Click **Done**!
5. When prompted with a security warning (for plain text internal lab), check:  
   ✅ **I understand the risks** ──► Click **Confirm**!

---

## Phase 6: Live Verification & Testing (The Lab Exam Checklist)

Execute these **3 live verification tests** to prove your Mail Server works 100%:

### 🧪 Test 1: Send Internal Email
1. In Thunderbird on `pro-win-client`, click **`Write`** (New Message):
   * **To:** `administrator@e6.local`
   * **Subject:** `Test from Student Client VM`
   * **Body:** `Hello Administrator, our Windows Server Mail Server is officially working!`
2. Click **`Send`**!
3. 🟢 **Status:** The message sends without errors and lands in your "Sent" folder!

---

### 🧪 Test 2: Verify Delivery on the Server Console
On **`pro-win-server`**:
1. Open **hMailServer Administrator**.
2. Click on **`Status`** in the left menu.
3. Click the **`Server`** tab:
   * Look at: **Delivered messages** (Counter increments by `+1`!).
4. Click on **`Logging`**:
   * You will see the live SMTP handshake timestamped with:  
     `SENT: 250 2.0.0 OK: queued as ...`

---

### 🧪 Test 3: Admin Replies to Student
1. Add the `administrator@e6.local` account to Thunderbird or open webmail.
2. Open the email sent from `s.pengseang@e6.local`.
3. Click **`Reply`**:
   * **Body:** `Message received loud and clear! Great job setting up Step 7!`
4. Click **`Send`**!
5. Switch back to `s.pengseang` inbox ──► click **Get Messages**:
   * 📬 **The reply email arrives instantly in the inbox!**

---

## Phase 7: Advanced Command-Line Test (Raw SMTP via Telnet)

In networking exams, professors often ask students to send an email using pure **Telnet** without using any email app:

1. Open **Command Prompt** on `pro-win-client` and run:
   ```cmd
   telnet mail.e6.local 25
   ```
2. Type these exact commands line-by-line:
   ```text
   HELO client.e6.local
   MAIL FROM: <s.pengseang@e6.local>
   RCPT TO: <administrator@e6.local>
   DATA
   Subject: Raw Telnet Test Email

   This email was dispatched via raw command line SMTP!
   .
   QUIT
   ```
3. 🟢 **Result:** The server replies `250 OK: queued` and the message appears in the administrator's inbox!

---

## Phase 8: Troubleshooting Common Mail Server Errors

| Error Code / Symptom | Root Cause | Exact Solution |
|:---|:---|:---|
| **"Could not connect to server / Connection refused on port 25"** | Windows Firewall is blocking Port 25, or hMailServer service is stopped. | Run `Get-Service hMailServer` on server. Ensure firewall rule `Mail Server - SMTP` is enabled. |
| **"550 A password is required to send to external addresses"** | Client tried sending an email without SMTP Authentication enabled. | In Thunderbird Outgoing Server (SMTP) settings, ensure Authentication is set to **Normal Password**. |
| **"550 Relay Access Denied"** | The mail server rejected the recipient because it is not configured for `@e6.local`. | Check hMailServer Administrator ──► Domains ──► verify `e6.local` exists and is Enabled. |
| **"Server name could not be resolved"** | DNS MX or A record missing on Domain Controller. | Run `Resolve-DnsName mail.e6.local` and ensure it points to `192.168.1.10`. |

---

## 📊 Summary of Master Server Roles Completed

| # | Server Role | Status | Documentation File |
|:---:|:---|:---:|:---|
| 1 | **DHCP & DNS Core Network** | ✅ Complete | [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md) |
| 2 | **File Server & FTP Storage** | ✅ Complete | [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md) |
| 3 | **Web Server (IIS + Next.js + PM2)** | ✅ Complete | [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md) |
| 4 | **Database Server (Oracle 19c & PostgreSQL)** | ✅ Complete | [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md) |
| 5 | **Terminal Server (Remote Desktop Services - RDS)** | ✅ Complete | [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md) |
| 6 | **VPN Server (RRAS) & RADIUS Server (NPS)** | ✅ Complete | [`Step6_VPN_and_RADIUS_Server_Setup.md`](Step6_VPN_and_RADIUS_Server_Setup.md) |
| 7 | **Mail Server (SMTP, POP3, IMAP)** | 🚀 Ready to Execute | [`Step7_Mail_Server_Setup.md`](Step7_Mail_Server_Setup.md) |
| 8 | **Backup Server (Windows Server Backup - wbadmin)** | ⏳ Next | Step 8 |
| 9 | **Load Balancing & Failover Cluster** | ⏳ Next | Step 9 & 10 |
