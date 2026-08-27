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
8. [Phase 7: Live Disaster Recovery & File Restore Simulation](#phase-7-live-disaster-recovery--file-restore-simulation)
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

### 3.1 Install via PowerShell:
Run this single command on **`pro-win-server`**:

```powershell
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
```

Expected output:
```text
Success Restart Needed Exit Code      Feature Result
------- -------------- ---------      --------------
True    No             Success        {Windows Server Backup}
```

### 3.2 Verify Installed Tools:
Check that both the GUI and CLI are registered:
```powershell
Get-Command wbadmin
```

🟢 **Result:** `wbadmin.exe` and `wbadmin.msc` are ready to use with zero reboots required!

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

## Phase 7: Live Disaster Recovery & File Restore Simulation (Exam Proof)

To prove to your professor that your backup works, we simulate an accidental disaster (deleting a file) and restore it live from backup!

### 7.1 Create a Mission-Critical Test File on `C:\`:
```powershell
New-Item -Path "C:\Corporate_Secret.txt" -ItemType File -Value "CONFIDENTIAL: RUPP Class Year 4 Semester 1 Master Key 2026"
```

### 7.2 Run a Quick File Backup of that File:
```powershell
wbadmin start backup -backupTarget:B: -include:C:\Corporate_Secret.txt -quiet
```

### 7.3 Simulate the Disaster (Accidental Deletion!):
```powershell
# The file is deleted by accident or ransomware!
Remove-Item -Path "C:\Corporate_Secret.txt" -Force

# Verify it is GONE:
Test-Path "C:\Corporate_Secret.txt"   # Returns False!
```

### 7.4 Perform the Disaster Recovery Restore:
```powershell
# Get the latest backup version identifier:
$latestVersion = (wbadmin get versions -backupTarget:B: | Select-String "Version identifier:")[-1].Line.Split(":")[-1].Trim()

# Restore the file back to its original location:
wbadmin start recovery -version:$latestVersion -items:C:\Corporate_Secret.txt -itemType:File -quiet
```

### 7.5 Verify the File is Resurrected!
```powershell
Get-Content "C:\Corporate_Secret.txt"
```

Expected output:
```text
CONFIDENTIAL: RUPP Class Year 4 Semester 1 Master Key 2026
```

🎉 **100% RECOVERY SUCCESS!** The file was resurrected from the dead using Windows Server Backup!

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
