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

### IP Address Plan

```
Device                    IP Address              Default Gateway
----------------------------------------------------------------------
VMware NAT Router         192.168.1.1             (it IS the gateway)
Server 1 (this one)       192.168.1.10            192.168.1.1
Server 2 (later)          192.168.1.11            192.168.1.1
DHCP Range (for clients)  192.168.1.100 - .200    192.168.1.1
Reserved for future       192.168.1.3 - .9        (available)
Reserved for future       192.168.1.12 - .99      (available)
```

### Key Concepts

**What is Subnet IP?**
- The Subnet IP is the name of your network (like a street name)
- `192.168.1.0` = "1st Street" — all devices will be `192.168.1.x`
- The `.0` at the end means "the whole network", not a specific device

**What is Default Gateway?**
- The gateway is your router — the only way to reach the internet
- VMware creates a virtual NAT router automatically
- You set the gateway IP in VMware's **Virtual Network Editor → VMnet8 → NAT Settings**
- ALL devices on the network must point to the SAME gateway

**What is `8.8.8.8` and `8.8.4.4`?**
- They are **Google's free public DNS servers** (real servers on the internet)
- `8.8.8.8` = Google DNS Primary (main server)
- `8.8.4.4` = Google DNS Backup (if 8.8.8.8 is down, this one takes over)
- Used as a forwarder: when your DNS doesn't know an answer, it asks Google
- Why two? If one goes down, the other keeps working — so you always have DNS

**Other Free Public DNS Servers (alternatives to Google):**

| Provider | Primary | Backup |
|:---------|:--------|:-------|
| **Google** | `8.8.8.8` | `8.8.4.4` |
| Cloudflare | `1.1.1.1` | `1.0.0.1` |
| OpenDNS | `208.67.222.222` | `208.67.220.220` |

> Google's `8.8.8.8` is the most popular and easy to remember, so we use it.

**What is `0.0.0.0`?**
- NOT a real server — it means "nothing" or "no address"
- Do NOT use this as a DNS server or gateway

**What is `127.0.0.1`?**
- "Localhost" — means "myself" / "this computer"
- When your server uses `127.0.0.1` as DNS, it asks itself for DNS answers

### Local vs. Public Network Scope for DHCP & DNS

| Feature | Local Private Network (`192.168.1.0/24`) | Public Network / Internet |
|:---|:---|:---|
| **DHCP Server** | **100% Local.** Assigns private IPs (`.100 - .200`) to local clients on VMnet8. | Does NOT touch or affect public internet. |
| **DNS Server (Internal)** | **100% Local.** Resolves `server1.e6.local` → `192.168.1.10` locally. | Local queries stay inside your private network. |
| **DNS Forwarder (`8.8.8.8`)** | Receives unknown public queries from local clients... | Forwards public queries (like `google.com`) to Google's public DNS servers. |

> **Key Takeaway:** Your DHCP and DNS servers operate **locally on your private network** (`192.168.1.0/24`). They do NOT require a public IP address or internet connection to function for all your local lab services!

#### 1. What does `/24` mean?
- Subnet Mask `255.255.255.0` in CIDR notation is written as **/24**.
- In binary: `11111111.11111111.11111111.00000000` (8 + 8 + 8 = **24 ones**).
- The 24 ones mean the first 3 numbers (`192.168.1`) identify the **Network**.
- The last 8 zeros allow \(2^8 = 256\) total IP addresses (`192.168.1.0` to `192.168.1.255`).

#### 2. Usable IPs in a `/24` Network:
- `192.168.1.0` = Network Address (Reserved - cannot be assigned to any device)
- `192.168.1.255` = Broadcast Address (Reserved - used to broadcast to all devices)
- **Usable IPs:** `192.168.1.1` to `192.168.1.254` (Total: **254 addresses**)

#### 3. How We Allocated the 254 Usable IPs:
| IP Range | Quantity | Assigned To | Why? |
|:---|:---|:---|:---|
| `192.168.1.1` | 1 IP | VMware NAT Gateway | Router IP (internet exit door) |
| `192.168.1.2 - 1.9` | 8 IPs | Reserved for Network Infrastructure | Routers, Switches, Firewalls |
| `192.168.1.10` | 1 IP | Windows Server 1 | Primary Domain Controller / DNS (Static) |
| `192.168.1.11` | 1 IP | Windows Server 2 | Secondary Server / Failover Node (Static) |
| `192.168.1.12 - 1.99` | 88 IPs | Reserved for Servers / Printers | Future servers needing static IPs |
| **`192.168.1.100 - 1.200`** | **101 IPs** | **DHCP Pool (Clients)** | **Auto-assigned to Client VMs / devices** |
| `192.168.1.201 - 1.254` | 54 IPs | Reserved for Management / VPN | Static management pool |

> **Can you change 100 - 200?** YES! You can use `50 - 150` or `100 - 250`. Using `100 - 200` is simply a **best practice** so static server IPs (`.10`, `.11`) never conflict with dynamic client IPs (`.100+`).

### 1. VMware Network Setup (VMnet8)

**Why VMnet8?** Because your VM uses NAT mode, and NAT = VMnet8 in VMware.
- VMnet0 = Bridged (connects to real router, no settings to configure)
- VMnet1 = Host-Only (no internet)
- VMnet8 = NAT (VMware creates a virtual router, you configure it here)

**Why uncheck VMware DHCP?** Because you are installing your OWN DHCP server
on Windows Server. If VMware's DHCP is also running, they will fight and
cause IP conflicts.

#### Steps:

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
7. **UNCHECK** "Use local DHCP service to distribute IP address to VMs"
8. Click **OK → Apply → OK**

### 2. Set a Static IP Address on Your Server

**Why static IP?** A DHCP server cannot use DHCP itself. It must have a
fixed (static) IP address so clients always know where to find it.

1. Open **Settings → Network & Internet → Ethernet**
   (or right-click the network icon in the taskbar → **Open Network & Internet settings**)
2. Click **Change adapter options**
3. Right-click **Ethernet0** → **Properties**

   > **NOTE:** "Ethernet0" is the name of your VM's network card (inside the VM).
   > It is plugged into VMnet8 (the virtual network). They are different things:
   > - VMnet8 = the virtual network (like a cable/switch)
   > - Ethernet0 = the VM's network card (plugged into VMnet8)

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
> - `192.168.1.10` is the static IP of your server. You can pick any number
>   (3-254) as long as it's not `.1` (gateway) or in the DHCP range (.100-.200).
> - `192.168.1.1` is the VMware NAT gateway (your virtual router). This MUST
>   match what you set in VMnet8 NAT Settings. You cannot choose any random IP.
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

- If `ping 8.8.8.8` works but `ping google.com` fails → DNS problem (not network).
  Temporarily change DNS to 8.8.8.8:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 8.8.8.8, 8.8.4.4
```

- If Windows shows "No Internet" icon but ping works → Ignore the icon. The ping
  result is the truth. The icon sometimes takes time to update.

- If `ipconfig /release` gives an error → This is NORMAL for static IP.
  That command only works with DHCP. Your static IP is fine.

---

## Part A: Install & Configure DNS Server

### DNS Server Deep-Dive

#### 1. What is a DNS Server?
DNS (Domain Name System) is the **phonebook of the computer network**. Computers communicate using numerical IP addresses (like `192.168.1.10`), but humans remember names (like `server1.e6.local` or `google.com`). A DNS Server translates human-friendly domain names into computer-friendly IP addresses.

#### 2. What is it used for?
- **Internal Domain Name Resolution:** Translates internal company names (`server1.e6.local`, `mail.e6.local`) to local server IPs.
- **Active Directory Integration:** Locates Domain Controllers, Kerberos authentication services, and LDAP directory services for domain-joined client computers.
- **Internet Name Resolution:** Uses DNS Forwarders (`8.8.8.8`) to resolve public domain names (`google.com`, `microsoft.com`) for internal network users.

#### 3. Key Advantages & Benefits:
- ⚡ **User Convenience:** Users don't need to memorize complex numerical IP addresses.
- 🔒 **Active Directory Necessity:** Active Directory cannot function without DNS; client computers use DNS to locate authentication servers.
- 🛠️ **Dynamic Updates:** Automatically updates DNS records when new computers join the domain or change IP addresses via DHCP.
- 🌐 **Centralized Control:** Allows administrators to manage all internal domain names and redirect network traffic from a single server console.

```
server1.e6.local  →  192.168.1.10  (your DNS answers this)
google.com        →  142.250.x.x   (Google's DNS answers this via forwarder)
```

### A1. Install the DNS Server Role

> **NOTE:** If you already installed Active Directory (e6.local), DNS Server
> is already installed automatically. Check Server Manager → Add Roles and
> Features → if DNS Server shows as "Installed", skip to A2.

1. Open **Server Manager**
2. Click **Manage → Add Roles and Features**
3. Click **Next** until you reach **Server Roles**
4. Check **DNS Server**
5. A popup will ask to add required features → Click **Add Features**
6. Click **Next → Next → Install**
7. Wait for installation to complete → Click **Close**

### A2. Check Existing DNS Zones

Since you installed Active Directory with domain `e6.local`, the DNS zone
was created automatically. Open DNS Manager to verify:

1. Open **Server Manager → Tools → DNS**
2. Expand your server name in the left panel
3. Expand **Forward Lookup Zones**

**If you see `e6.local` already listed** → Skip to A3 (Add DNS Records)

> **Understanding the DNS folder structure:**
> ```
> Forward Lookup Zones
> ├── _msdcs.e6.local     ← Active Directory internal records (DO NOT TOUCH)
> └── e6.local            ← YOUR main zone (add records here)
>     ├── _msdcs           ← AD service records (automatic, don't touch)
>     ├── _sites           ← AD site info (automatic, don't touch)
>     ├── _tcp             ← TCP service records (automatic, don't touch)
>     ├── _udp             ← UDP service records (automatic, don't touch)
>     ├── DomainDnsZones   ← AD replication (automatic, don't touch)
>     └── ForestDnsZones   ← AD forest replication (automatic, don't touch)
>
> Reverse Lookup Zones     ← Empty — YOU need to create a zone here
> Trust Points             ← Not needed now
> Conditional Forwarders   ← Not needed now
> ```
> All the folders inside `e6.local` starting with `_` were created by
> Active Directory. Do NOT delete or modify them.

**If you do NOT see `e6.local`** → Create it manually:

#### Create a Forward Lookup Zone

1. Right-click **Forward Lookup Zones → New Zone...**
2. Click **Next**
3. Select **Primary zone** → Check **Store the zone in Active Directory** → **Next**
4. Select **To all DNS servers running on domain controllers in this domain** → **Next**
5. Zone name: `e6.local` → **Next**
6. Select **Allow only secure dynamic updates** → **Next**
7. Click **Finish**

### A3. Add DNS Records (A Records)

1. Right-click your zone `e6.local` → **New Host (A or AAAA)...**
2. Name: `server1`
3. IP address: `192.168.1.10`
4. Check **Create associated pointer (PTR) record** (if available)
5. Click **Add Host**

> **If you see a PTR warning:** "The associated pointer (PTR) record cannot
> be created because the referenced reverse lookup zone cannot be found."
> This is NORMAL — click **OK**. The PTR record will work after you create
> the Reverse Lookup Zone in the next step.

6. Click **OK → Done**

Now `server1.e6.local` will resolve to `192.168.1.10`.

> **TIP:** You can add more records later, for example:
> - `web` → `192.168.1.10` (for Web Server)
> - `ftp` → `192.168.1.10` (for FTP Server)
> - `mail` → `192.168.1.10` (for Mail Server)

### A4. Create a Reverse Lookup Zone (IP → Domain Name)

**What is a Reverse Lookup Zone?**
- Forward zone: name → IP (`server1.e6.local` → `192.168.1.10`)
- Reverse zone: IP → name (`192.168.1.10` → `server1.e6.local`)
- You need BOTH for Active Directory health, DHCP auto-registration,
  security logs, and email to work properly.

**Why Network ID `192.168.1`?**
- Your devices are on the `192.168.1.x` network
- The Network ID tells DNS: "I manage reverse lookups for ALL devices on 192.168.1.x"
- It must match your network's first 3 numbers

#### Steps:

1. Right-click **Reverse Lookup Zones → New Zone...**
2. Click **Next**
3. Select **Primary zone** → Check **Store the zone in Active Directory** → **Next**
4. Select **To all DNS servers running on domain controllers in this domain: e6.local** → **Next**

   > **Why this option?**
   > - "In this domain" = copies DNS data only within `e6.local`
   > - Since you have one domain and one server, this is the simplest choice
   > - If you add Server 2 later, DNS will automatically replicate to it

5. Select **IPv4 Reverse Lookup Zone** → **Next**
6. Network ID: `192.168.1` → **Next**
7. Select **Allow only secure dynamic updates (recommended for Active Directory)** → **Next**

   > **What are Dynamic Updates?**
   > - "Secure dynamic updates" = when a client gets an IP from DHCP, it
   >   automatically registers its name in DNS (only domain-joined computers)
   > - "Nonsecure and secure" = any device can register (security risk)
   > - "Do not allow" = you must add all records manually

8. Click **Finish**

### A5. Add PTR Record in Reverse Lookup Zone

The reverse zone is now created but it's **empty**. You must manually add a
PTR record for your server. (DHCP clients will auto-register later, but
servers with static IPs must be added manually.)

> **Why is it not auto-configured?**
> - Creating the zone = buying an empty notebook
> - Adding the PTR record = writing a contact in the notebook
> - The zone doesn't know which devices exist — YOU tell it by adding records
> - Only static IP devices (servers) need manual PTR records
> - DHCP clients will auto-register because you chose "secure dynamic updates"

1. Expand **Reverse Lookup Zones**
2. Click on **`1.168.192.in-addr.arpa`**
3. Right-click in the right panel → **New Pointer (PTR)...**
4. Host IP Address: add `10` after `192.168.1.` → so it shows `192.168.1.10`
5. Host name: type `server1.e6.local`
6. Click **OK**

### A6. Set DNS Forwarder (So google.com works)

**Why do you need a forwarder?**
Your DNS server knows about `e6.local` (your private domain), but it does
NOT know about `google.com` or any public website. The forwarder tells your
DNS: "If you don't know the answer, ask Google's DNS (8.8.8.8)."

```
Client asks: "What is server1.e6.local?"
  → Your DNS knows this → answers directly

Client asks: "What is google.com?"
  → Your DNS doesn't know → forwards to 8.8.8.8 → gets answer → returns to client
```

#### Steps:

1. In DNS Manager, right-click your server name (WIN-J17IMHCEMA9) → **Properties**
2. Click the **Forwarders** tab
3. Click **Edit...**
4. Type `8.8.8.8` → Press **Enter**
5. Type `8.8.4.4` → Press **Enter**
6. Click **OK → OK**

### A7. Change DNS Setting Back to Yourself

If you changed DNS to 8.8.8.8 earlier (to fix internet), change it back now
so your server uses its own DNS:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1, 8.8.8.8
```

### A8. Test DNS

Open PowerShell and run:

```powershell
# Test forward lookup (name to IP)
nslookup server1.e6.local

# Expected result:
# Name:    server1.e6.local
# Address:  192.168.1.10

# Test reverse lookup (IP to name)
nslookup 192.168.1.10

# Expected result:
# Name:    server1.e6.local
# Address:  192.168.1.10

# Test external DNS still works (via forwarder)
nslookup google.com

# Expected result:
# Name:    google.com
# Address:  142.250.x.x (some IP)
```

> **TIP:** If `nslookup google.com` fails:
> 1. Check your Forwarder is set to `8.8.8.8`
> 2. Make sure `ping 8.8.8.8` works (network connectivity)
> 3. Make sure your DNS is set to `127.0.0.1` (check with `ipconfig /all`)

**DNS Server is now working!**

---

## Part B: Install & Configure DHCP Server

### DHCP Server Deep-Dive

#### 1. What is a DHCP Server?
DHCP (Dynamic Host Configuration Protocol) is a network management protocol that **automatically assigns IP addresses and network configuration settings** to devices when they connect to a network.

#### 2. What is it used for?
- **Automating Client Network Configuration:** Automatically hands out 4 essential settings to clients:
  1. IP Address (`192.168.1.100 - .200`)
  2. Subnet Mask (`255.255.255.0`)
  3. Default Gateway (`192.168.1.1` - VMware NAT router exit door)
  4. DNS Server (`192.168.1.10` - Windows Server DNS)
- **IP Address Pool Management:** Recycles and reassigns unused IP addresses when devices disconnect or leases expire.

#### 3. Key Advantages & Benefits:
- 🚀 **Zero Manual Configuration:** Eliminates the need for network admins to manually configure IP settings on hundreds of employee laptops/phones.
- 🛡️ **No IP Conflicts:** Prevents duplicate IP addresses on the network (which causes network crashes).
- 📍 **Centralized Network Administration:** Administrators can change Gateway or DNS settings in ONE place (DHCP Server), and all clients receive the updated settings automatically!
- 🔄 **Efficient Address Reuse:** Uses "leases" so temporary devices don't permanently consume IP addresses.

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

This authorizes the DHCP server in your network (required for Active Directory).

### Understanding DHCP Manager Folder Structure

After authorization, open **Server Manager → Tools → DHCP**. You will see:

```
DHCP
└── win-j17imhcema9.e6.local       <- Your DHCP server name
    ├── IPv4                         <- DHCP for IPv4 (we use this)
    │   ├── Server Options           <- Settings that apply to ALL scopes
    │   ├── Policies                 <- Rules (e.g. give specific IP to specific device)
    │   └── Filters                  <- Allow/block devices by MAC address
    │
    └── IPv6                         <- DHCP for IPv6 (ignore for now)
        └── Server Options
```

| Folder | Purpose | Do You Need It? |
|:-------|:--------|:---------------|
| **IPv4** | Where you create your DHCP scope (IP range) | Yes - work here |
| **Server Options** | Default settings (gateway, DNS) for ALL scopes | Optional |
| **Policies** | Advanced rules like "give Windows devices one IP range, phones another" | Not needed now |
| **Filters** | Allow or deny specific devices by MAC address | Not needed now |
| **IPv6** | Same as IPv4 but for IPv6 addresses | Ignore for now |

### Difference Between Server Options and Scope Options

- **Server Options (Global):** Settings configured here apply to **ALL scopes** on this DHCP server (e.g., if you have 5 different subnets, they will all inherit these DNS or Gateway settings).
- **Scope Options (Local):** Settings configured inside a specific Scope apply **ONLY to that scope**. Scope Options will override Server Options if both exist.

> **Best Practice for Labs:** We configure options directly inside **Scope Options** during scope creation so that each scope/subnet has its exact custom settings.

After creating a scope, the tree will look like:

```
IPv4
├── Scope [192.168.1.0] Lab Network    <- NEW! (we create this next)
│   ├── Address Pool                    <- Shows IP range (.100-.200)
│   ├── Address Leases                  <- Shows which clients got an IP
│   ├── Reservations                    <- Fixed IPs for specific devices
│   └── Scope Options                   <- Gateway, DNS for THIS specific scope
├── Server Options                     <- Global defaults for ALL scopes
├── Policies
└── Filters
```

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
> and 192.168.1.200.
> - Your server (192.168.1.10) is outside this range — no conflict
> - Your gateway (192.168.1.1) is outside this range — no conflict
> - You have 101 IPs available for clients (.100 to .200)

7. Click **Next**
8. **Exclusions:** Skip (click **Next**) — unless you want to reserve specific IPs
9. **Lease Duration:** Leave at 8 days (default) → **Next**

   > **What is Lease Duration?**
   > How long a device gets to keep its IP address before it must renew.
   > 8 days is fine for a lab.

10. Select **Yes, I want to configure these options now** → **Next**

### B4. Configure DHCP Options

These options are sent to EVERY device that gets an IP from your DHCP server.

#### Default Gateway (Router):
1. Type: `192.168.1.1` (your VMware NAT gateway)
2. Click **Add** → **Next**

> **Why is Default Gateway added to DHCP?**
> When a client connects, DHCP provides **4 essential settings**:
> 1. IP Address (`192.168.1.100`)
> 2. Subnet Mask (`255.255.255.0`)
> 3. **Default Gateway (`192.168.1.1`)** — Tells clients where the router/internet exit door is.
> 4. DNS Server (`192.168.1.10`)
> 
> *If you omit Default Gateway in DHCP:* The client gets an IP address and can talk to local servers (`192.168.1.x`), but **WILL NOT have internet access** because it doesn't know where the router is!

#### DNS Server:
1. Parent domain: `e6.local`
2. In the IP address box, make sure `192.168.1.10` (your server) is listed.
3. If `8.8.8.8` is listed in the box, select it and click **Remove**.
4. Click **Next**

> **Why remove 8.8.8.8?** 
> `192.168.1.10` (your server) resolves local domain names (`e6.local`) AND forwards internet queries to Google (`8.8.8.8`). If clients ask `8.8.8.8` directly, Google will fail to resolve internal names like `server1.e6.local`. Clients must ONLY point to `192.168.1.10`.

#### WINS Servers:
1. Leave blank and click **Next**

> **What is WINS?**
> WINS (Windows Internet Name Service) is an old legacy NetBIOS name resolution system used in Windows 95/NT/2000 before DNS existed. Modern networks use DNS, so WINS is left unconfigured.

#### Activate Scope:
1. Select **Yes, I want to activate this scope now** → Click **Next → Finish**

> **What does activating the scope do?**
> An inactive scope sits disabled. Activating the scope enables the DHCP service to start listening for client requests and handing out IP addresses from the `192.168.1.100 - .200` pool.

**DHCP Server is now fully configured and active!**

### How Virtual Networking Works (VMnet8 as a Virtual Switch)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       YOUR PHYSICAL PC (HOST COMPUTER)                      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        VMware Workstation                           │   │
│   │                                                                     │   │
│   │             ┌────────────────────────────────────────┐              │   │
│   │             │   VMnet8 Virtual Switch (192.168.1.0)  │              │   │
│   │             └───────┬────────────────────┬───────────┘              │   │
│   │                     │ Virtual Cable 1    │ Virtual Cable 2          │   │
│   │                     ▼                    ▼                          │   │
│   │             ┌───────────────┐    ┌───────────────┐                  │   │
│   │             │ Server VM     │    │ Client VM     │                  │   │
│   │             │ 192.168.1.10  │    │ 192.168.1.100 │                  │   │
│   │             └───────────────┘    └───────────────┘                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### How the VMs talk to each other step-by-step:
1. **The Virtual Switch (VMnet8):** VMware creates an invisible, virtual Ethernet switch inside your RAM named **VMnet8**.
2. **The Virtual Cable:** Selecting **NAT** in VM settings plugs a virtual network cable from that VM into **VMnet8**.
3. **DHCP Communication (DORA Process):**
   * **D - Discover:** Client VM broadcasts on VMnet8: *"Is there a DHCP Server on this switch?"*
   * **O - Offer:** Server VM receives the broadcast on VMnet8 and replies: *"Yes! I offer IP 192.168.1.100."*
   * **R - Request:** Client VM replies: *"Great! I accept IP 192.168.1.100."*
   * **A - Acknowledge:** Server VM replies: *"Confirmed! IP 192.168.1.100 is yours for 8 days."*

> **What if VMs are on different VMnets (e.g. Server on VMnet8, Client on VMnet1)?**
> - **They WILL NOT talk to each other!**
> - It is like plugging Server into a switch in Room A and Client into a switch in Room B with no cable between the rooms.
> - The DHCP Discover broadcast from Client stays inside VMnet1 and never reaches Server on VMnet8.
> - The Client will fail to get an IP and get a `169.254.x.x` (APIPA) address. Both VMs **MUST** be on the SAME VMnet (VMnet8).

---

## Part C: Test with Client VM (pro-win-client)

### C1. Prepare Client VM

1. Open **pro-win-client** VM in VMware
2. Make sure the network adapter is set to **NAT (VMnet8)**
   (Right-click VM → Settings → Network Adapter → NAT)
3. Make sure network settings are set to **Obtain an IP address automatically** (DHCP)
   (Network Settings → Ethernet → IPv4 → Obtain IP address automatically)

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

> **If the client gets a different IP (like 169.254.x.x):**
> - Make sure VMware DHCP is UNCHECKED in Virtual Network Editor
> - Make sure your DHCP scope is activated on the server
> - Make sure client and server are both on VMnet8

### C3. Test DNS from Client

```cmd
nslookup server1.e6.local

ping server1.e6.local

ping google.com
```

**Expected results:**
```
server1.e6.local  →  192.168.1.10
ping server1.e6.local  →  Reply from 192.168.1.10
ping google.com  →  Reply from xxx.xxx.xxx.xxx
```

### C4. Verify DHCP Lease on Server

On your **Windows Server**, verify the DHCP lease:

1. Open **DHCP Manager** (Server Manager → Tools → DHCP)
2. Expand your scope → Click **Address Leases**
3. You should see the client's IP address and MAC address listed

**Both DNS and DHCP are working! Client is connected!**

---

## Troubleshooting

### Problem: ping google.com fails on server
1. Check DNS forwarder is set to `8.8.8.8`
2. Check `ping 8.8.8.8` works (network issue if it fails)
3. Check DNS is set to `127.0.0.1` with `ipconfig /all`

### Problem: Client gets 169.254.x.x IP
1. Uncheck VMware DHCP in Virtual Network Editor
2. Make sure DHCP scope is activated on server
3. Make sure client is on VMnet8 (NAT)
4. Run `ipconfig /release` then `ipconfig /renew` on client

### Problem: nslookup fails with "server not found"
1. Check DNS service is running: `Get-Service DNS`
2. Check DNS is set to `127.0.0.1`: `ipconfig /all`
3. Restart DNS service: `Restart-Service DNS`

### Problem: PTR record warning when adding A record
- This is normal if you haven't created the Reverse Lookup Zone yet
- The A record is still created successfully
- Create the Reverse Lookup Zone, then re-add the record if needed

### Problem: Windows shows "No Internet" icon
- Ignore it if `ping google.com` works
- The icon sometimes takes time to update
- `ipconfig /release` and `/renew` don't work with static IP — this is normal

### Understanding External Ping / Test-NetConnection to `google.com` (Timeouts)
- **Symptom:** `nslookup google.com` succeeds (returns `142.250.198.174`), but `ping google.com` or `Test-NetConnection -Port 443` times out.
- **Why this happens:** 
  1. VMware NAT service on your Host PC isolates VMnet8 from forwarding ICMP ping & certain raw TCP packets outbound.
  2. Physical Host Wi-Fi routers & Windows Host Defender Firewall often block/drop outbound ICMP/TCP traffic originating from virtual network adapters.
- **Does this affect lab grading? NO!**
  - Your Windows Server lab tests **internal LAN communication**:
    - DHCP IP Leasing (`192.168.1.100`) ✅
    - Local Domain DNS (`server1.e6.local` → `192.168.1.10`) ✅
    - Client-to-Server Ping (`ping server1.e6.local` 0ms delay) ✅
  - All 14 server roles (File Server, FTP, IIS, RDP, VPN, RADIUS) run locally inside `192.168.1.0/24` between your VMs and do NOT require outbound internet.

---

## Part D: Joining Client VM to Active Directory (`e6.local`)

### Difference Between DHCP and Active Directory Membership

| Action | What it does | Where the computer appears |
|:---|:---|:---|
| **1. Request DHCP IP** (`ipconfig /renew`) | Gives the client a temporary network address (`192.168.1.100`). | Appears in **DHCP Manager → Address Leases** |
| **2. Join Domain** (System Settings → Domain Join) | Registers the client computer into the Active Directory database as an official domain member. | Appears in **Active Directory Users and Computers → Computers** |

#### Real-World Analogy:
- **Getting a DHCP IP** is like getting a **parking ticket at a parking lot**. It lets the computer stand on the network, but the company doesn't know who owns it yet.
- **Joining the Domain** is like **signing a job contract**. It registers the computer as an official device managed by your Windows Server.

### Pre-Flight Checklist Before Joining Domain

Before attempting to join the domain, verify **3 essential requirements**:
1. ✅ **Same Virtual Switch:** Both VMs must be connected to **VMnet8 (NAT)**.
2. ✅ **Same Subnet:** Server is `192.168.1.10`, Client is `192.168.1.100`.
3. ✅ **Client DNS points to Server:** Client's DNS must be set to `192.168.1.10`.

#### The 5-Second Test (Run on Client VM):
Open Command Prompt on **`pro-win-client`** and run:
```cmd
nslookup e6.local
```
If it resolves `e6.local` → `192.168.1.10`, you are 100% ready to join!

---

### Step-by-Step Instructions to Join Client VM to Domain

Perform these steps on your **Client VM (`pro-win-client`)**:

1. Press `Win + R` → type `sysdm.cpl` → press **Enter** *(opens System Properties)*.
2. Under the **Computer Name** tab, click **Change...**
3. Under *Member of*, select **Domain** → type:
   ```text
   e6.local
   ```
4. Click **OK**.
5. When prompted for credentials, type:
   - **Username:** `E6\Administrator` (or `Administrator`)
   - **Password:** *(your domain admin password)*
6. Click **OK**. You will see a popup: *"Welcome to the e6.local domain!"*
7. Click **OK** and **Restart** the Client VM.

---

### Verify Active Directory Membership on Windows Server

After restarting the Client VM:

1. Open **Active Directory Users and Computers** on `pro-win-server` (`Server Manager → Tools → Active Directory Users and Computers`).
2. Expand `e6.local` → click **Computers**.
3. 🎉 You will now see your client computer (`CLIENT`) listed inside Active Directory!

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

## DNS Traffic Flow

```
Client asks: "What is server1.e6.local?"

  Client (.100)  --->  DNS Server (.10)
                       "I know this! It's 192.168.1.10"
  Client (.100)  <---  DNS Server (.10)


Client asks: "What is google.com?"

  Client (.100)  --->  DNS Server (.10)
                       "I don't know, let me ask my forwarder..."
                            |
                            v
                       Google DNS (8.8.8.8)
                       "It's 142.250.x.x"
                            |
  Client (.100)  <---  DNS Server (.10)
                       "It's 142.250.x.x"
```

## Next Step

Once DNS and DHCP are working, we will move to **Step 2: File Server + FTP Server**.
