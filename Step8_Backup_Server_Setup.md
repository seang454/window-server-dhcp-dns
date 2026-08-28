# Step 8: Backup Server (Windows Server Backup & `wbadmin`) — Complete Hands-On Lab Setup Guide

**Windows Server 2022 on VMware Workstation**  
**Domain:** `e6.local` (NetBIOS: `E6`)  
**Server Hostname:** `WIN-J17IMHCEMA9` (`pro-win-server` at `192.168.1.10`)  
**Client Hostname:** `client` (`pro-win-client` at `192.168.1.100`)  
**Primary System Drive:** `C:\` (OS, Active Directory, Databases, Mail)  
**Dedicated Backup Drive:** `B:\` (or `E:\`, 40 GB Virtual Hard Disk dedicated to Backups)

---

## 📖 Table of Contents

1. [Lab Topology & Disaster Recovery Overview](#1-lab-topology--disaster-recovery-overview)
2. [Phase 1: Add a Dedicated Virtual Hard Disk in VMware Workstation](#phase-1-add-a-dedicated-virtual-hard-disk-in-vmware-workstation)
3. [Phase 2: Initialize & Format the Backup Drive in Windows Server](#phase-2-initialize--format-the-backup-drive-in-windows-server)
4. [Phase 3: Install Windows Server Backup (`Windows-Server-Backup`)](#phase-3-install-windows-server-backup-windows-server-backup)
5. [Phase 4: Perform a One-Time System State Backup via PowerShell (`wbadmin`)](#phase-4-perform-a-one-time-system-state-backup-via-powershell-wbadmin)
6. [Phase 5: Perform a Full Server / Volume Backup via GUI (`wbadmin.msc`)](#phase-5-perform-a-full-server--volume-backup-via-gui-wbadminmsc)
7. [Phase 6: Configure an Automated Daily Backup Schedule (2:00 AM)](#phase-6-configure-an-automated-daily-backup-schedule-200-am)
8. [Phase 7: The Master 7-Step Enterprise Disaster Recovery Testing Suite](#phase-7-the-master-7-step-enterprise-disaster-recovery-testing-suite)
   * [7.1 Flow 1: Backup Catalog Verification](#-71-flow-1-backup-catalog-verification-checking-the-storage-vault)
   * [7.2 Flow 2: Live Mission-Critical File Disaster Recovery](#-72-flow-2-live-mission-critical-file-disaster-recovery-ransomware--deletion-simulation)
   * [7.3 Flow 3: Automated Daily 2:00 AM Schedule Verification](#-73-flow-3-automated-daily-200-am-schedule-verification-unattended-bcp-policy)
   * [7.4 Flow 4: Visual GUI Console Verification](#-74-flow-4-visual-gui-console-verification-executive--auditor-proof)
   * [7.5 Flow 5: VSS Writer Health & Database Consistency Check](#-75-flow-5-vss-writer-health--database-consistency-check-bank-grade-integrity)
   * [7.6 Flow 6: Active Directory Object Disaster Recovery](#-76-flow-6-active-directory-object-disaster-recovery-deleted-user-account-resurrect)
   * [7.7 Flow 7: Automated Backup Retention Policy & Storage Purge](#-77-flow-7-automated-backup-retention-policy--storage-purge-lifecycle-management)
9. [Phase 8: Troubleshooting Common Windows Server Backup Errors](#phase-8-troubleshooting-common-windows-server-backup-errors)
10. [Summary of Master Server Roles Completed](#10-summary-of-master-server-roles-completed)

---

## 1. Lab Topology & Disaster Recovery Overview

In enterprise IT, a server without backups is a ticking time bomb. Across Steps 1 to 7, you built 7 mission-critical services on `pro-win-server`. **Step 8 creates an impenetrable safety net.**

```text
  ========================================================================================
                          ENTERPRISE BACKUP & DISASTER RECOVERY ARCHITECTURE
  ========================================================================================

  🖥️ pro-win-server (192.168.1.10 - Windows Server 2022)
  ┌──────────────────────────────────────────────────────────────────────────────────────┐
  │  C:\ DRIVE (Production Storage)                                                      │
  │  ├── 🗄️ Active Directory Database (C:\Windows\NTDS\ntds.dit)                        │
  │  ├── 📜 Group Policies & Logon Scripts (C:\Windows\SYSVOL\)                         │
  │  ├── 🔑 System Registry Hives (SAM, SECURITY, SYSTEM, SOFTWARE)                     │
  │  ├── 🌐 IIS Websites & Next.js App (C:\inetpub\ & Node.js)                           │
  │  ├── 🗄️ PostgreSQL 18 & Oracle 19c Databases                                        │
  │  ├── ✉️ hMailServer Email Inboxes (C:\Program Files (x86)\hMailServer\Data\)        │
  │  └── 🛡️ VPN & RADIUS Configurations                                                 │
  └────────────────────────────────────────┬─────────────────────────────────────────────┘
                                           │
                                           │ Volume Shadow Copy Service (VSS)
                                           │ Takes live, consistent point-in-time snapshot
                                           │ without stopping any running services!
                                           ▼
  ┌──────────────────────────────────────────────────────────────────────────────────────┐
  │  B:\ DRIVE (Dedicated Virtual Backup Hard Disk - 40 GB)                              │
  │  └── 📁 WindowsImageBackup\                                                         │
  │      └── 📁 WIN-J17IMHCEMA9\                                                         │
  │          ├── 📦 System State Backup (Active Directory, Registry, Boot)               │
  │          ├── 📦 Volume Shadow Copies (VHDX disk images)                              │
  │          └── 📜 Backup Catalog & History Logs                                        │
  └──────────────────────────────────────────────────────────────────────────────────────┘
  ========================================================================================
```

---

## Phase 1: Add a Dedicated Virtual Hard Disk in VMware Workstation

In real enterprise data centers, backups are **NEVER saved onto the same physical drive as Windows (`C:\`)**. If the physical disk crashes, both Windows and your backups would be destroyed! We add a dedicated secondary hard disk in VMware.

### 1.1 Add the Virtual Hard Disk:
1. In VMware Workstation, look at your VM tab: **`pro-win-server`**.
2. Click **VM** on the top menu bar ──► click **`Settings...`** (or press `Ctrl + D`).
3. Under the **Hardware** tab, click the **`Add...`** button at the bottom.
4. Select **`Hard Disk`** ──► click **`Next`**.
5. Disk Type: Select **`SCSI (Recommended)`** ──► click **`Next`**.
6. Disk: Select **`Create a new virtual disk`** ──► click **`Next`**.
7. Disk Capacity:
   * **Maximum disk size (GB):** Type **`40.0`** *(or `60.0` if you have plenty of host space)*.
   * Select: 🔘 **`Store virtual disk as a single file`**.
   * *(Optional: Ensure `Allocate all disk space now` is UNCHECKED so it only uses disk space as it fills up!)*
8. Click **`Next`** ──► click **`Finish`** ──► click **`OK`**!

🟢 **Result:** VMware creates the second virtual hard drive and attaches it to your server immediately!

---

## Phase 2: Initialize & Format the Backup Drive in Windows Server

Now we bring the new virtual disk online, initialize it with a GPT partition table, and format it as Drive **`B:\`** (labeled **`Backups`**).

### 2.1 One-Line PowerShell Disk Provisioning:
Run this command in PowerShell as Administrator on **`pro-win-server`**:

```powershell
# Find the uninitialized new disk (Disk 1), bring it online, initialize as GPT, and format as B:
Get-Disk | Where-Object PartitionStyle -eq 'RAW' | 
    Initialize-Disk -PartitionStyle GPT -PassThru | 
    New-Partition -DriveLetter B -UseMaximumSize | 
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Backups" -Confirm:$false
```

### 2.2 Verify the New Drive:
```powershell
Get-Volume -DriveLetter B
```

Expected output:
```text
DriveLetter FriendlyName FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining     Size
----------- ------------ -------------- --------- ------------ ----------------- -------------     ----
B           Backups      NTFS           Fixed     Healthy      OK                     39.85 GB 39.99 GB
```

🟢 **Result:** Drive `B:\` is mounted, healthy, and ready to store backups!

---

## Phase 3: Install Windows Server Backup (`Windows-Server-Backup`)

Windows Server does not have the backup feature installed by default. We install the feature and its management tools (`wbadmin` CLI and GUI console).

### 3.1 Option A: Install via Server Manager GUI:
1. Open **Server Manager**.
2. Top-right menu: click **`Manage`** ──► click **`Add Roles and Features`**.
3. Installation Type: Select **`Role-based or feature-based installation`** ──► click **`Next`**.
4. Server Selection: Select **`pro-win-server` (192.168.1.10)** ──► click **`Next`**.
5. Server Roles: Click **`Next`** (Windows Server Backup is a *Feature*, not a Role).
6. Features: Scroll down and check the box:  
   👉 ☑️ **`Windows Server Backup`**
7. Confirmation: Click **`Install`**!

---

### 3.2 Option B: Install via PowerShell (Fastest - 1 Line):
Run this single command in **PowerShell (Administrator)** on **`pro-win-server`**:

```powershell
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
```

Expected output:
```text
Success Restart Needed Exit Code      Feature Result
------- -------------- ---------      --------------
True    No             Success        {Windows Server Backup}
```

---

### 3.3 Verify Installed Tools:
Check that both the GUI and CLI are registered:
```powershell
Get-Command wbadmin
```

🟢 **Result:** `wbadmin.exe` CLI and `wbadmin.msc` GUI (accessible in Server Manager ──► Tools ──► Windows Server Backup) are ready to use with zero reboots required!

---

## Phase 4: Perform a One-Time System State Backup via PowerShell (`wbadmin`)

### 🧠 What is System State?
On a Domain Controller, the **System State** is the heartbeat of your enterprise. It contains:
1. **Active Directory Database (`ntds.dit`)** — Every user, password, computer, and OU in `e6.local`.
2. **SYSVOL Directory** — All Group Policy Objects (GPOs) and logon scripts.
3. **Registry Hives** — All system, security, and hardware configurations.
4. **Boot Configuration Data (BCD)** — Boot files required to start Windows.

### 4.1 Run the System State Backup Command:
Run this command in PowerShell as Administrator on **`pro-win-server`**:

```powershell
wbadmin start systemstatebackup -backupTarget:B: -quiet
```

### 🔍 Command Parameter Breakdown:
* `wbadmin start systemstatebackup`: Initiates the specialized System State backup engine.
* `-backupTarget:B:`: Directs the backup files to our newly formatted 40 GB `B:\` drive.
* `-quiet`: Runs the backup without asking for manual confirmation prompts (`Y/N`).

### 📊 What You Will See During Execution:
```text
wbadmin 1.0 - Backup command-line tool
(C) Copyright 2013 Microsoft Corporation. All rights reserved.

Retrieving volume information...
This will back up the system state from volumes to B:.
Do you want to start the backup operation?
Creating a shadow copy of the volumes specified for backup...
Creating a shadow copy of the volumes specified for backup...
Scanning files...
Found 15284 files.
Backing up files...
Overall progress: 100%
The backup operation completed successfully.
```

### 4.2 Verify the Backup on Disk:
```powershell
wbadmin get versions -backupTarget:B:
```

Expected output:
```text
Backup time: 8/28/2026 1:00 AM
Backup target: Fixed Disk labeled Backups(B:)
Version identifier: 08/28/2026-06:00
Can recover: Volume(s), File(s), Application(s), Bare Metal Recovery, System State
```

🟢 **Result:** Your Active Directory and system state are safely archived in `B:\WindowsImageBackup\`!

---

## Phase 5: Perform a Volume Backup via GUI (`wbadmin.msc`)

For everyday administrators who prefer a graphical interface, Windows Server Backup includes a dedicated MMC console.

### 5.1 Open the Console:
1. Press **`Win + R`** ──► type:
   ```text
   wbadmin.msc
   ```
   and press **Enter**.
2. In the left panel, click on **`Local Backup`**.

### 5.2 Run Backup Once (Wizard):
1. In the right **Actions** pane, click 👉 **`Backup Once...`**.
2. **Backup Options:** Select 🔘 **`Different options`** ──► click **Next**.
3. **Select Backup Configuration:**
   * Select 🔘 **`Custom`** ──► click **Next**.
4. **Select Items for Backup:**
   * Click **`Add Items`**.
   * Check: ✅ **`System State`**
   * Check: ✅ **`C:`** (or specific folders like `C:\Program Files (x86)\hMailServer\Data`)
   * Click **OK** ──► click **Next**.
5. **Specify Destination Type:**
   * Select 🔘 **`Local drives`** ──► click **Next**.
6. **Select Backup Destination:**
   * Choose: **`Backups (B:)`** ──► click **Next**.
7. **Confirmation:** Click 👉 **`Backup`**!

Watch the progress bar advance as Volume Shadow Copy (VSS) creates the snapshot and writes the `.vhdx` image to drive `B:\`!

---

## Phase 6: Configure an Automated Daily Backup Schedule (2:00 AM)

A manual backup is useless if an administrator forgets to run it. Enterprise standards require **automated daily unattended backups** scheduled during off-peak hours (e.g. 2:00 AM).

### 6.1 Configure Daily Schedule via PowerShell:
Run this script to configure an automatic daily backup of the System State and `C:\` drive to `B:\` at 2:00 AM:

```powershell
# Create a new backup policy:
$policy = New-WBPolicy

# Add System State and Bare Metal Recovery:
Add-WBSystemState -Policy $policy
Add-WBBareMetalRecovery -Policy $policy

# Add C: drive volume to policy:
$volume = Get-WBVolume -VolumePath "C:"
Add-WBVolume -Policy $policy -Volume $volume

# Set the dedicated backup target drive (B:):
$target = New-WBBackupTarget -Disk (Get-WBDisk | Where-Object { $_.Properties -match "B:" })
Add-WBBackupTarget -Policy $policy -Target $target

# Set schedule time (2:00 AM daily):
Set-WBSchedule -Policy $policy -Schedule 02:00

# Save and activate the policy:
Set-WBPolicy -Policy $policy -Force
```

### 6.2 Verify the Active Schedule:
```powershell
Get-WBPolicy
Get-WBSchedule -Policy (Get-WBPolicy)
```

Expected output:
```text
Schedule : {02:00:00}
```

🟢 **Result:** Every single night at 2:00 AM, Windows Server Backup will silently back up all changes, Active Directory accounts, and mail data to Drive `B:\`!

---

## Phase 7: The Master 7-Step Enterprise Disaster Recovery Testing Suite

In real-world enterprise infrastructure (banks, hospitals, telecom datacenters), taking a backup is only 50% of the job. The other 50% is **rigorous, multi-scenario testing** to guarantee that data can be resurrected without corruption under real disaster conditions.

Below is the complete **7-Step Enterprise Disaster Recovery Testing Suite**:

---

### 🧪 7.1 Flow 1: Backup Catalog Verification (Checking the Storage Vault)

#### 🏢 Why We Do / Configure This:
Before an organization can trust a disaster recovery plan, administrators must inspect the **Backup Catalog**. The catalog is the master database indexing every backup snapshot, timestamp, and recoverable component on Drive `B:\`. If the catalog is corrupt or missing, Windows cannot locate the `.vhdx` images during an emergency.

#### 🛠️ Step-by-Step Execution Command:
Run this command in **PowerShell (Administrator)** on `pro-win-server`:

```powershell
# Query the local backup catalog on Drive B:
wbadmin get versions -backupTarget:B:
```

#### 📊 Expected Output & Verification:
```text
wbadmin 1.0 - Backup command-line tool
(C) Copyright Microsoft Corporation. All rights reserved.

Backup time: 08/29/2026-02:30
Backup target: Fixed Disk labeled Backups(B:)
Version identifier: 08/29/2026-02:30
Can recover: Volume(s), File(s), Application(s), System State
Snapshot ID: {a4f129c8-72b1-49e0-811c-d32e1892fbc4}
```

🎓 **What to Tell the Professor:**  
*"This command inspects the VSS catalog on Drive `B:\` and proves that our backup version identifier is healthy, valid, and fully indexed to restore System State, Volumes, and individual Files."*

---

### 🧪 7.2 Flow 2: Live Mission-Critical File Disaster Recovery (Ransomware / Deletion Simulation)

#### 🏢 Why We Do / Configure This:
Demonstrates point-in-time file recovery (RPO & RTO). When a critical company document or database file is maliciously encrypted by ransomware or accidentally deleted by an employee with `Shift + Delete`, the administrator extracts the original file directly from the `.vhdx` shadow image and resurrects it live without rebooting the server.

#### 🛠️ Step-by-Step Execution Commands:

```powershell
# 1. Create a confidential mission-critical company file on Drive C:
Set-Content -Path "C:\Corporate_Secret.txt" -Value "CONFIDENTIAL: RUPP Class Year 4 Master Security Key 2026"

# 2. Capture a standalone backup of this specific file to Drive B:
wbadmin start backup -backupTarget:B: -include:C:\Corporate_Secret.txt -quiet

# 3. Simulate the Disaster (Permanently delete the file!):
Remove-Item -Path "C:\Corporate_Secret.txt" -Force

# 4. Prove the file is completely GONE from the system:
Test-Path "C:\Corporate_Secret.txt"   # Returns: False!

# 5. Perform the Disaster Recovery Restore from Drive B:
$latestVer = (wbadmin get versions -backupTarget:B: | Select-String "Version identifier:")[-1].Line.Split(":")[-1].Trim()
wbadmin start recovery -version:$latestVer -items:C:\Corporate_Secret.txt -itemType:File -quiet

# 6. Verify the file is resurrected with original content intact:
Get-Content "C:\Corporate_Secret.txt"
```

#### 📊 Expected Output & Verification:
```text
CONFIDENTIAL: RUPP Class Year 4 Master Security Key 2026
```

🎓 **What to Tell the Professor:**  
*"We simulated a ransomware attack by permanently deleting `Corporate_Secret.txt`. Using `wbadmin start recovery`, we extracted the file from the shadow copy on `B:\` and restored it in 5 seconds with 100% data integrity."*

---

### 🧪 7.3 Flow 3: Automated Daily 2:00 AM Schedule Verification (Unattended BCP Policy)

#### 🏢 Why We Do / Configure This:
Human administrators forget manual tasks. Enterprise Business Continuity Plans (BCP) require **automated, unattended daily backups** scheduled during off-peak hours (e.g. 2:00 AM) to prevent database lockups and network congestion during active business hours.

#### 🛠️ Step-by-Step Execution Commands:

```powershell
# 1. Verify the active automated backup policy registered in Windows Task Scheduler:
Get-WBPolicy

# 2. Check the exact scheduled execution time:
Get-WBSchedule -Policy (Get-WBPolicy)
```

#### 📊 Expected Output & Verification:
```text
Schedule : {02:00:00}
```

🎓 **What to Tell the Professor:**  
*"This verifies that our Business Continuity Plan is automated. Windows Task Scheduler triggers a full snapshot every night at 2:00 AM without requiring any human intervention."*

---

### 🧪 7.4 Flow 4: Visual GUI Console Verification (Executive & Auditor Proof)

#### 🏢 Why We Do / Configure This:
External compliance auditors (e.g. ISO 27001, Central Bank audits) and executive managers require visual verification of backup health. The MMC GUI console provides visual status indicators and a visual calendar history of successful recovery points.

#### 🛠️ Step-by-Step Execution:
1. Open **Server Manager** ──► Click **`Tools`** ──► Click **`Windows Server Backup`** (or press `Win + R` and type `wbadmin.msc`).
2. In the left navigation tree, select **`Local Backup`**.
3. Inspect the center dashboard:
   * **Status:** Look for the green shield: **`Last Backup: Successful`**.
   * **Next Backup:** Shows scheduled time (`2:00 AM`).
   * **Total Backups:** Shows the number of available point-in-time recovery versions.

🎓 **What to Tell the Professor:**  
*"We open `wbadmin.msc` to demonstrate the graphical management console, showing audit-ready green health indicators and calendar snapshot history for executive reporting."*

---

### 🧪 7.5 Flow 5: VSS Writer Health & Database Consistency Check (Bank-Grade Integrity)

#### 🏢 Why We Do / Configure This:
Backing up an active, running Active Directory (`ntds.dit`) or SQL database without stable VSS writers produces a **corrupted, unbootable backup**. VSS Writers pause disk writes for a few milliseconds to ensure database consistency. Checking `vssadmin list writers` guarantees that all critical system components flushed their buffers cleanly.

#### 🛠️ Step-by-Step Execution Command:

```powershell
# Inspect the health of all registered Volume Shadow Copy Service (VSS) writers:
vssadmin list writers
```

#### 📊 Expected Output & Verification:
Inspect the output to ensure all critical writers show `State: [1] Stable` and `Last error: No error`:
```text
Writer name: 'NTDS'
   State: [1] Stable
   Last error: No error

Writer name: 'Registry'
   State: [1] Stable
   Last error: No error

Writer name: 'System Writer'
   State: [1] Stable
   Last error: No error

Writer name: 'IIS Metabase Writer'
   State: [1] Stable
   Last error: No error
```

🎓 **What to Tell the Professor:**  
*"We execute `vssadmin list writers` to verify bank-grade transactional consistency. All core writers—especially NTDS for Active Directory and the Registry Writer—are in a stable state with zero errors."*

---

### 🧪 7.6 Flow 6: Active Directory Object Disaster Recovery (Deleted User Account Resurrect)

#### 🏢 Why We Do / Configure This:
Simple file backup does not protect Active Directory identities. If an administrator accidentally deletes an employee account (`s.pengsorng`), the user's unique **Security Identifier (SID)**, Kerberos password hashes, and group permissions are lost. Active Directory object recovery resurrects the user with their **exact same SID**, allowing them to log in immediately without IT having to reconfigure 50 permissions manually!

#### 🛠️ Step-by-Step Execution Commands:

```powershell
# 1. Enable the Active Directory Recycle Bin feature on forest e6.local (Run once):
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'e6.local' -Confirm:$false

# 2. Simulate Disaster: Delete domain user account 's.pengsorng':
Get-ADUser -Identity "s.pengsorng" | Remove-ADUser -Confirm:$false

# 3. Verify user is DELETED (Query returns an error):
Get-ADUser -Identity "s.pengsorng"   # Cannot find an object with identity!

# 4. Resurrect the deleted user live from the Active Directory tombstone vault:
Get-ADObject -Filter 'isDeleted -eq $true -and name -like "*s.pengsorng*"' -IncludeDeletedObjects | Restore-ADObject

# 5. Verify the user is resurrected with full domain attributes intact:
Get-ADUser -Identity "s.pengsorng"
```

#### 📊 Expected Output & Verification:
```text
DistinguishedName : CN=s.pengsorng,CN=Users,DC=e6,DC=local
Enabled           : True
Name              : s.pengsorng
ObjectClass       : user
UserPrincipalName : s.pengsorng@e6.local
```

🎓 **What to Tell the Professor:**  
*"We deleted user `s.pengsorng` from Active Directory. Using Active Directory disaster recovery, we resurrected the user account with their original SID and password intact, so the employee can immediately log in from their client machine."*

---

### 🧪 7.7 Flow 7: Automated Backup Retention Policy & Storage Purge (Lifecycle Management)

#### 🏢 Why We Do / Configure This:
Without automated retention policies, daily enterprise backups will rapidly fill up storage targets, eventually causing backup failures due to `0x80070070 (Disk Full)`. Big enterprises enforce **Retention Rules** (e.g. keep only the 3 most recent backups and automatically purge stale historical snapshots to recycle disk space).

#### 🛠️ Step-by-Step Execution Command:

```powershell
# Purge historical System State backups, keeping strictly the 3 most recent versions:
wbadmin delete systemstatebackup -keepVersions:3 -backupTarget:B: -quiet
```

#### 📊 Expected Output & Verification:
```text
wbadmin 1.0 - Backup command-line tool
(C) Copyright Microsoft Corporation. All rights reserved.

The operation succeeded.
Deleted 0 backup versions older than the latest 3 versions.
```

🎓 **What to Tell the Professor:**  
*"We execute storage lifecycle retention policies to enforce automated disk recycling, ensuring that Drive `B:\` preserves the 3 newest operational points while preventing storage exhaustion."*

---

## Phase 8: Troubleshooting Common Windows Server Backup Errors

| Error Code / Symptom | Root Cause | Exact Solution |
|:---|:---|:---|
| **"The backup storage location is invalid"** | Target drive `B:\` was formatted with FAT32 instead of NTFS/ReFS, or is offline. | Run `Get-Disk` to ensure disk is Online. Format with NTFS: `Format-Volume -DriveLetter B -FileSystem NTFS`. |
| **"Error: The Volume Shadow Copy operation failed (0x80042306)"** | VSS service is disabled, or another backup software (like VMware Tools quiescing) locked VSS. | Run `Restart-Service VSS` in PowerShell. Ensure `swprv` (Microsoft Software Shadow Copy Provider) is running. |
| **"System State backup requires a separate volume"** | You attempted to save a System State backup onto the same drive (`C:\`) being backed up. | Windows Server prohibits saving System State to the source drive. Always target a separate drive: `-backupTarget:B:`. |
| **"The disk is full (0x80070070)"** | Backup disk `B:\` ran out of free space. | Windows Server Backup automatically purges old shadow copies when full, but if manual VHDXs were copied, delete them or expand the virtual disk in VMware. |
| **"DSRM password unknown during recovery"** | When booting into Directory Services Restore Mode, the standard Active Directory admin password doesn't work. | DSRM uses its own local administrator password set during `dcpromo`. Reset it using: `ntdsutil "set dsrm password" "reset on server null" q q`. |

---

## 10. Summary of Master Server Roles Completed

| # | Master Server Role | Status | Documentation File |
|:---:|:---|:---:|:---|
| **1** | **DHCP & DNS Core Network** | ✅ Complete | [`Step1_DHCP_DNS_Setup.md`](Step1_DHCP_DNS_Setup.md) |
| **2** | **File Server & FTP Server** | ✅ Complete | [`Step2_File_FTP_Server_Setup.md`](Step2_File_FTP_Server_Setup.md) |
| **3** | **Web Server (IIS + Next.js + PM2)** | ✅ Complete | [`Step3_IIS_Web_Server_Setup.md`](Step3_IIS_Web_Server_Setup.md) |
| **4** | **Database Server (Oracle & PostgreSQL)** | ✅ Complete | [`Step4_Database_Server_Setup.md`](Step4_Database_Server_Setup.md) |
| **5** | **Terminal Server (RDS / Remote Desktop)** | ✅ Complete | [`Step5_Terminal_Server_RDS_Setup.md`](Step5_Terminal_Server_RDS_Setup.md) |
| **6** | **VPN & RADIUS Server (RRAS + NPS)** | ✅ Complete | [`Step6_VPN_and_RADIUS_Server_Setup.md`](Step6_VPN_and_RADIUS_Server_Setup.md) |
| **7** | **Mail Server (SMTP, IMAP, POP3)** | ✅ Complete | [`Step7_Mail_Server_Setup.md`](Step7_Mail_Server_Setup.md) |
| **8** | **Backup Server (Windows Server Backup & `wbadmin`)** | 🚀 **Ready to Execute!** | [`Step8_Backup_Server_Setup.md`](Step8_Backup_Server_Setup.md) |
| **9** | **Load Balancing (NLB / IIS ARR Server Farm)** | ⏳ Next | Step 9 |
| **10** | **Failover Cluster (WSFC High Availability)** | ⏳ Final Step | Step 10 |
