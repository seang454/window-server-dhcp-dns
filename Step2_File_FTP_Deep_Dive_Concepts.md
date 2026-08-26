# 🗄️ Step 2: File Server & FTP Server - Deep-Dive Concept Guide

## 1. What is it? 🔍

### 📁 File Server (SMB)
- **Full Name Breakdown:** Server Message Block (SMB) Protocol.
- **Definition:** A centralized server that shares folders and files across a network. Windows clients access these shared resources using UNC (Universal Naming Convention) paths, like `\\192.168.1.10\software` or `\\WIN-J17IMHCEMA9\software`.
- **Simple Analogy:** 🏢 A massive, secure, shared company filing cabinet located in the center of the office. Everyone can access their permitted drawers from their own desks without having to walk over.

### 🌐 FTP Server
- **Full Name Breakdown:** File Transfer Protocol.
- **Definition:** A dedicated service for transferring files over a network or the Internet, typically using TCP ports 20 (data) and 21 (control).
- **Simple Analogy:** 🚚 A delivery dock or loading bay. It's specifically designed for loading (uploading) and unloading (downloading) packages (files) efficiently, even across different operating systems.

---

## 2. Objective & Purpose 🎯

| Service | Objective | Purpose / Description |
| :--- | :--- | :--- |
| **File Server** | Centralized Document Storage | Keep all important company files in one backed-up location instead of scattered on local C: drives. |
| **File Server** | Access Control & Security | Use NTFS Permissions to tightly control who can Read, Write, or Modify specific files (e.g., only HR can see HR files). |
| **File Server** | Resource Management | Utilize Quota Management to prevent users like `s.pengseang` from using up all server storage, and Shadow Copies for easy file recovery. |
| **FTP Server** | Cross-Platform Transfers | Provide a standard way to exchange files between Windows, Linux, Mac, and web servers. |
| **FTP Server** | Bulk Data Exchange | Efficiently handle large file uploads and downloads (e.g., website files, firmware, huge datasets). |

---

## 3. What Are They Used For? 🛠️

### 📁 File Server Real-World Use Cases:
1. **Departmental Shared Folders:** The IT team at `e6.local` accesses `\\WIN-J17IMHCEMA9\IT_Share` to collaborate on scripts, while HR has a separate, isolated share for employee records.
2. **Software Distribution:** IT stores all installation files in `\\192.168.1.10\software`. Instead of using USBs, `CLIENT` computers simply run the installer directly from the network path.
3. **User Home Folders:** `s.pengseang` logs into any PC in the domain and automatically gets a mapped `Z:` drive pointing to their personal, private folder on the File Server.

### 🌐 FTP Server Real-World Use Cases:
1. **Web Developer Uploads:** A web developer uses an FTP client (like FileZilla) to upload new HTML/PHP files to the IIS FTP site running on `192.168.1.10`.
2. **Firmware Updates:** Network devices (routers/switches) automatically connect to the FTP server to download their latest OS images.
3. **B2B Data Exchange:** Sharing huge daily database dumps with an external partner who runs a Linux environment (since FTP is universally supported).

---

## 4. Advantages 🌟

| Service | Advantage | Explanation |
| :--- | :--- | :--- |
| **File Server** | Single Source of Truth | No more "Report_v2_Final_FINAL.docx". Everyone edits the exact same file on the server. |
| **File Server** | Seamless Integration | Built natively into Windows Explorer. To the user `s.pengseang`, a mapped network drive looks just like a local hard drive. |
| **File Server** | Advanced Storage Features | Supports DFS (Distributed File System) to group multiple servers under one namespace, and FSRM (File Server Resource Manager) for quotas and file screens. |
| **FTP Server** | Universal Compatibility | Every OS (Windows, Linux, macOS) and virtually every programming language supports FTP out of the box. |
| **FTP Server** | Dedicated Transfer Logic | Specifically built for transferring data, handling interrupted downloads, and managing transfer queues better than simple file sharing. |

---

## 5. What Happens WITH vs WITHOUT 💥

### 📁 File Server: The Chaos of No Central Storage

**WITHOUT File Server (The Nightmare):**
```text
[s.pengseang's PC]       [Admin's PC]           [Boss's PC]
     📄 v1                  📄 v2 (edited)         📄 v3 (lost)
       \                      /                      /
        \___📧 Emails file___/                      /
             💾 USB Drive -------------------------/

Disaster: Which version is correct? What if a PC crashes? No backups!
```

**WITH File Server (The Clean Solution):**
```text
                   [ WIN-J17IMHCEMA9 (192.168.1.10) ]
                   [        Central Storage         ]
                   [   📄 Project_Plan_v1.docx      ]
                          /         |         \
                         /          |          \
                 (Mapped Z:)    (Mapped Z:)   (Mapped Z:)
                 [s.pengseang]  [  Admin  ]   [   Boss  ]

Solution: Everyone edits the SAME file. Server is backed up daily!
```

### 🌐 FTP Server: Transferring Large/Cross-Platform Files

**WITHOUT FTP Server:**
```text
[Web Developer (Mac)]                       [Windows Server (IIS)]
"How do I upload these 500 web files?"
"SMB doesn't work well over the Internet!"
"Can I email a 2GB zip file?" ----------> ❌ ERROR: Attachment too large
```

**WITH FTP Server:**
```text
[Web Developer (Mac)] ============= (Internet / WAN) =============> [FTP Server on 192.168.1.10]
   (FileZilla Client)                                                   (IIS FTP Service)
           |                                                                    |
           +---------------------> TCP Port 21 (Login) ------------------------>+
           +---------------------> TCP Port 20 (Transfer 500 files) ----------->+
                                 ✅ Fast, Standardized, Resumable
```

---

## 6. How It Works Internally ⚙️

### 📁 How File Server (SMB) Works
1. **UNC Path Resolution:** When `s.pengseang` types `\\WIN-J17IMHCEMA9\software` into Explorer, Windows asks DNS to resolve `WIN-J17IMHCEMA9` to `192.168.1.10`.
2. **Connection:** The client establishes a TCP connection to the server on **Port 445** (SMB over TCP/IP).
3. **Authentication & Negotiation:** The client and server silently negotiate the SMB dialect (e.g., SMB 3.1.1) and authenticate using Kerberos/NTLM (via Active Directory `e6.local`).
4. **Permissions Check (Double Barrier):**
   - **Share Permissions:** Determines if the user can enter the "front door" of the shared folder over the network.
   - **NTFS Permissions:** Determines what the user can do once inside (Read, Write, Delete specific files).
   - *Rule:* The most restrictive permission between the two wins!

```text
[ Client ] ---> TCP Port 445 ---> [ WIN-J17IMHCEMA9 ]
                                     |
                                     |--> Share Permission: Everyone (Full Control)
                                     |--> NTFS Permission: s.pengseang (Read Only)
                                     |
                                     +--> Result: User can only READ files.
```

### 🌐 How FTP Works (Active vs. Passive)
FTP is unique because it uses **two** channels:
- **Control Channel (Port 21):** Used for sending commands (`USER`, `PASS`, `LIST`, `RETR`, `STOR`).
- **Data Channel (Port 20 or High Ports):** Used to actually transfer the file contents or folder listings.

**Active Mode (Server initiates data connection - Bad for Client Firewalls):**
1. Client connects to Server Port 21 (Control).
2. Client says "I am listening on Port 5000 for data."
3. Server connects from its Port 20 to Client's Port 5000 to send data. (Client's firewall usually blocks this incoming connection!)

**Passive Mode (Client initiates both connections - Good for Firewalls):**
1. Client connects to Server Port 21 (Control).
2. Client says "PASV" (Passive Mode).
3. Server replies "I am listening on Port 50000 for data."
4. Client connects from its own high port to Server's Port 50000 to transfer data.

```text
PASSIVE MODE FLOW:
[ Client: pro-win-client ]                           [ Server: 192.168.1.10 ]
        | --- 1. TCP 21: USER abc, PASS abc@123 ---> | (Control Channel)
        | <--- 2. 230 User logged in --------------- |
        | --- 3. TCP 21: PASV ---------------------> |
        | <--- 4. 227 Entering Passive Mode (P:50000)|
        | --- 5. TCP High Port to Server P:50000 --> | (Data Channel Created)
        | --- 6. TCP 21: RETR file.zip ------------> | (Command to download)
        | <--- 7. TCP 50000: [File Data Streams] --- | (Actual File Transfer)
```

### ⚔️ SMB vs FTP Comparison
| Feature | SMB (File Server) | FTP |
| :--- | :--- | :--- |
| **Primary Use** | Local Network (LAN) collaboration | WAN/Internet file transfers |
| **Port(s)** | TCP 445 | TCP 20, 21 |
| **File Editing** | Edit files directly on the server | Must download, edit locally, then upload |
| **Security** | High (Integrated with Active Directory) | Low by default (Clear text). Needs FTPS for security. |

---

## 7. Full Abbreviation & Terminology Glossary 📚

| Term | Full Name | Definition |
| :--- | :--- | :--- |
| **SMB** | Server Message Block | The standard Windows protocol for sharing files, printers, and serial ports over a network. |
| **CIFS** | Common Internet File System | An old, obsolete dialect of SMB. Often used interchangeably with SMB, but technically outdated. |
| **FTP** | File Transfer Protocol | Standard network protocol used for the transfer of computer files between a client and server. |
| **FTPS** | FTP Secure | FTP wrapped in TLS/SSL encryption to secure the control and data channels. |
| **SFTP** | SSH File Transfer Protocol | Completely different protocol from FTP. File transfer over Secure Shell (SSH). Common in Linux. |
| **UNC** | Universal Naming Convention | The standard format for specifying the location of resources on a local area network (e.g., `\\ServerName\ShareName`). |
| **NTFS** | New Technology File System | The default file system for Windows, providing local file-level security and permissions. |
| **ACL** | Access Control List | A list of permissions attached to an object (like a file or folder) dictating who can access it and how. |
| **DFS** | Distributed File System | A Windows feature that groups shared folders on different servers into one logical namespace. |
| **TCP** | Transmission Control Protocol | The underlying reliable delivery protocol used by both SMB and FTP. |
| **Share Permissions** | - | Network-level permissions acting as the "front door" to a shared folder. |
| **NTFS Permissions** | - | Local file-system permissions acting as the "inner doors" for specific files/folders. |
| **Quota** | - | A limit placed on the amount of disk space a user (like `s.pengseang`) can consume. |
| **Shadow Copy** | Volume Snapshot Service (VSS) | A technology that takes automatic backup snapshots of files, allowing users to restore previous versions. |
| **Active Mode** | - | FTP mode where the server initiates the data connection back to the client. |
| **Passive Mode** | - | FTP mode where the client initiates both the control and data connections to the server. |
