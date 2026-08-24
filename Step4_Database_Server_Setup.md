# Step 4: Database Server (PostgreSQL & Oracle Database) Setup Guide

**Windows Server 2022 on VMware Workstation**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  
**PostgreSQL Port: 5432**  
**Oracle DB Listener Port: 1521**  

---

## 📖 Deep-Dive Concepts & Architecture

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
                    │  │ Web Server (IIS + Next.js)       │  │
                    │  │ Port 80 / localhost:3000         │  │
                    │  └────────────────┬─────────────────┘  │
                    │                   │ Internal DB Query  │
                    │  ┌────────────────▼─────────────────┐  │
                    │  │ PostgreSQL Engine (Port 5432)    │  │
                    │  │ ├── database: portfolio_db       │  │
                    │  │ ├── database: hr_system_db       │  │
                    │  │ └── database: finance_db         │  │
                    │  └──────────────────────────────────┘  │
                    │  ┌──────────────────────────────────┐  │
                    │  │ Oracle Database XE (Port 1521)   │  │
                    │  │ ├── Pluggable DB: XEPDB1         │  │
                    │  │ └── Pluggable DB: PORTFOLIO_PDB  │  │
                    │  └──────────────────────────────────┘  │
                    └────────────────────────────────────────┘
```

---

### Multi-Database Hosting Architecture (One Server ──► Multiple Databases)

A single Database Server instance running on Windows Server can host **dozens or hundreds of completely isolated databases** simultaneously:

| Database Engine | Example Databases Hosted on 1 Server | Security & Data Isolation |
|:---|:---|:---|
| 🐘 **PostgreSQL (Port 5432)** | • `portfolio_db`<br>• `hr_system_db`<br>• `finance_db`<br>• `e_commerce_db` | Each database has its own isolated tables, schema, and dedicated user credentials (`portfolio_user`, `hr_user`). |
| 🔴 **Oracle DB (Port 1521)** | • `XEPDB1` (Pluggable DB 1)<br>• `PORTFOLIO_PDB` (Pluggable DB 2)<br>• `ERP_PDB` (Pluggable DB 3) | Uses Oracle Multitenant Architecture (PDBs) to separate corporate business applications inside 1 Container Database (CDB). |

> **Key Enterprise Advantage:** Hosting multiple databases on 1 server consolidates CPU, RAM, and storage, while enforcing strict user credential isolation so no application can read another database's tables!

---

## 📊 Security Model: Local LAN & Web Application Isolation

In enterprise environments, database engines (PostgreSQL and Oracle) are kept hidden inside the **Local LAN Zone** behind web servers:

| Layer | Component | Function & Security Scope |
|:---|:---|:---|
| **Tier 1 (Public / Edge)** | **Microsoft IIS (Port 80/443)** | Receives public user web traffic (`portfolio.e6.local`). |
| **Tier 2 (Application)** | **Next.js Standalone (Port 3000)** | Renders React components, processes forms, executes SQL queries. |
| **Tier 3 (Database)** | **PostgreSQL (5432) / Oracle (1521)** | Stores customer records, contact form messages, and portfolio logs. **Hidden from public internet.** |

> **Security Rule:** Database ports (`5432` and `1521`) are **never** exposed directly to public internet router ports to prevent automated SQL injection and brute-force attacks.

---

## 🚀 Step-by-Step Detailed Configuration Guide

---

### Step 1: Install PostgreSQL Database Server on Server VM (`pro-win-server`)

#### 🎯 Objective & Purpose
To install PostgreSQL Server engine (v16+) and pgAdmin 4 management console on `pro-win-server`.

#### 🛠️ What it is for
PostgreSQL is an open-source relational database management system (RDBMS) that stores structured tables, JSON documents, and relational data for web applications.

#### ⚙️ Configuration Steps
1. On `pro-win-server`, download **PostgreSQL Windows x64 Installer** from `https://www.postgresql.org/download/windows/`.
2. Run `postgresql-16.x-x64.exe` as Administrator.
3. Select installation directory: `C:\Program Files\PostgreSQL\16`.
4. Select components: Check ✅ **PostgreSQL Server**, ✅ **pgAdmin 4**, ✅ **Command Line Tools**.
5. Set password for superuser `postgres` *(e.g., `Admin123!`)*.
6. Set Port: `5432`.
7. Click **Next → Next → Install** → wait for completion → click **Finish**.

#### ✅ Expected Verification Result
Opening Command Prompt on `pro-win-server` and running `psql -U postgres -h localhost -p 5432` prompts for password and opens `postgres=#` SQL shell.

---

### Step 2: Configure `postgresql.conf` & `pg_hba.conf` for Network Access

#### 🎯 Objective & Purpose
To configure PostgreSQL to listen on all server IP network interfaces (`0.0.0.0`) and grant client machines on subnet `192.168.1.0/24` permission to authenticate.

#### 🛠️ What it is for
By default, PostgreSQL listens only on `localhost` (`127.0.0.1`). Updating `listen_addresses = '*'` and adding `192.168.1.0/24` to `pg_hba.conf` allows Next.js backend scripts and Client VM tools (pgAdmin/DBeaver) to connect.

#### ⚙️ Configuration Steps
1. Open `C:\Program Files\PostgreSQL\16\data\postgresql.conf` in Notepad as Admin.
2. Search for `listen_addresses` → set:
```text
listen_addresses = '*'
```
3. Save `postgresql.conf`.
4. Open `C:\Program Files\PostgreSQL\16\data\pg_hba.conf` in Notepad as Admin.
5. Scroll to the bottom and add this line:
```text
host    all             all             192.168.1.0/24          scram-sha-256
```
6. Save `pg_hba.conf`.
7. Open Services (`services.msc`) → right-click **postgresql-x64-16** → click **Restart**.

#### ✅ Expected Verification Result
PostgreSQL service restarts cleanly and listens on `0.0.0.0:5432`.

---

### Step 3: Create Portfolio Database & User in pgAdmin 4

#### 🎯 Objective & Purpose
To create dedicated database `portfolio_db` and application user `portfolio_user` with password credentials.

#### 🛠️ What it is for
Prevents web applications from running as superuser `postgres` (Least Privilege Principle).

#### ⚙️ Configuration Steps
1. Open **pgAdmin 4** on `pro-win-server` (**Start → PostgreSQL 16 → pgAdmin 4**).
2. Enter master password → expand **Servers → PostgreSQL 16**.
3. Right-click **Login/Group Roles → Create → Login/Group Role...**:
   - **Name:** `portfolio_user`
   - **Definition → Password:** `PortfolioPass123!`
   - **Privileges:** Check ✅ **Can login?** → click **Save**.
4. Right-click **Databases → Create → Database...**:
   - **Database:** `portfolio_db`
   - **Owner:** `portfolio_user` → click **Save**.

#### ✅ Expected Verification Result
`portfolio_db` appears under Databases in pgAdmin 4 owned by `portfolio_user`.

---

### Step 4: Configure Firewall Inbound Rule for PostgreSQL Port 5432

#### 🎯 Objective & Purpose
To open inbound TCP Port 5432 in Windows Defender Firewall for local LAN connections.

#### 🛠️ What it is for
Permits client VMs (`192.168.1.100`) and internal services to reach PostgreSQL engine on Port 5432.

#### ⚙️ Configuration Steps
Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
netsh advfirewall firewall add rule name="Allow PostgreSQL Port 5432" dir=in action=allow protocol=TCP localport=5432
```

#### ✅ Expected Verification Result
PowerShell returns `Ok.`.

---

### Step 5: Install & Configure Oracle Database Express Edition (XE)

#### 🎯 Objective & Purpose
To install Oracle Database 21c/19c XE and configure Oracle Listener on Port 1521.

#### 🛠️ What it is for
Oracle Database is an enterprise-grade relational database engine used widely in corporate banking, ERPs, and enterprise infrastructure.

#### ⚙️ Configuration Steps
1. On `pro-win-server`, download **Oracle Database Express Edition (XE)** from `https://www.oracle.com/database/technologies/xe-downloads.html`.
2. Extract zip file and run `setup.exe` as Administrator.
3. Accept license agreement → select destination: `C:\app\Administrator\product\21c\dbhomeXE`.
4. Enter password for `SYS` and `SYSTEM` accounts *(e.g., `OraclePass123!`)*.
5. Click **Install** → wait for setup completion.
6. Open Command Prompt (Admin) and verify Oracle Listener status:
```cmd
lsnrctl status
```

#### ✅ Expected Verification Result
`lsnrctl status` displays Listener running on Port `1521` with SID `XE` and Service `XEPDB1`.

---

### Step 6: Configure Firewall Rule & Test Oracle Connection

#### 🎯 Objective & Purpose
To open TCP Port 1521 in Windows Firewall and connect via SQL*Plus or SQL Developer.

#### 🛠️ What it is for
Allows client machines and application services to execute Oracle SQL queries.

#### ⚙️ Configuration Steps
1. Open PowerShell (Admin) on `pro-win-server` and run:
```powershell
netsh advfirewall firewall add rule name="Allow Oracle Database Port 1521" dir=in action=allow protocol=TCP localport=1521
```
2. Open Command Prompt and test SQL*Plus login:
```cmd
sqlplus sys/OraclePass123!@localhost:1521/XEPDB1 as sysdba
```

#### ✅ Expected Verification Result
SQL*Plus connects successfully and displays `Connected to: Oracle Database 21c Express Edition`.

---

## 🛠️ Verification & Troubleshooting Commands

```powershell
# Check PostgreSQL Service & Port
Get-Service -Name postgresql*
Test-NetConnection -ComputerName 192.168.1.10 -Port 5432

# Check Oracle Listener & Port
lsnrctl status
Test-NetConnection -ComputerName 192.168.1.10 -Port 1521
```

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
