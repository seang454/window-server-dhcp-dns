# Step 4: Database Server (PostgreSQL & Oracle Database 19c) Setup Guide

**Windows Server 2022 on VMware Workstation**  
**Domain: e6.local**  
**Server IP: 192.168.1.10**  
**PostgreSQL Port: 5432**  
**Oracle DB Listener Port: 1521**  
**Oracle EM Express Port: 5500**  

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
                    │  │ Oracle 19c Enterprise (Port 1521)│  │
                    │  │ ├── CDB: orcl.e6.local           │  │
                    │  │ └── PDB: orclpdb                 │  │
                    │  └──────────────────────────────────┘  │
                    └────────────────────────────────────────┘
```

---

## 🔄 Master Deployment Flowchart: Enterprise Database Server Setup

```
                    MASTER DATABASE SERVER DEPLOYMENT FLOWCHART
                        
 [ PHASE 1: DATABASE ENGINE INSTALLATION (pro-win-server) ]
   1. Install PostgreSQL 18 Server (`C:\Program Files\PostgreSQL\18`)
   2. Install Oracle Database 19c Enterprise (`C:\server\oracle\WINDOWS.X64_193000_db_home`)
            │
            ▼
 [ PHASE 2: NETWORK LISTENER & FIREWALL CONFIGURATION ]
   1. Configure PostgreSQL `postgresql.conf` (`listen_addresses = '*'`)
   2. Configure PostgreSQL `pg_hba.conf` (`host all all 192.168.1.0/24 scram-sha-256`)
   3. Verify Oracle Listener Status (`lsnrctl status` on Port 1521)
   4. Open Inbound Windows Firewall Ports: 5432 (PostgreSQL) & 1521 (Oracle)
            │
            ▼
 [ PHASE 3: DATABASE & SECURITY USER PROVISIONING ]
   1. Create application user (`portfolio_user`) with strong password
   2. Create application database (`portfolio_db`) owned by `portfolio_user`
   3. Provision Oracle Pluggable Database (`orclpdb`) & tablespaces
            │
            ▼
 [ PHASE 4: APPLICATION & CLIENT INTEGRATION ]
   1. Connect Next.js application via Prisma/pg driver (`postgresql://portfolio_user:pass@localhost:5432/portfolio_db`)
   2. Connect Client VM management tools (pgAdmin 4, DBeaver, SQL Developer)
            │
            ▼
 🎉 SUCCESS! Enterprise Multi-Tenant Relational Databases Running 24/7!
```

---

## 📊 Multi-Database Hosting Architecture (One Server ──► Multiple Databases)

A single Database Server instance running on Windows Server can host **dozens or hundreds of completely isolated databases** simultaneously:

| Database Engine | Example Databases Hosted on 1 Server | Security & Data Isolation |
|:---|:---|:---|
| 🐘 **PostgreSQL (Port 5432)** | • `portfolio_db`<br>• `hr_system_db`<br>• `finance_db`<br>• `e_commerce_db` | Each database has its own isolated tables, schema, and dedicated user credentials (`portfolio_user`, `hr_user`). |
| 🔴 **Oracle DB 19c (Port 1521)** | • `orcl.e6.local` (Container DB)<br>• `orclpdb` (Pluggable DB 1)<br>• `hrpdb` (Pluggable DB 2) | Uses Oracle Multitenant Architecture (PDBs) to separate corporate business applications inside 1 Container Database (CDB). |

> **Key Enterprise Advantage:** Hosting multiple databases on 1 server consolidates CPU, RAM, and storage, while enforcing strict user credential isolation so no application can read another database's tables!

---

## 🔒 Security Model: Local LAN & Web Application Isolation

In enterprise environments, database engines (PostgreSQL and Oracle) are kept hidden inside the **Local LAN Zone** behind web servers:

| Layer | Component | Function & Security Scope |
|:---|:---|:---|
| **Tier 1 (Public / Edge)** | **Microsoft IIS (Port 80/443)** | Receives public user web traffic (`portfolio.e6.local`). |
| **Tier 2 (Application)** | **Next.js Standalone (Port 3000)** | Renders React components, processes forms, executes SQL queries. |
| **Tier 3 (Database)** | **PostgreSQL (5432) / Oracle (1521)** | Stores customer records, contact form messages, and portfolio logs. **Hidden from public internet.** |

> **Security Rule:** Database ports (`5432` and `1521`) are **never** exposed directly to public internet router ports to prevent automated SQL injection and brute-force attacks.

---

## 🚀 Part 1: PostgreSQL 18 Setup Guide (Completed ✅)

---

### Step 1: Install PostgreSQL Database Server on Server VM (`pro-win-server`)

#### 🎯 Objective & Purpose
To install PostgreSQL Server engine (v18+) and pgAdmin 4 management console on `pro-win-server`.

#### 🛠️ What it is for
PostgreSQL is an open-source relational database management system (RDBMS) that stores structured tables, JSON documents, and relational data for web applications.

#### ⚙️ Configuration Steps
1. On `pro-win-server`, download **PostgreSQL Windows x64 Installer** from `https://www.postgresql.org/download/windows/`.
2. Run `postgresql-18.x-x64.exe` as Administrator.
3. Select installation directory: `C:\Program Files\PostgreSQL\18`.
4. Select components: Check ✅ **PostgreSQL Server**, ✅ **pgAdmin 4**, ✅ **Command Line Tools**.
5. Set password for superuser `postgres` *(e.g., `Admin123!`)*.
6. Set Port: `5432`.
7. Click **Next → Next → Install** → wait for completion → click **Finish**.

#### ✅ Expected Verification Result
Opening Command Prompt on `pro-win-server` and running `"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432` prompts for password and opens `postgres=#` SQL shell.

---

### Step 2: Configure `postgresql.conf` & `pg_hba.conf` for Network Access

#### 🎯 Objective & Purpose
To configure PostgreSQL to listen on all server IP network interfaces (`0.0.0.0`) and grant client machines on subnet `192.168.1.0/24` permission to authenticate.

#### 🛠️ What it is for
By default, PostgreSQL listens only on `localhost` (`127.0.0.1`). Updating `listen_addresses = '*'` and adding `192.168.1.0/24` to `pg_hba.conf` allows Next.js backend scripts and Client VM tools (pgAdmin/DBeaver) to connect over the LAN.

#### ⚙️ Configuration Steps
1. Open `C:\Program Files\PostgreSQL\18\data\postgresql.conf` in Notepad as Admin.
2. Search for `listen_addresses` → set:
```text
listen_addresses = '*'
```
3. Save `postgresql.conf`.
4. Open `C:\Program Files\PostgreSQL\18\data\pg_hba.conf` in Notepad as Admin.
5. Scroll to the bottom and add this line:
```text
host    all             all             192.168.1.0/24          scram-sha-256
```
6. Save `pg_hba.conf`.
7. Open Services (`services.msc`) → right-click **postgresql-x64-18** → click **Restart**.

#### ✅ Expected Verification Result
PostgreSQL service restarts cleanly and listens on `0.0.0.0:5432`.

---

### Step 3: Create Portfolio Database & User in pgAdmin 4

#### 🎯 Objective & Purpose
To create dedicated database `portfolio_db` and application user `portfolio_user` with password credentials.

#### 🛠️ What it is for
Prevents web applications from running as superuser `postgres` (Least Privilege Principle).

#### ⚙️ Configuration Steps
1. Open **pgAdmin 4** on `pro-win-server` (**Start → PostgreSQL 18 → pgAdmin 4**).
2. Enter master password → expand **Servers → PostgreSQL 18**.
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

## 🔴 Part 2: Oracle Database 19c Enterprise Edition Full 17-Step Guide (Completed ✅)

---

### 📖 Oracle 19c Account Hierarchy & Multitenant Architecture

```
                      ORACLE 19c DATABASE INSTANCE (orcl)
                      
   ┌──────────────────────────────────────────────────────────────────┐
   │                  CONTAINER DATABASE (CDB$ROOT)                  │
   │                                                                  │
   │  👑 SYS (sys as sysdba)     ──► Controls SGA/PGA RAM Memory,     │
   │                                  Disk Storage, & Kernel Services.│
   │  🛡️ SYSTEM                   ──► Creates Users, Tablespaces,     │
   │                                  and manages Global DBAs.        │
   └─────────────────────────────────┬────────────────────────────────┘
                                     │
                 ┌───────────────────┴───────────────────┐
                 │                                       │
   ┌─────────────▼─────────────┐           ┌─────────────▼─────────────┐
   │ PLUGGABLE DATABASE (PDB1) │           │ PLUGGABLE DATABASE (PDB2) │
   │          orclpdb          │           │           hrpdb           │
   │                           │           │                           │
   │ 🏢 PDBADMIN               │           │ 🏢 PDBADMIN               │
   │   (Manages PDB1 schema)   │           │   (Manages PDB2 schema)   │
   │                           │           │                           │
   │ 📁 portfolio_user         │           │ 📁 hr_user                │
   │   (Portfolio tables)      │           │   (Employee tables)       │
   └───────────────────────────┘           └───────────────────────────┘
```

---

### ⚙️ Complete Step-by-Step Oracle 19c Installer Breakdown & Technical Rationale

| Step | Wizard Screen | Selected Option / Choice | Technical Reason & Justification |
|:---|:---|:---|:---|
| **Step 1** | **Configuration Option** | `Create and configure a single instance database` | Automatically creates a ready-to-use starter database instance (`orcl`) during software installation, saving us from having to run DBCA manually later. |
| **Step 2** | **System Class** | `Server class` | Unlocks enterprise memory (SGA/PGA) tuning, Pluggable Databases (PDBs), and full Active Directory Domain Controller integration for Windows Server 2022. |
| **Step 3** | **Install Type** | `Advanced install` | Allows custom selection of the **Oracle Home User** (`Windows Built-in Account`), which is required to bypass Virtual Account restrictions (`INS-35156`) on Domain Controllers. |
| **Step 4** | **Database Edition** | `Enterprise Edition` | Provides full industry-standard database features (partitioning, parallel SQL queries, multitenant architecture) with zero limitations. |
| **Step 5** | **Oracle Home User** | `Use Windows Built-in Account` (`NT AUTHORITY\SYSTEM`) | Bypasses error **`INS-35156`** on Active Directory Domain Controllers 100%! Allows Windows to run Oracle services in the background automatically on system boot. |
| **Step 6** | **Installation Location** | `C:\server\app\Administrator` (Base)<br>`C:\server\oracle\WINDOWS.X64_193000_db_home` (Home) | Follows Oracle's Optimal Flexible Architecture (OFA) directory structure for Windows, ensuring clean separation of binaries and data files. |
| **Step 7** | **Configuration Type** | `General Purpose / Transaction Processing` | Optimized for Online Transaction Processing (OLTP) applications (like Next.js web applications, portfolio forms, user logins, and web API queries). |
| **Step 8** | **Database Identifiers** | Global DB: `orcl.e6.local`<br>SID: `orcl`<br>PDB: `orclpdb` | Automatically binds the database to your Active Directory domain (`e6.local`) and creates a Pluggable Database (`orclpdb`) for multi-tenant isolation. |
| **Step 9** | **Configuration Options** | RAM: `2483 MB`<br>Charset: `AL32UTF8`<br>Sample Schemas: Checked ✅ | • **RAM:** Prevents Oracle from consuming all server memory.<br>• **AL32UTF8:** Universal UTF-8 Unicode character set supporting all global languages.<br>• **Sample Schemas:** Installs classic `HR` tables for testing SQL. |
| **Step 10** | **Database Storage** | `File system` (`C:\server\app\Administrator\oradata`) | Stores datafiles directly inside standard Windows NTFS folders on the C drive. |
| **Step 11** | **Management Options** | Unchecked EM Cloud Control | Enables local lightweight **Oracle Enterprise Manager Express** on Port 5500 (`https://localhost:5500/em`) without needing extra management servers. |
| **Step 12** | **Recovery Options** | Default Recovery | Uses standard fast recovery area (FRA) settings without requiring dedicated tape drive hardware. |
| **Step 13** | **Schema Passwords** | `Use the same password for all accounts` (`OraclePass123`) | Sets a single, secure master administrative password for `SYS`, `SYSTEM`, and `PDBADMIN` accounts for easy management. |
| **Step 14** | **Prerequisite Checks** | Passed All Checks ✅ | Confirms OS architecture, admin privileges, registry keys, and memory meet Oracle 19c Enterprise specifications. |
| **Step 15** | **Summary** | Click `Install` | Review and lock in all 14 configuration decisions before compilation starts. |
| **Step 16** | **Install Product** | Executed DBCA (0% to 100%) | Automatically compiled Oracle DLL binaries, registered Windows Services (`OracleServiceORCL` & `OracleOraDB19Home1TNSListener`), and built datafiles. |
| **Step 17** | **Finish** | Click `Close` | Displays final confirmation and EM Express management URL (`https://WIN-J17IMHCEMA9.e6.local:5500/em`). |

---

### Step 6: Configure Firewall Inbound Rule for Oracle Port 1521

#### 🎯 Objective & Purpose
To open inbound TCP Port 1521 in Windows Defender Firewall for local LAN connections.

#### ⚙️ Configuration Steps
Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
netsh advfirewall firewall add rule name="Allow Oracle Database Port 1521" dir=in action=allow protocol=TCP localport=1521
```

#### ✅ Expected Verification Result
Opening Command Prompt and running `lsnrctl status` displays Listener running on Port `1521` with SID `orcl` and Service `orclpdb`.

---

## 🛠️ Verification & Troubleshooting Commands

```powershell
# Check PostgreSQL Service & Port
Get-Service -Name postgresql*
Test-NetConnection -ComputerName 192.168.1.10 -Port 5432

# Check Oracle Listener & Services
Get-Service -Name Oracle*
lsnrctl status
Test-NetConnection -ComputerName 192.168.1.10 -Port 1521
```

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
