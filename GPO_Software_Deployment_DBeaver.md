# GPO Software Deployment Guide: DBeaver Community & Network Trust Configuration

**Windows Server 2022 Active Directory Domain Controller**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  
**Server Hostname: WIN-J17IMHCEMA9**  
**Target Client OS: Windows 8 / 10 / 11 (pro-win-client)**  

---

## 🎯 Overview & Enterprise Objective

This guide documents the complete enterprise deployment of **DBeaver Community** across Active Directory client computers using **Group Policy Objects (GPO)**. 

To ensure installations run 100% silently without blocking on Windows SmartScreen / "Open File - Security Warning" popups during system boot, this guide includes the **Enterprise GPO Network Trust Configuration**.

---

## 🔄 Master Deployment Flowchart

```
                 ENTERPRISE GPO SOFTWARE DEPLOYMENT FLOWCHART
                        
 [ PHASE 1: SMB NETWORK SHARE PREPARATION ]
   1. Place `dbeaver-ce-26.1.5-windows-x86_64.exe` in shared folder
      UNC Path: `\\WIN-J17IMHCEMA9\sotfware\dbeaver\`
   2. Grant Read permissions to `Authenticated Users` & `Domain Computers`
            │
            ▼
 [ PHASE 2: BYPASS SECURITY WARNINGS (GPO POLICY 1) ]
   1. Configure `Site to Zone Assignment List` (*.e6.local = Zone 1)
   2. Configure `Inclusion list for low file types` (.exe;.msi;.bat;.cmd)
            │
            ▼
 [ PHASE 3: AUTOMATED SILENT INSTALLATION (GPO POLICY 2) ]
   1. Configure GPO Startup Script: `dbeaver-ce-...exe /S /allusers`
   2. Link GPO to Computer OU (`OU=Computer,OU=MainOu,DC=e6.local`)
            │
            ▼
 [ PHASE 4: ENFORCE POLICY & REBOOT CLIENT VM ]
   1. Run `gpupdate /force` on Server & Client
   2. Reboot Client VM (`shutdown /r /t 0`)
            │
            ▼
 🎉 SUCCESS! DBeaver Community Installed Silently on Desktop & Start Menu!
```

---

## 🛡️ Enterprise GPO Fix: Trust Network Shares & Bypass Security Warnings

### 🎯 Purpose
By default, Windows displays an **"Open File - Security Warning: Do you want to run this file?"** prompt when executing `.exe` files from network shares (`\\WIN-J17IMHCEMA9\`). Since GPO Startup Scripts execute during boot before any user logs in, this security popup blocks silent installations. 

Configuring these 2 policies classifies your server network shares as **Local Intranet Zone (Zone 1)**, completely suppressing the security prompt.

---

### Step 1: Create & Link GPO on `pro-win-server`
1. Open **Group Policy Management** (`gpmc.msc`) on `pro-win-server`.
2. Right-click domain **`e6.local`** (or `MainOu`) → select **Create a GPO in this domain, and Link it here...**.
3. Name the GPO: **`Bypass_Network_Security_Warnings`** → click **OK**.
4. Right-click **`Bypass_Network_Security_Warnings`** → click **Edit...**.

---

### Step 2: Add Network Shares to Local Intranet Zone
1. In Group Policy Management Editor, navigate to:  
   **Computer Configuration → Policies → Administrative Templates → Windows Components → Internet Explorer → Internet Control Panel → Security Page**
2. Double-click **`Site to Zone Assignment List`**.
3. Select **Enabled** → click the **Show...** button.
4. Add the following entries:

| Value Name (Host / Domain / IP) | Value (Zone) | Meaning |
|:---|:---|:---|
| `*.e6.local` | `1` | Local Intranet Zone |
| `192.168.1.10` | `1` | Local Intranet Zone |
| `WIN-J17IMHCEMA9` | `1` | Local Intranet Zone |

5. Click **OK** → click **Apply** → click **OK**.

---

### Step 3: Disable Security Prompts for Executables (Low-Risk File Types)
1. Navigate to:  
   **User Configuration → Policies → Administrative Templates → Windows Components → Attachment Manager**
2. Double-click **`Inclusion list for low file types`**.
3. Select **Enabled**.
4. In the **Options** box, type:
   ```text
   .exe;.msi;.bat;.cmd
   ```
5. Click **Apply** → click **OK**.

---

## 📦 Part 2: Silent DBeaver Community GPO Deployment Setup

---

### Step 1: Copy DBeaver Installer to Network Share
1. Download **DBeaver Community x64** installer on `pro-win-server` from `https://dbeaver.io/download/`.
2. Place the file in your shared folder:  
   `\\WIN-J17IMHCEMA9\sotfware\dbeaver\dbeaver-ce-26.1.5-windows-x86_64.exe`
3. Verify NTFS & Share Permissions: Grant **Read** permission to **`Domain Computers`** and **`Authenticated Users`**.

---

### Step 2: Create DBeaver Deployment GPO
1. Open **Group Policy Management** (`gpmc.msc`).
2. Right-click **Computer** OU (`OU=Computer,OU=MainOu,DC=e6,DC=local`) → select **Create a GPO in this domain, and Link it here...**.
3. Name the GPO: **`Deploy_DBeaver_Software`** → click **OK**.
4. Right-click **`Deploy_DBeaver_Software`** → click **Edit...**.

---

### Step 3: Configure Startup Script Parameters
1. Navigate to:  
   **Computer Configuration → Policies → Windows Settings → Scripts (Startup/Shutdown) → Startup**
2. Double-click **Startup** → click **Add...**:
   * **Script Name:**  
     `\\WIN-J17IMHCEMA9\sotfware\dbeaver\dbeaver-ce-26.1.5-windows-x86_64.exe`
   * **Script Parameters:**  
     `/S /allusers`
3. Click **OK** → click **Apply** → click **OK**.

---

## 🚀 Step 4: Enforce Policy & Verify Installation

### 1. Update Group Policy on Server & Client
Open **Command Prompt (Admin)** on `pro-win-server` and `pro-win-client` and run:

```cmd
gpupdate /force
```

### 2. Reboot Client VM (`pro-win-client`)
On `pro-win-client`, run:

```cmd
shutdown /r /t 0
```

### 3. Verification Result
Upon reboot, Windows executes the installer silently before login. 

* 🟢 **File System:** `C:\Program Files\DBeaver\dbeaver.exe` exists.
* 🟢 **Desktop Shortcut:** DBeaver Community icon appears on Desktop & Start Menu for all domain users.

---

## 🗑️ Part 3: Automated Silent Uninstall Guide via GPO

If you ever need to remove DBeaver from domain client computers automatically from `pro-win-server`:

### Method 1: GPO Startup Silent Uninstall Script
1. Open **Group Policy Management** (`gpmc.msc`) on `pro-win-server`.
2. Edit GPO **`Deploy_DBeaver_Software`** (or create **`Uninstall_DBeaver`**).
3. Navigate to:  
   **Computer Configuration → Policies → Windows Settings → Scripts (Startup) → Startup**
4. Add Startup Script:
   * **Script Name:** `"C:\Program Files\DBeaver\uninstall.exe"`
   * **Script Parameters:** `/S`
5. Save → run `gpupdate /force`.
6. Upon next reboot of `pro-win-client`, Windows executes `uninstall.exe /S` and cleanly removes DBeaver.

### Method 2: Manual Silent Uninstall Command (Immediate)
On `pro-win-client`, open **Command Prompt (Admin)** and run:
```cmd
"C:\Program Files\DBeaver\uninstall.exe" /S
```

---

## 🛠️ Summary of Switches & Parameters

| Parameter | Meaning & Function |
|:---|:---|
| `\\WIN-J17IMHCEMA9\...` | UNC Network Share Path accessible by `E6\CLIENT$` computer account. |
| `/S` | **Silent Mode:** Suppresses all installer dialogs, popups, and progress windows. |
| `/allusers` | **All Users Mode:** Installs DBeaver for all domain users logging into the computer. |
| `Zone Value 1` | Assigns server hostnames to the **Local Intranet Zone** to bypass SmartScreen warnings. |

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
