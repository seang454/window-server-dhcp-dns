# Step 3: Web Server (IIS) Setup & Custom Website Guide

**Windows Server 2022 on VMware Workstation**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  
**Server Hostname: server1.e6.local**  

---

## 📖 Deep-Dive Concepts & Theory

### 1. What is a Web Server (IIS)?
Internet Information Services (IIS) is Microsoft's enterprise web server software role built into Windows Server. It allows companies to host websites, web applications, REST APIs, and intranet portals for employees and public internet users.

### 2. What is it used for?
- **Corporate Intranet Portals:** Internal employee news, HR portals, and department dashboards.
- **Public Company Websites:** E-commerce stores, corporate homepages, and customer portals.
- **Web Applications & APIs:** Hosting ASP.NET Core, PHP, Node.js, or HTML/CSS/JS applications.
- **Secure File Downloads:** Serving documents, images, and video assets via HTTP/HTTPS protocols.

### 3. Key Advantages of IIS:
- **Active Directory Integration:** Authenticate internal web users using domain accounts (`E6\Username`) via Windows Authentication (NTLM / Kerberos).
- **High Performance & Multi-Site Hosting:** Host multiple websites on a single IP using **Host Headers** and **Port Bindings**.
- **Security & SSL/TLS Management:** Native support for HTTPS encryption, SSL certificates, Request Filtering, and IP Restrictions.
- **Centralized Management:** Managed visually through **IIS Manager** (`inetmgr`).

### 4. Microsoft IIS vs. Nginx Web Server Comparison

| Feature | 🏢 Microsoft IIS (Internet Information Services) | ⚡ Nginx Web Server / Reverse Proxy |
|:---|:---|:---|
| **OS Native Environment** | Native to **Windows Server** (built-in role). | Native to **Linux** (Ubuntu, RedHat, Fedora). |
| **Active Directory Integration** | Native Single Sign-On (SSO), Kerberos, and AD Domain user authentication out-of-the-box. | Requires LDAP / RADIUS modules. |
| **Primary Enterprise Use Case** | Corporate intranet web portals, ASP.NET applications, IIS Web & FTP file servers. | High-concurrency Reverse Proxy, Load Balancer, SSL Termination, Microservices API Gateway. |
| **Installation Location** | Installed on **Windows Server VM (`pro-win-server`)**. | Installed on Linux VM or as Reverse Proxy in front of Web Servers. |

| Feature | 🌐 HTTP (Hypertext Transfer Protocol) | 🔒 HTTPS (HTTP Secure) |
|:---|:---|:---|
| **Port Number** | **TCP Port 80** | **TCP Port 443** |
| **Security** | Plain text (passwords and data visible to eavesdroppers). | **Encrypted (SSL/TLS)** (data protected by digital certificates). |
| **Browser Indicator** | Displays "Not Secure" ⚠️ warning banner. | Displays Secure Padlock 🔒 icon. |
| **Use Case** | Internal practice labs & development environments. | Enterprise production websites, online banking, e-commerce. |

---

## 📁 What is a Default Document?
When a user opens `http://server1.e6.local` without typing a specific filename in the URL, IIS looks inside `C:\inetpub\wwwroot\` for a **Default Document** to serve automatically.

IIS checks default filenames in this order:
1. `index.html` *(Custom HTML Homepage)*
2. `index.htm`
3. `Default.htm`
4. `Default.asp`
5. `iisstart.htm` *(Default Windows IIS Welcome Page)*

---

## 🚀 Step-by-Step Implementation Guide

### Step 1. Install Web Server (IIS) Role via Server Manager
*(Note: If you already installed IIS during Step 2 FTP setup, verify it is listed as **Installed**).*

1. Open **Server Manager** on `pro-win-server`.
2. Click **Manage → Add Roles and Features**.
3. Click **Next** until you reach **Server Roles**.
4. Check ✅ **Web Server (IIS)** (click **Add Features** on the popup).
5. Click **Next → Next → Install**.
6. Wait for installation to complete → click **Close**.

---

### Step 2. Create Custom Company Website Homepage (`index.html`)

1. Open **File Explorer** on `pro-win-server` → navigate to `C:\inetpub\wwwroot\`.
2. Right-click inside `C:\inetpub\wwwroot\` → select **New → Text Document**.
3. Rename the file to **`index.html`** *(confirm file extension change when prompted)*.
4. Right-click `index.html` → select **Open with → Notepad**.
5. Paste the following clean HTML corporate template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>E6 Enterprise Portal | server1.e6.local</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; text-align: center; }
        header { background-color: #003366; color: white; padding: 30px 0; }
        h1 { margin: 0; font-size: 2.2em; }
        p.subtitle { margin-top: 8px; font-size: 1.1em; color: #b0c4de; }
        .container { width: 80%; max-width: 800px; margin: 40px auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        .status-box { background-color: #e6fffa; border-left: 5px solid #38b2ac; padding: 15px; margin: 20px 0; text-align: left; }
        .grid { display: flex; justify-content: space-around; margin-top: 30px; }
        .card { background: #f8fafc; border: 1px solid #e2e8f0; padding: 20px; border-radius: 6px; width: 45%; }
        footer { margin-top: 50px; color: #718096; font-size: 0.9em; padding-bottom: 20px; }
    </style>
</head>
<body>
    <header>
        <h1>Welcome to E6 Enterprise Web Portal</h1>
        <p class="subtitle">Windows Server 2022 Infrastructure Lab</p>
    </header>

    <div class="container">
        <h2>Web Server Status: Active ✅</h2>
        <div class="status-box">
            <strong>Server Hostname:</strong> server1.e6.local<br>
            <strong>Server IP Address:</strong> 192.168.1.10<br>
            <strong>Domain Name:</strong> e6.local<br>
            <strong>Web Server Engine:</strong> Microsoft IIS / 10.0
        </div>

        <div class="grid">
            <div class="card">
                <h3>📁 File & FTP Access</h3>
                <p>Shared Data: <code>\\server1.e6.local\CompanyData</code></p>
                <p>FTP Server: <code>ftp://server1.e6.local</code></p>
            </div>
            <div class="card">
                <h3>🔒 Network Identity</h3>
                <p>DNS Server: <code>192.168.1.10</code></p>
                <p>DHCP Scope: <code>192.168.1.100 - .200</code></p>
            </div>
        </div>
    </div>

    <footer>
        &copy; 2026 E6 Enterprise Domain Infrastructure. All rights reserved.
    </footer>
</body>
</html>
```

6. Click **File → Save** and close Notepad.

---

### Step 3. Verify Default Document in IIS Manager

1. Open **Server Manager → Tools → Internet Information Services (IIS) Manager**.
2. Expand `WIN-J17IMHCEMA9` → expand **Sites** → click **Default Web Site**.
3. In the middle panel, double-click **Default Document**.
4. Verify that **`index.html`** is listed at the top of the list:
   - If not listed: Right-click blank space → click **Add...** → type `index.html` → click **OK**.
   - Select `index.html` → click **Move Up** in the right panel until it is at the very top.

---

### Step 4. Enable Web Server Firewall Rule (HTTP Port 80)

Open **Command Prompt as Administrator** on `pro-win-server` and run:

```cmd
netsh advfirewall firewall add rule name="Allow World Wide Web HTTP Port 80" dir=in action=allow protocol=TCP localport=80
```

---

### Step 5. Client Testing Flow for Web Server (`pro-win-client`)

```
                           WEB SERVER TESTING FLOW
                           
   [1. Open Client Browser] ──► [2. Type http://server1.e6.local] ──► [3. DNS Resolves IP]
                                                                              │
                                                                              ▼
   [5. Custom Website Displays! 🎉] ◄── [4. IIS Serves index.html] ◄───────┘
```

#### Test 1: Access Web Server via Domain Name
1. Open **Microsoft Edge** or **Internet Explorer** on `pro-win-client`.
2. In the top address bar, type:
   ```text
   http://server1.e6.local
   ```
3. Press **Enter**.
4. **Expected Result:** The blue corporate homepage titled **"Welcome to E6 Enterprise Web Portal"** displays instantly!

#### Test 2: Access Web Server via IP Address
1. In the browser address bar, type:
   ```text
   http://192.168.1.10
   ```
2. Press **Enter**.
3. **Expected Result:** The custom homepage displays cleanly!

---

## 🏠 Local vs. 🌐 Public Web Publishing Setup

### 🏠 1. Local Network Access (Internal Intranet)
- **URL:** `http://server1.e6.local` (Port 80)
- **Scope:** Accessible only by devices on `192.168.1.0/24` LAN.
- **Authentication:** Integrated Windows Authentication (AD Single Sign-On).

### 🌐 2. Public Access Simulation (VMware NAT Port Forwarding & ngrok)

#### Step 1: Configure VMware NAT Port Forwarding (Host 8080 ──► VM 80)
1. On your **Physical Laptop**, open **VMware Workstation**.
2. Click **Edit → Virtual Network Editor** → click **Change Settings** (Admin prompt).
3. Select **VMnet8 (NAT)** → click **NAT Settings...**
4. Click **Add...** and fill in:
   - **Host Port:** `8080`
   - **Type:** `TCP`
   - **Virtual machine IP address:** `192.168.1.10`
   - **Virtual machine port:** `80`
   - **Description:** `Public Web IIS`
5. Click **OK → Apply → OK**.

#### Step 2: Open Port 8080 on Physical Laptop Firewall
Open Command Prompt as Administrator on your physical laptop (`C:\Users\M>`) and run:
```cmd
netsh advfirewall firewall add rule name="Allow VMware Public Web Port 8080" dir=in action=allow protocol=TCP localport=8080
```

#### Step 3: Launch ngrok HTTP Tunnel on Physical Laptop
Open Command Prompt on your physical laptop (`C:\Users\M>`) and run:
```cmd
ngrok http 127.0.0.1:8080
```

#### Step 4: Access Website from Any Device Worldwide!
Anyone on any mobile phone, Fedora laptop, or remote computer opens the generated link:
```text
https://xxxx.ngrok-free.app
```
🎉 **Result:** The custom **E6 Enterprise Web Portal** homepage displays on any device anywhere in the world!

---

## 🛠️ Troubleshooting Guide for Step 3

### 1. Error: Default blue IIS Welcome Page (`iisstart.htm`) displays instead of custom website
- **Cause:** `index.html` does not exist in `C:\inetpub\wwwroot\`, or it was saved with a hidden `.txt` extension (`index.html.txt`). IIS skips missing files and serves `iisstart.htm`.
- **Fix:** 
  1. Open File Explorer on Server → go to `C:\inetpub\wwwroot\`.
  2. Click **View → Show → File name extensions** (ensure `.txt` extensions are visible).
  3. Rename `index.html.txt` to **`index.html`**.
  4. In browser, press **`Ctrl + F5`** (Hard Refresh) to reload!

### 2. Error: "HTTP 404 - File Not Found"
- **Cause:** `index.html` is missing or saved with wrong extension (`index.html.txt`).
- **Fix:** In `C:\inetpub\wwwroot\`, ensure file extensions are shown (*File Explorer → View → Show → File name extensions*). Rename to `index.html`.

### 2. Error: "This page can't be displayed" / Connection Timeout
- **Cause:** Windows Firewall blocking Port 80 on server.
- **Fix:** Run `netsh advfirewall firewall add rule name="Allow World Wide Web HTTP Port 80" dir=in action=allow protocol=TCP localport=80` on server.

### 3. Error: "HTTP 403 - Forbidden"
- **Cause:** No Default Document defined or directory browsing disabled.
- **Fix:** In IIS Manager → click Default Web Site → double-click Default Document → add `index.html` to top.

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
