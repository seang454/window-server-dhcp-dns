# Step 2: File Server + FTP Server Setup Guide

**Windows Server 2022 on VMware Workstation**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  

---

## Overview Architecture

```
                    ┌────────────────────────────────────────┐
                    │               CLIENT VM                │
                    │             IP: 192.168.1.100          │
                    │             Domain: e6.local           │
                    └───────────────────┬────────────────────┘
                                        │
                         VMnet8 NAT Network (192.168.1.0/24)
                                        │
                    ┌───────────────────┴────────────────────┐
                    │            WINDOWS SERVER              │
                    │             IP: 192.168.1.10           │
                    │             Domain: e6.local           │
                    │                                        │
                    │  ┌──────────────────────────────────┐  │
                    │  │ File Server Role (SMB Port 445)   │  │
                    │  │ Path: C:\Shares\CompanyData      │  │
                    │  └──────────────────────────────────┘  │
                    │  ┌──────────────────────────────────┐  │
                    │  │ FTP Server Role (Port 21)        │  │
                    │  │ Path: C:\inetpub\ftproot         │  │
                    │  └──────────────────────────────────┘  │
                    └────────────────────────────────────────┘
```

> **Note on Network Alignment:** Both Server (`192.168.1.10`) and Client (`192.168.1.100`) are connected to **VMnet8** and belong to the exact same subnet (`192.168.1.0/24`). This allows direct local SMB file sharing and FTP communication with `<1ms` response time!

---

## Key Concepts Explained

### 1. Share Permissions vs. NTFS Permissions

When a user accesses a file over the network, Windows evaluates **two layers** of security:

```
Network Request  ──► [ 1. Share Permissions ] ──► [ 2. NTFS Permissions ] ──► Access Granted/Denied
```

> **The Rule of Permissions:** When Share Permissions and NTFS Permissions conflict, **the MOST RESTRICTIVE permission wins!**
> 
> **Best Practice:** 
> - Set **Share Permissions** to `Everyone = Full Control`.
> - Control actual security using **NTFS Permissions** (Security tab) because NTFS permissions apply both locally and over the network!

### 2. Active Directory Security Groups (`Domain Users` vs. `Domain Admins`)

In Active Directory, users are organized into **Security Groups** to manage folder permissions easily:

| Security Group | Who is inside? | Best Used For |
|:---|:---|:---|
| **`Domain Users`** | **EVERY user account** created in Active Directory (automatically added). | Granting general access to company-wide shared folders (`CompanyData`, `Public`). |
| **`Domain Admins`** | System Administrators only. | Full administrative control over all domain controllers, servers, and computers. |

> **Why use `Domain Users` in folder permissions?** 
> Instead of manually typing 500 employee names into folder permissions one by one, you simply add `e6\Domain Users`. Automatically, every current and future employee gets access!

---

## Part A: File Server Setup (SMB Shared Folders)

### A1. Create Folder Structure on Windows Server (`pro-win-server`)

1. Open **File Explorer** on your Windows Server.
2. Go to `C:\` drive and create a folder named `Shares`.
3. Inside `C:\Shares`, create 3 folders:
   - `CompanyData`  *(For general company documents)*
   - `HR_Private`   *(Restricted folder for testing access control)*
   - `Public`       *(For shared read-only files)*

---

### A2. Configure Sharing & NTFS Permissions

#### Folder 1: `CompanyData` (Accessible to all domain users)
1. Right-click `C:\Shares\CompanyData` → select **Properties**.
2. Click the **Sharing** tab → click **Advanced Sharing...**
3. Check ✅ **Share this folder**.
4. Share Name: `CompanyData`.
5. Click **Permissions**:
   - Select `Everyone` → Check **Full Control**, **Change**, **Read**.
   - Click **OK**.
6. Click the **Security** tab (NTFS Permissions):
   - Click **Edit...**
   - Click **Add...** → type `Domain Users` → click **Check Names** → click **OK**.
   - Grant `Domain Users`: Check **Modify**, **Read & execute**, **List folder contents**, **Read**, **Write**.
7. Click **OK** → click **Close**.

#### Folder 2: `HR_Private` (Restricted to Administrators only)
1. Right-click `C:\Shares\HR_Private` → select **Properties**.
2. Go to **Sharing** tab → **Advanced Sharing...** → Check ✅ **Share this folder** → set Share Permissions `Everyone = Full Control` → **OK**.
3. Go to **Security** tab → click **Advanced**:
   - Click **Disable inheritance** → select **Convert inherited permissions into explicit permissions**.
   - Select `Domain Users` or `Users` → click **Remove**.
   - Ensure only `Administrators` and `SYSTEM` are listed with Full Control.
4. Click **OK**.

---

### A3. Two Client Testing Approaches (Domain-Joined vs. Unjoined)

You can test File Server and FTP Server access from your client computer using two different methods:

| Approach | Client Setup | Experience | Enterprise Status |
|:---|:---|:---|:---|
| **Approach 1 ⭐ (RECOMMENDED)** | **Client Joined to Domain (`e6.local`)** | **Single Sign-On (SSO):** Automatically logs in with domain credentials. No login popups! | **Industry Standard & Recommended for Class.** |
| **Approach 2** | **Client NOT Joined to Domain (Workgroup)** | Windows pops up a credentials window asking for `E6\Administrator` every time. | Alternative / Quick Test method. |

> **Why Approach 1 (Domain Joined) is RECOMMENDED:**
> 1. **Single Sign-On (SSO):** Users log in once at Windows startup (`E6\John`). Access to network shares (`\\server1.e6.local\CompanyData`) is instant without re-typing passwords.
> 2. **Course Grading:** Professors grade whether client machines are properly integrated into Active Directory.
> 3. **NTFS Permission Testing:** Allows testing different domain user accounts (`E6\HR_User` vs `E6\Sales_User`).

---

### A4. Client Testing Flow for File Server (`pro-win-client`)

```
                          CLIENT TESTING FLOW
                          
   [1. Open Explorer] ──► [2. Type \\server1.e6.local\CompanyData]
                                        │
                                        ▼
   [5. File Appears on Server] ◄── [4. Create test.txt] ◄── [3. Access Granted!]
```

#### Test 1: Access Shared Folder via UNC Path
1. Log into your **`pro-win-client`** VM.
2. Open **File Explorer** (or press `Win + R` to open Run dialog).
3. Type the UNC path:
   ```text
   \\server1.e6.local\CompanyData
   ```
   *(or `\\192.168.1.10\CompanyData`)*
4. Press **Enter**.
5. **Verify:** The folder opens!
6. **Create a Test File:**
   - Right-click inside the folder → **New → Text Document**.
   - Name it `client_test.txt`.
   - Open it, type *"Hello from Client VM!"*, and save it.
7. **Verify on Server:** Go to `C:\Shares\CompanyData` on `pro-win-server` and confirm `client_test.txt` exists!

---

#### Test 2: Map a Network Drive (Drive `Z:`)
1. On **`pro-win-client`**, open **File Explorer** → click **This PC**.
2. Click the **Computer** tab at the top menu → click **Map network drive**.
3. Settings:
   - **Drive:** Select `Z:`
   - **Folder:** Type `\\server1.e6.local\CompanyData`
   - Check ✅ **Reconnect at sign-in**
4. Click **Finish**.
5. **Verify:** Drive `Z:` now appears under **This PC** like a local hard drive!

---

#### Test 3: Verify Security Restrictions (`HR_Private`)
1. On **`pro-win-client`**, open Run (`Win + R`) and type:
   ```text
   \\server1.e6.local\HR_Private
   ```
2. **Expected Result:** 
   - If logged in as a normal domain user: ❌ **"Windows cannot access \\server1.e6.local\HR_Private - Access is denied."**
   - This proves your NTFS security permissions are working properly!

---

## Part B: FTP Server Setup (File Transfer Protocol)

### B1. Install FTP Server Role via Server Manager

1. Open **Server Manager** on `pro-win-server`.
2. Click **Manage → Add Roles and Features**.
3. Click **Next** until you reach **Server Roles**.
4. Scroll down and expand **Web Server (IIS)** → expand **FTP Server**:
   - Check ✅ **FTP Service**
   - Check ✅ **FTP Extensibility**
5. Click **Next → Next → Install**.
6. Wait for installation to complete → click **Close**.

---

### B2. Create FTP Folder & Configure FTP Site

1. Open **File Explorer** on Server → navigate to `C:\inetpub\`.
2. Create a folder named `ftproot` (Path: `C:\inetpub\ftproot`).
3. Inside `C:\inetpub\ftproot`, create a file named `welcome.txt` with text *"Welcome to Lab FTP Server!"*.
4. Open **Server Manager → Tools → Internet Information Services (IIS) Manager**.
5. Expand your server name (`WIN-J17IMHCEMA9`).
6. Right-click **Sites** → select **Add FTP Site...**

#### Configure FTP Site Wizard:
* **FTP Site Name:** `LabFTP`
* **Physical Path:** `C:\inetpub\ftproot` → click **Next**.
* **Binding and SSL Settings:**
  - IP Address: `All Unassigned` (or `192.168.1.10`)
  - Port: `21`
  - SSL: Select **No SSL** → click **Next**.
* **Authentication and Authorization Information:**
  - Authentication: Check ✅ **Basic**
  - Allow access to: Select **All users**
  - Permissions: Check ✅ **Read** and ✅ **Write**
* Click **Finish**.

---

### B3. Enable FTP Firewall Rules

Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
Enable-NetFirewallRule -DisplayGroup "FTP Server"
```

---

### B4. Client Testing Flow for FTP Server (`pro-win-client`)

```
                           FTP TESTING FLOW
                           
   [1. Open Client CMD] ──► [2. ftp server1.e6.local] ──► [3. Enter Credentials]
                                                                  │
                                                                  ▼
   [6. File Downloaded!] ◄── [5. get welcome.txt] ◄── [4. Type dir to list]
```

#### Test 1: Access FTP via Command Prompt
1. Open **Command Prompt** on `pro-win-client`.
2. Connect to FTP:
   ```cmd
   ftp server1.e6.local
   ```
3. When prompted for User:
   ```text
   Administrator
   ```
4. When prompted for Password:
   ```text
   (your domain admin password)
   ```
   *(Note: Password characters will not show while typing)*
5. You will see: `230 User logged in, proceed.`
6. List files:
   ```cmd
   dir
   ```
   *(You will see `welcome.txt` listed!)*
7. Download test file:
   ```cmd
   get welcome.txt
   ```
8. Type `quit` to exit.

---

#### Test 2: Access FTP via Web Browser or File Explorer
1. Open **File Explorer** or **Internet Explorer** on `pro-win-client`.
2. Type in address bar:
   ```text
   ftp://server1.e6.local
   ```
3. Enter username `Administrator` and password when prompted.
4. **Verify:** You can drag and drop files into the window to upload files to the server via FTP!

---

## Troubleshooting Guide for Step 2

### 1. Error: "Access is Denied" when connecting to Network Share
- **Cause:** NTFS permissions on the folder restrict your account.
- **Fix:** On Server, right-click folder → Properties → Security tab → ensure `Domain Users` or your specific user account is added with Read/Write permissions.

### 2. Error: "Windows cannot find \\server1.e6.local"
- **Cause:** DNS resolution issue.
- **Fix:** Run `nslookup server1.e6.local` on client. If it fails, verify client's DNS is set to `192.168.1.10`.

### 3. Error: FTP connection times out on Port 21
- **Cause:** Windows Firewall blocking FTP port.
- **Fix:** On Server PowerShell (Admin), run `Enable-NetFirewallRule -DisplayGroup "FTP Server"`.

---

## Summary Checklist for Step 2

- [ ] Created `C:\Shares\CompanyData` and `C:\Shares\HR_Private` on Server
- [ ] Configured Share Permissions (`Everyone = Full Control`) & NTFS Permissions (`Domain Users = Modify`)
- [ ] Tested UNC access `\\server1.e6.local\CompanyData` from Client VM
- [ ] Successfully created `client_test.txt` from Client VM
- [ ] Mapped `Z:` drive on Client VM
- [ ] Verified `HR_Private` access is denied for non-admin users
- [ ] Installed FTP Server role in IIS
- [ ] Configured FTP Site `LabFTP` on `C:\inetpub\ftproot`
- [ ] Connected via `ftp server1.e6.local` from Client VM and ran `dir`
