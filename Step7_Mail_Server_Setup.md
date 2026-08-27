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

## Phase 1: Configure Prerequisite DNS Infrastructure (A, MX, PTR, SPF, DMARC)

Before installing any mail software, **these 5 foundational DNS records must be created** so servers know where to route emails, how to verify sender identity, and how to block spoofing. *(Note: DKIM cryptographic keys will be generated inside hMailServer in Phase 3 and published to DNS then!)*

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

> [!CAUTION]
> **🛑 CRITICAL DNS PITFALL: The Trailing Root Dot (`.`) & The Double Domain Bug**  
> In DNS architecture (RFC 1034), if you type `mail.e6.local` without a trailing dot `.`, Windows DNS assumes it is a **relative name** and appends the zone name again, creating:  
> ❌ **`mail.e6.local.e6.local.`** *(Broken! Incoming mail will bounce!)*  
> Always either:
> 1. Type the trailing dot explicitly: **`mail.e6.local.`**
> 2. **OR** click the **`Browse...`** button and select the `mail` host. Windows will automatically insert the dot!

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

> [!NOTE]
> **💡 Why is the Record Name `_dmarc` and the Text formatted like this?**
> * **Why `_dmarc`?** Receiving servers (Gmail, Microsoft) are programmed by RFC 7489 to automatically query `_dmarc.<domain>`. The underscore `_` is used because DNS standards forbid underscores in normal computer names, ensuring this security record never collides with a real server name!
> * **`v=DMARC1`**: Mandatory version identifier.
> * **`p=none`**: Monitoring mode (allows emails through without blocking, but logs failures). In production, set to `p=reject` to completely destroy fake emails!
> * **`rua=mailto:...`**: Destination address where worldwide servers automatically email daily XML audit reports.
> * **`pct=100`**: Applies the rule to 100% of emails.

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

### 2.1 Prerequisite: Enable .NET Framework 3.5 (`Net-Framework-Core`) ⚠️
The hMailServer Administrator tool relies on the legacy .NET 2.0/3.5 runtime. If this is not installed, the setup wizard will attempt to download `dotnetfx.exe` from an obsolete 2008 Microsoft link that returns **404 Not Found**!

Run this command in PowerShell as Administrator on **`pro-win-server`** before installing:

```powershell
Install-WindowsFeature Net-Framework-Core
```
*(Windows enables the built-in .NET 3.5 feature in ~30 seconds, completely bypassing the 404 error!)*

---

### 2.2 Download hMailServer Installer:
1. On `pro-win-server` or your host laptop browser, visit:  
   👉 **[https://www.hmailserver.com/download](https://www.hmailserver.com/download)**
2. Under **Latest version**, click:  
   👉 **`Download hMailServer 5.6.8 - Build 2574`**
3. Save the installer to: **`C:\software\hMailServer-5.6.8-B2574.exe`**

---

### 2.3 Run the Installer:
1. Double-click **`C:\software\hMailServer-5.6.8-B2574.exe`**.
2. Click **Next** ──► Choose **"I accept the agreement"** ──► Click **Next**.
3. Destination: `C:\Program Files (x86)\hMailServer` ──► Click **Next**.
4. **Select Components:** Make sure both are checked:
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
When the connection dialog appears:
1. Optional: Check the box: ✅ **Automatically connect on start-up**
2. Click on **`localhost`** ──► click the **`Connect`** button at the bottom!
3. When prompted for password:
   * Type: 👉 **`abc@123`**
   * Click **OK**!

---

### 3.2 Add Your Email Domain (`e6.local`):
Once the main hMailServer Administrator window opens:
1. In the left tree menu, click on **`Domains`**.
2. On the right side, click the **`Add...`** button:
   * **Domain:** `e6.local`
   * **Status:** Ensure it is checked: ✅ **Enabled**
3. Click the **`Save`** button at the bottom right!

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

### 3.4 (Optional): Create a Distribution List (Group Email Address):
If you want 1 email address (e.g. `team@e6.local`) to deliver to multiple users at once:
1. Under `e6.local`, click **`Distribution lists`** ──► click **`Add...`**:
   * **Address:** `team`
   * **Mode:** Select `Public` (anyone can email) or `Members` (only members can email)
   * Check: ✅ **Enabled** ──► click **Save**!
2. Click the **`Members`** tab ──► click **`Add...`**:
   * Add: `administrator@e6.local`
   * Add: `s.pengseang@e6.local`
3. Click **Save**! Now emails sent to `team@e6.local` reach both users!

---

### 3.5 The 6 Console Folders Explained (Quick Reference):
* **`Accounts`**: Real human mailboxes (stores messages on disk, has password, quota).
* **`Aliases`**: Forwarding nicknames (`help@e6.local` forwards straight to a real mailbox).
* **`Distribution lists`**: Group mailing lists (1 email automatically broadcasts to 10+ members).
* **`Rules`**: Automated filters ("If Subject contains 'Spam' ──► Delete").
* **`Settings`**: Core engine controls (SMTP/IMAP/POP3 ports, Anti-Spam SPF, IP Ranges).
* **`Utilities`**: Administrative tools (Automated health diagnostics & full system backup).

---

### 3.6 Configure Anti-Relay & Authentication Rules:
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

### 3.7 (Advanced / Production Optional): DKIM Cryptographic Signing Setup

> [!IMPORTANT]
> **📌 WHEN DO YOU NEED TO SET THIS UP? (AND WHY IT IS SKIPPED FOR LOCAL NETWORKS)**
> * **The Short Answer:**  
>   👉 **LEAVE THIS UNCHECKED / SKIPPED!** You do **NOT** need DKIM to send, receive, or synchronize emails between your Windows 8 client VMs. Everything works 100% with standard Host A, MX, and PTR records!
>
> * **🧐 Why DKIM is NOT Needed on a Local Network:**
>   1. **Where Was DKIM Designed to Work?**  
>      DKIM was invented for the **wild, untrusted public Internet**, where an email passes through 5 to 10 unknown third-party routers and intermediate relay servers before reaching Google or Yahoo. It attaches a cryptographic signature so receiving servers can verify: *"Did a rogue intermediate router tamper with or modify this email in transit?"*
>   2. **How YOUR Local Network Works:**  
>      On your private network:
>      ```text
>      Client 1 (192.168.1.100) ──► LAN Switch ──► pro-win-server (192.168.1.10) ──► Client 2 (192.168.1.101)
>      ```
>      There are **NO outside servers, NO third-party relays, and NO untrusted intermediate hops**!  
>      When Client 1 connects to send mail, hMailServer already requires **Username + Password (SMTP Authentication)**. The server already knows with 100% certainty that the sender is legitimate.  
>      *(💡 Analogy: Adding DKIM on a local network is like putting an official royal wax seal on a handwritten note that you are handing directly to your roommate across the desk!)*
>
> * **When is DKIM ACTUALLY Required in the Real World?**  
>   👉 Only in **Public Internet Production** when your server sends outbound emails directly to external public providers like **Gmail**, **Microsoft 365**, or **Yahoo**. Modern public mail providers mandate DKIM signatures to prove that the email was not modified or spoofed in transit across the Internet.
>
> ---
>
> **📍 WHERE IS THIS CONFIGURED? (Saved for Future Production Reference):**
> * **In hMailServer:** Expand `Domains` ──► click `e6.local` ──► click the **`DKIM Signing`** tab.
> * **In DNS Manager (`dnsmgmt.msc`):** `Forward Lookup Zones` ──► `e6.local` ──► Text (TXT) record named **`s1._domainkey`**.
> * **The Private Key File:** Saved on server disk at `C:\Program Files (x86)\hMailServer\Data\dkim.private.key`.

#### 🛠️ How to Enable in Production (When Needed):
1. On a production machine with OpenSSL installed, generate the key pair:
   ```cmd
   openssl genrsa -out "C:\Program Files (x86)\hMailServer\Data\dkim.private.key" 2048
   openssl rsa -in "C:\Program Files (x86)\hMailServer\Data\dkim.private.key" -pubout -out "C:\Program Files (x86)\hMailServer\Data\dkim.public.key"
   ```
2. Copy the public key text and add a TXT record in DNS Manager:
   * **Name:** `s1._domainkey`
   * **Value:** `v=DKIM1; k=rsa; p=<PUBLIC_KEY_STRING>`
3. In hMailServer under `e6.local` ──► `DKIM Signing`:
   * **Selector:** `s1`
   * **Private key file:** `C:\Program Files (x86)\hMailServer\Data\dkim.private.key`
   * Check: ✅ **Enabled** ──► click **Save**!

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

> [!NOTE]
> **⚠️ Windows 8 / 8.1 Client Compatibility (Thunderbird 115 ESR):**  
> Modern Thunderbird versions require Windows 10 or newer. The **official final version that supports Windows 8 and 8.1** is **Thunderbird 115.15.0 ESR**!  
> * **Direct Download Link:**  
>   [https://archive.mozilla.org/pub/thunderbird/releases/115.15.0esr/win32/en-US/Thunderbird%20Setup%20115.15.0esr.exe](https://archive.mozilla.org/pub/thunderbird/releases/115.15.0esr/win32/en-US/Thunderbird%20Setup%20115.15.0esr.exe)

1. Run the **Thunderbird 115 ESR** installer on `pro-win-client`.
2. Open Thunderbird, go to: **Account Settings ──► Add Mail Account**:
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

## Phase 8: Troubleshooting Common Mail Server Errors (Lab Tested Solutions)

| Error Code / Symptom | Root Cause | Exact Solution |
|:---|:---|:---|
| **"Could not connect to server / Connection refused on port 25"** | Windows Firewall is blocking Port 25, or hMailServer service is stopped. | Run `Get-Service hMailServer` on server. Ensure firewall rule `Mail Server - SMTP` is enabled. |
| **"SMTP authentication is required"** | Client tried sending an email without SMTP Authentication, or Thunderbird Outgoing Server Authentication method was set to Blank/None. | In Thunderbird Outgoing Server (SMTP) settings, edit the server and set **Authentication method** to **Normal password** with full email `s.pengsorng@e6.local`. In hMailServer -> Settings -> Advanced -> IP Ranges -> Internet, uncheck `Local to local email addresses`. |
| **"Unable to log in at server. Probably wrong configuration, username or password"** | 1. Account does not exist in hMailServer yet.<br>2. Username was typed as just `s.pengsorng` instead of full email `s.pengsorng@e6.local`.<br>3. Password typo (`abc@123` vs `abc@1234`). | In hMailServer, ensure account exists under Domains -> e6.local -> Accounts. In Thunderbird, set Incoming & Outgoing Username to the **full email address** (`s.pengsorng@e6.local`), and ensure password matches hMailServer. |
| **"Status: Copying message to Sent folder..." (Progress bar stuck on send)** | Email sent via SMTP successfully, but IMAP could not find/create the remote `Sent` folder on the server. | 1. In Thunderbird, go to Account Settings -> Copies & Folders -> select **Other: Local Folders -> Sent** (instant local save).<br>2. OR right-click account -> New Folder -> `Sent` to pre-create the IMAP folder on the server. |
| **"This version of Thunderbird requires Windows 10 or newer"** | Latest Thunderbird dropped support for Windows 7/8/8.1. | Download and install the official ESR release: **Thunderbird 115.15.0 (64-bit)** which fully supports Windows 8.1. |
| **Password prompt appears every single time you click Send** | Outgoing SMTP password is not saved in Thunderbird's Password Vault (Saved Logins only has `imap://`). | When the Send password prompt appears, check the box **"Use Password Manager to remember this password"** before clicking OK. |
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
| 7 | **Mail Server (SMTP, POP3, IMAP)** | 🏆 **Complete & Verified!** | [`Step7_Mail_Server_Setup.md`](Step7_Mail_Server_Setup.md) |
| 8 | **Backup Server (Windows Server Backup - wbadmin)** | ⏳ **Next Up!** | Step 8 |
| 9 | **Load Balancing (NLB / ARR Farm)** | ⏳ Next | Step 9 |
| 10 | **Failover Cluster (WSFC High Availability)** | ⏳ Final Step | Step 10 |

