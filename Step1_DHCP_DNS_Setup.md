# Step 1: DNS Server + DHCP Server Setup Guide

**Windows Server 2022 on VMware Workstation**
**Domain: e6.local**
**Network: 192.168.1.0/24**

---

## Network Info

```
VMware NAT Gateway:   192.168.1.1
Server IP:            192.168.1.10
Subnet Mask:          255.255.255.0
Domain:               e6.local
DHCP Range:           192.168.1.100 - 192.168.1.200
```

---

## Prerequisites

### 1. VMware Network Setup (VMnet8)

1. Open **VMware Workstation**
2. **Edit → Virtual Network Editor**
3. Click **Change Settings** (admin permission)
4. Click **VMnet8 (NAT)**
5. Set:
   ```
   Subnet IP:   192.168.1.0
   Subnet Mask: 255.255.255.0
   ```
6. Click **NAT Settings** → Set Gateway IP to `192.168.1.1`
7. Uncheck "Use local DHCP service to distribute IP address to VMs"
8. Click **OK → Apply → OK**

### 2. Set a Static IP Address on Your Server

1. Open **Settings → Network & Internet → Ethernet**
   (or right-click the network icon in the taskbar → **Open Network & Internet settings**)
2. Click **Change adapter options**
3. Right-click **Ethernet0** → **Properties**
4. Select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties**
5. Select **Use the following IP address** and enter:

```
IP address:        192.168.1.10
Subnet mask:       255.255.255.0
Default gateway:   192.168.1.1
```

6. Select **Use the following DNS server addresses** and enter:

```
Preferred DNS:     127.0.0.1
Alternate DNS:     8.8.8.8
```

> **NOTE:**
> - `192.168.1.10` is the static IP of your server.
> - `192.168.1.1` is the VMware NAT gateway (your virtual router).
> - `127.0.0.1` means the server will use itself as the DNS server.
> - `8.8.8.8` is Google's public DNS as a backup.

7. Click **OK → Close**

### 3. Verify Network

Open PowerShell and run:

```powershell
ipconfig
ping 8.8.8.8
ping google.com
```

All should reply successfully. If `ping google.com` fails but `ping 8.8.8.8` works,
temporarily change DNS to 8.8.8.8:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 8.8.8.8, 8.8.4.4
```

---

## Part A: Install & Configure DNS Server

### A1. Install the DNS Server Role

> **NOTE:** If you already installed Active Directory (e6.local), DNS Server
> may already be installed. Check Server Manager - if DNS Server shows as
> "Installed", skip to A2.

1. Open **Server Manager**
2. Click **Manage → Add Roles and Features**
3. Click **Next** until you reach **Server Roles**
4. Check **DNS Server**
5. A popup will ask to add required features → Click **Add Features**
6. Click **Next → Next → Install**
7. Wait for installation to complete → Click **Close**

### A2. Check Existing DNS Zones

Since you installed Active Directory with domain `e6.local`, the DNS zone
may already exist:

1. Open **Server Manager → Tools → DNS**
2. Expand your server name in the left panel
3. Expand **Forward Lookup Zones**

**If you see `e6.local` already listed** → Skip to A3 (Add DNS Records)
**If you do NOT see `e6.local`** → Create it manually:

#### Create a Forward Lookup Zone

1. Right-click **Forward Lookup Zones → New Zone...**
2. Click **Next**
3. Select **Primary zone** → **Next**
4. Zone name: `e6.local` → **Next**
5. Select **Create a new file with this file name** → **Next**
6. Select **Do not allow dynamic updates** → **Next**
7. Click **Finish**

### A3. Add DNS Records (A Records)

1. Right-click your zone `e6.local` → **New Host (A or AAAA)...**
2. Name: `server1`
3. IP address: `192.168.1.10`
4. Click **Add Host → OK → Done**

Now `server1.e6.local` will resolve to `192.168.1.10`.

> **TIP:** You can add more records later, for example:
> - `web` → `192.168.1.10` (for Web Server)
> - `ftp` → `192.168.1.10` (for FTP Server)
> - `mail` → `192.168.1.10` (for Mail Server)

### A4. Create a Reverse Lookup Zone (IP → Domain Name)

1. Right-click **Reverse Lookup Zones → New Zone...**
2. Click **Next**
3. Select **Primary zone** → **Next**
4. Select **IPv4 Reverse Lookup Zone** → **Next**
5. Network ID: `192.168.1` → **Next**
6. Select **Create a new file** → **Next**
7. Select **Do not allow dynamic updates** → **Next**
8. Click **Finish**

### A5. Set DNS Forwarder (So google.com works)

1. In DNS Manager, right-click your server name → **Properties**
2. Click the **Forwarders** tab
3. Click **Edit...**
4. Type `8.8.8.8` → Press **Enter**
5. Type `8.8.4.4` → Press **Enter**
6. Click **OK → OK**

### A6. Change DNS Setting Back to Yourself

If you changed DNS to 8.8.8.8 earlier, change it back now:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1, 8.8.8.8
```

### A7. Test DNS

Open PowerShell and run:

```powershell
# Test forward lookup (name → IP)
nslookup server1.e6.local

# Expected result:
# Name:    server1.e6.local
# Address:  192.168.1.10

# Test reverse lookup (IP → name)
nslookup 192.168.1.10

# Test external DNS still works (via forwarder)
nslookup google.com
```

> **TIP:** If `nslookup google.com` fails:
> 1. Check your Forwarder is set to `8.8.8.8`
> 2. Make sure `ping 8.8.8.8` works (network connectivity)

**DNS Server is now working!**

---

## Part B: Install & Configure DHCP Server

### B1. Install the DHCP Server Role

1. Open **Server Manager**
2. Click **Manage → Add Roles and Features**
3. Click **Next** until you reach **Server Roles**
4. Check **DHCP Server**
5. A popup will ask to add required features → Click **Add Features**
6. Click **Next → Next → Install**
7. Wait for installation to complete → Click **Close**

### B2. Complete DHCP Post-Install Configuration

After installing, you will see a yellow warning flag in Server Manager.

1. Click the **yellow flag** → Click **Complete DHCP configuration**
2. Click **Next → Commit → Close**

This authorizes the DHCP server in your network.

### B3. Configure DHCP Scope

A "Scope" defines the range of IP addresses the DHCP server will give out.

1. Open **Server Manager → Tools → DHCP**
2. Expand your server name → Expand **IPv4**
3. Right-click **IPv4 → New Scope...**
4. Click **Next**
5. **Scope Name:** `Lab Network` → **Next**
6. **IP Address Range:**

```
Start IP address:  192.168.1.100
End IP address:    192.168.1.200
Subnet mask:       255.255.255.0
```

> **NOTE:**
> This means devices will automatically get an IP between 192.168.1.100
> and 192.168.1.200. Your server at 192.168.1.10 is outside this range,
> so it won't conflict.

7. Click **Next**
8. **Exclusions:** Skip (click **Next**)
9. **Lease Duration:** Leave at 8 days (default) → **Next**
10. Select **Yes, I want to configure these options now** → **Next**

### B4. Configure DHCP Options

#### Default Gateway (Router):
1. Type: `192.168.1.1`
2. Click **Add** → **Next**

#### DNS Server:
1. Parent domain: `e6.local`
2. In the IP address box, type: `192.168.1.10`
3. Click **Add** → **Next**

#### WINS Servers:
1. Skip (click **Next**)

#### Activate Scope:
1. Select **Yes, I want to activate this scope now** → **Next → Finish**

**DHCP Server is now working!**

---

## Part C: Test with Client VM (pro-win-client)

### C1. Prepare Client VM

1. Open **pro-win-client** VM in VMware
2. Make sure the network adapter is set to **NAT (VMnet8)**
3. Make sure network settings are set to **Obtain an IP address automatically** (DHCP)

### C2. Get IP from DHCP

Open **Command Prompt** on the client and run:

```cmd
ipconfig /release
ipconfig /renew
ipconfig /all
```

**Expected result:**
```
IPv4 Address:      192.168.1.1xx    (an IP from your DHCP range, e.g. 192.168.1.100)
Subnet Mask:       255.255.255.0
Default Gateway:   192.168.1.1
DNS Servers:       192.168.1.10
```

### C3. Test DNS from Client

```cmd
nslookup server1.e6.local

ping server1.e6.local

ping google.com
```

**Expected results:**
```
server1.e6.local → 192.168.1.10
ping server1.e6.local → Reply from 192.168.1.10
ping google.com → Reply from xxx.xxx.xxx.xxx
```

### C4. Verify on Server

On your **Windows Server**, verify the DHCP lease:

1. Open **DHCP Manager** (Server Manager → Tools → DHCP)
2. Expand your scope → Click **Address Leases**
3. You should see the client's IP address and MAC address listed

**Both DNS and DHCP are working! Client is connected!**

---

## Summary

| Service | Status | What It Does |
|:--------|:-------|:------------|
| **DNS Server** | Installed | Resolves `server1.e6.local` → `192.168.1.10` |
| **DHCP Server** | Installed | Assigns IPs from `192.168.1.100` to `192.168.1.200` |

## Network Diagram

```
                    INTERNET
                       |
             +---------+----------+
             |  VMware NAT Router |
             |  192.168.1.1       |
             |  (Default Gateway) |
             +---------+----------+
                       |
    ===================+====================
    |        Network: 192.168.1.0/24       |
    ===================+====================
              |                    |
    +---------+---------+  +------+--------+
    |  Windows Server   |  |  Client VM    |
    |  192.168.1.10     |  |  IP: Auto     |
    |  Domain: e6.local |  |  (from DHCP)  |
    |                   |  |  192.168.1.1xx|
    |  +-----+ +-----+ |  |               |
    |  | DNS | |DHCP | |  |               |
    |  +-----+ +-----+ |  |               |
    +-------------------+  +---------------+
```

## Next Step

Once DNS and DHCP are working, we will move to **Step 2: File Server + FTP Server**.
