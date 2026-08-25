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

### ⚙️ Complete Step-by-Step Oracle 19c Installer Breakdown (Step 1 to Step 17)

#### Step 1 of 17: Select Configuration Option
* 🎯 **Objective & Purpose:** To create a starter enterprise database instance during software installation.
* ⚙️ **Configuration Action:** Select **`Create and configure a single instance database`** → click **Next >**.
* ✅ **Verification:** Installer advances to Step 2.

#### Step 2 of 17: Select System Class
* 🎯 **Objective & Purpose:** To choose the operating environment class for performance and memory tuning.
* ⚙️ **Configuration Action:** Select **`Server class`** → click **Next >**.
* 🛠️ **Why:** Server class enables enterprise multitenant architecture, listener tuning, and Active Directory Domain Controller support.

#### Step 3 of 17: Select Install Type
* 🎯 **Objective & Purpose:** To unlock advanced security, character set, and Oracle Home User options.
* ⚙️ **Configuration Action:** Select **`Advanced install`** → click **Next >**.
* 🛠️ **Why:** Advanced install lets us select `Windows Built-in Account` to bypass Virtual Account restrictions (`INS-35156`) on Domain Controllers.

#### Step 4 of 17: Select Database Edition
* 🎯 **Objective & Purpose:** To choose between Enterprise Edition and Standard Edition 2.
* ⚙️ **Configuration Action:** Select **`Enterprise Edition`** → click **Next >**.
* 🛠️ **Why:** Enterprise Edition provides full partitioning, parallel SQL execution, and unlimited pluggable database capabilities.

#### Step 5 of 17: Specify Oracle Home User
* 🎯 **Objective & Purpose:** To specify the Windows service user for running Oracle background processes.
* ⚙️ **Configuration Action:**
  1. Select **`Use Windows Built-in Account`** (`NT AUTHORITY\SYSTEM`).
  2. Click **Next >**.
  3. When warning `[INS-35810]` appears (*"Are you sure you want to continue?"*), click **Yes**!
* 🛠️ **Why:** Bypasses Virtual Account error `INS-35156` on Active Directory Domain Controllers cleanly.

#### Step 6 of 17: Specify Installation Location
* 🎯 **Objective & Purpose:** To define the Oracle Base directory and Software Location (`ORACLE_HOME`).
* ⚙️ **Configuration Action:**
  - **Oracle base:** `C:\server\app\Administrator`
  - **Software location:** `C:\server\oracle\WINDOWS.X64_193000_db_home`
  - Click **Next >**.

#### Step 7 of 17: Select Configuration Type
* 🎯 **Objective & Purpose:** To select the workload pattern for the starter database.
* ⚙️ **Configuration Action:** Select **`General Purpose / Transaction Processing`** → click **Next >**.
* 🛠️ **Why:** Optimized for online web applications (Next.js), user logins, and transaction tables (OLTP).

#### Step 8 of 17: Specify Database Identifiers
* 🎯 **Objective & Purpose:** To set the unique global database name, System Identifier (SID), and Pluggable Database (PDB).
* ⚙️ **Configuration Action:**
  - **Global database name:** `orcl.e6.local` *(automatically detects AD domain `e6.local`)*
  - **Oracle system identifier (SID):** `orcl`
  - Check ✅ **`Create as Container database`**
  - **Pluggable database name:** `orclpdb`
  - Click **Next >**.

#### Step 9 of 17: Specify Configuration Options
* 🎯 **Objective & Purpose:** To configure RAM memory allocation, Unicode character sets, and sample schemas.
* ⚙️ **Configuration Action:**
  1. **Memory tab:** Allocate memory slider set to `2483 MB (40%)`.
  2. **Character sets tab:** Select **`Use Unicode (AL32UTF8)`**.
  3. **Sample schemas tab:** Check ✅ **`Install sample schemas in the database`** *(installs `HR` and `SCOTT` sample tables)*.
  4. Click **Next >**.

#### Step 10 of 17: Specify Database Storage Options
* 🎯 **Objective & Purpose:** To specify the physical storage mechanism for database datafiles.
* ⚙️ **Configuration Action:** Select **`File system`** → location: `C:\server\app\Administrator\oradata` → click **Next >**.

#### Step 11 of 17: Specify Management Options
* 🎯 **Objective & Purpose:** To configure Enterprise Manager Cloud Control registration.
* ⚙️ **Configuration Action:** Leave `Register with Enterprise Manager (EM) Cloud Control` unchecked → click **Next >**.
* 🛠️ **Why:** Oracle 19c automatically provides local EM Database Express on Port 5500 out-of-the-box.

#### Step 12 of 17: Specify Recovery Options
* 🎯 **Objective & Purpose:** To configure automated backup and recovery locations.
* ⚙️ **Configuration Action:** Leave recovery options default → click **Next >**.

#### Step 13 of 17: Specify Schema Passwords
* 🎯 **Objective & Purpose:** To define administrative master passwords for `SYS`, `SYSTEM`, and `PDBADMIN` accounts.
* ⚙️ **Configuration Action:**
  1. Select **`Use the same password for all accounts`**.
  2. **Password:** `OraclePass123`
  3. **Confirm password:** `OraclePass123`
  4. Click **Next >**. *(If password complexity popup appears, click **Yes**)*.

#### Step 14 of 17: Prerequisite Checks
* 🎯 **Objective & Purpose:** System automatically validates Windows version, edition, environment variables, memory, and privileges.
* ⚙️ **Configuration Action:** All 5 checks display **Passed** ✅ → click **Next >**.

#### Step 15 of 17: Summary
* 🎯 **Objective & Purpose:** Displays final technical configuration tree before writing files.
* ⚙️ **Configuration Action:** Review settings (`NT AUTHORITY\SYSTEM`, `orcl.e6.local`, `orclpdb`, `AL32UTF8`) → click **Install**!

#### Step 16 of 17: Install Product
* 🎯 **Objective & Purpose:** Installer copies software binaries, compiles DLLs, and executes Database Configuration Assistant (DBCA) to create `orcl` database from 0% to 100%.
* ⚙️ **Configuration Action:** Watch progress bar. *(If popup asks "Do you want to exit?", click **No**)*.

#### Step 17 of 17: Finish (Completed ✅)
* 🎯 **Objective & Purpose:** Displays final confirmation and Enterprise Manager Express URL.
* ⚙️ **Configuration Action:**
  - Displays: *"The configuration of Oracle Database was successful. Oracle Enterprise Manager Database Express URL: https://WIN-J17IMHCEMA9.e6.local:5500/em"*
  - Click **Close**!

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
