# Step 4: Database Server (PostgreSQL & Oracle Database 19c) Setup & Deinstall Guide

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

---

## 🚀 Part 1: PostgreSQL 18 Setup Guide (Completed ✅)

---

### Step 1: Install PostgreSQL Database Server on Server VM (`pro-win-server`)

#### 🎯 Objective & Purpose
To install PostgreSQL Server engine (v18+) and pgAdmin 4 management console on `pro-win-server`.

#### ⚙️ Configuration Steps
1. Download **PostgreSQL Windows x64 Installer** from `https://www.postgresql.org/download/windows/`.
2. Run `postgresql-18.x-x64.exe` as Administrator.
3. Select installation directory: `C:\Program Files\PostgreSQL\18`.
4. Select components: Check ✅ **PostgreSQL Server**, ✅ **pgAdmin 4**, ✅ **Command Line Tools**.
5. Set password for superuser `postgres` *(e.g., `Admin123!`)*.
6. Set Port: `5432`.
7. Click **Next → Next → Install** → wait for completion → click **Finish**.

---

### Step 2: Configure `postgresql.conf` & `pg_hba.conf` for Network Access

#### ⚙️ Configuration Steps
1. Open `C:\Program Files\PostgreSQL\18\data\postgresql.conf` in Notepad as Admin.
2. Set: `listen_addresses = '*'`.
3. Open `C:\Program Files\PostgreSQL\18\data\pg_hba.conf` in Notepad as Admin.
4. Add line: `host all all 192.168.1.0/24 scram-sha-256`.
5. Restart PostgreSQL service in `services.msc`.

---

## 🔴 Part 2: Oracle Database 19c Enterprise Edition Full Setup Guide (Completed ✅)

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

### 🔑 Comprehensive Breakdown of Oracle Login & Connection Types

#### 1. Connection Identifier Types (DBeaver / GUI Tools)
| Connection Type | Example Syntax | When to Use |
|:---|:---|:---|
| **Service Name** (Recommended ⭐) | `192.168.1.10:1521/orclpdb.e6.local` | Primary method for connecting to **Pluggable Databases (PDBs)** in Oracle 12c/19c/21c. |
| **SID** (System Identifier) | `192.168.1.10:1521:orcl` | Legacy method used to connect to the **Container Database (`CDB$ROOT`)**. |
| **TNS Alias** | `ORCLPDB` | Connects using pre-saved network aliases in `tnsnames.ora`. |
| **EZConnect URL** | `jdbc:oracle:thin:@//192.168.1.10:1521/orclpdb.e6.local` | Used by Node.js, Next.js, Java, and Python database drivers. |

#### 2. User Authentication Roles & Security Scope
| Role | User Account | Access Scope & Security Power |
|:---|:---|:---|
| **Normal** | `system`, `hr`, `portfolio_user` | Standard database user for queries, tables, and daily administration. |
| **SYSDBA** 👑 | `sys` | **Kernel Root Superuser:** Full control over startup, shutdown, datafiles, and **reading all confidential user tables**. |
| **SYSOPER** ⚙️ | `sys` | **System Operator:** Can startup, shutdown, and mount instance, **BUT CANNOT view or read confidential user data**. |
| **SYSBACKUP** 💾 | `sysbackup` | Dedicated backup administrator role for RMAN backup operations. |

#### 🛡️ Detailed Privileges: SYSDBA vs. SYSOPER Comparison
| Action / Privilege | 👑 SYSDBA | ⚙️ SYSOPER |
|:---|:---:|:---:|
| `STARTUP` / `SHUTDOWN` Instance | ✅ Allowed | ✅ Allowed |
| `ALTER DATABASE MOUNT / OPEN` | ✅ Allowed | ✅ Allowed |
| `CREATE DATABASE` | ✅ Allowed | ❌ Forbidden |
| `SELECT FROM USER TABLES` (Read Data) | ✅ **Allowed** | ❌ **FORBIDDEN** |
| `CREATE USER` / `DROP USER` | ✅ Allowed | ❌ Forbidden |

#### 3. Authentication Methods
| Method | Description |
|:---|:---|
| **Database Native** | Password authentication stored inside Oracle Data Dictionary (`SYSTEM` / `OraclePass123`). |
| **Windows OS Authentication** | Logging in via Windows Administrator rights without typing a database password (`sqlplus / as sysdba`). |
| **Active Directory Kerberos** | Single Sign-On (SSO) using domain user accounts (`E6\Administrator`). |

### 👑 Master Oracle 19c Login Cheatsheet (All Methods Combined)

| Scenario / Goal | Database Target | Username | Role | Command Line (CMD / PowerShell) | DBeaver GUI Settings |
|:---|:---|:---|:---|:---|:---|
| 👑 **Root Superuser** *(Startup, Shutdown, Repair)* | `orcl` (SID) | `sys` | **`SYSDBA`** | `sqlplus / as sysdba` | **Host:** `192.168.1.10`<br>**Port:** `1521`<br>**Database:** SID `orcl`<br>**User:** `sys` \| **Role:** `SYSDBA` |
| 🛡️ **DBA Admin** *(Create Users, Tables, Grants)* | `orclpdb.e6.local` (Service) | `system` | **`Normal`** | `sqlplus system/OraclePass123@192.168.1.10:1521/orclpdb.e6.local` | **Host:** `192.168.1.10`<br>**Port:** `1521`<br>**Database:** Service `orclpdb.e6.local`<br>**User:** `system` \| **Role:** `Normal` |
| 👤 **Business App** *(Next.js, HR, Portfolio)* | `orclpdb.e6.local` (Service) | `hr` or `portfolio_user` | **`Normal`** | `sqlplus hr/OraclePass123@192.168.1.10:1521/orclpdb.e6.local` | **Host:** `192.168.1.10`<br>**Port:** `1521`<br>**Database:** Service `orclpdb.e6.local`<br>**User:** `hr` \| **Role:** `Normal` |
| ⚙️ **System Operator** *(Maintenance Without Data Access)* | `orcl` (SID) | `sys` | **`SYSOPER`** | `sqlplus / as sysoper` | **Host:** `192.168.1.10`<br>**Port:** `1521`<br>**Database:** SID `orcl`<br>**User:** `sys` \| **Role:** `SYSOPER` |

---

### ⚙️ Complete Step-by-Step Oracle 19c Installer Breakdown & Technical Rationale

| Step | Wizard Screen | Selected Option / Choice | Technical Reason & Justification |
|:---|:---|:---|:---|
| **Step 1** | **Configuration Option** | `Create and configure a single instance database` | Automatically creates a ready-to-use starter database instance (`orcl`) during software installation, saving us from having to run DBCA manually later. |
| **Step 2** | **System Class** | `Server class` | Unlocks enterprise memory (SGA/PGA) tuning, Pluggable Databases (PDBs), and full Active Directory Domain Controller integration for Windows Server 2022. |
| **Step 3** | **Install Type** | `Advanced install` | Allows custom selection of the **Oracle Home User** (`Windows Built-in Account`), which is required to bypass Virtual Account restrictions (`INS-35156`) on Domain Controllers. |
| **Step 4** | **Database Edition** | `Enterprise Edition` | Provides full industry-standard database features (partitioning, parallel SQL queries, multitenant architecture) with zero limitations. |
| **Step 5** | **Oracle Home User** | `Use Windows Built-in Account` (`NT AUTHORITY\SYSTEM`) | **Bypasses error `INS-35156` on Active Directory Domain Controllers 100%!** Allows Windows to run Oracle background services automatically on system boot. |
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

### Step 6: Configure Firewall Inbound Rule & Client LAN Access

#### ⚙️ Server Configuration Step (`pro-win-server`)
Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
netsh advfirewall firewall add rule name="Allow Oracle Database Port 1521" dir=in action=allow protocol=TCP localport=1521
```

#### 💻 Client Connection Parameters (`pro-win-client`)

| Parameter | Connection Value |
|:---|:---|
| **Host / IP Address** | `192.168.1.10` *(or `pro-win-server.e6.local`)* |
| **Port** | `1521` |
| **Service Name** | `orclpdb.e6.local` *(Pluggable Database)* |
| **SID** | `orcl` *(Container Database)* |
| **Username** | `system` or `hr` or `portfolio_user` |
| **Password** | `OraclePass123` |

---

## 🗑️ Part 3: Oracle 19c Deinstall & Clean Uninstallation Guide

If you ever need to safely remove or uninstall Oracle Database 19c Enterprise Edition from your server:

```
                  ORACLE 19c DEINSTALLATION FLOWCHART
                        
 1. STOP ORACLE SERVICES ──► 2. RUN DEINSTALL.BAT ──► 3. CLEAN REGISTRY & DATA
 (Stop `OracleServiceORCL`)  (`.../deinstall/deinstall.bat`)  (Delete ORACLE keys & oradata)
```

---

### Step 1: Stop Oracle Windows Services

Open **PowerShell as Administrator** on `pro-win-server` and run:

```powershell
Stop-Service -Name Oracle*
```

---

### Step 2: Execute Oracle Deinstall Tool (`deinstall.bat`)

Oracle 19c includes a dedicated command-line uninstallation tool (`deinstall.bat`) located inside your Oracle Home:

1. Open **Command Prompt as Administrator** on `pro-win-server`.
2. Navigate to the deinstall directory:
   ```cmd
   cd C:\server\oracle\WINDOWS.X64_193000_db_home\deinstall
   ```
3. Run the deinstall script:
   ```cmd
   deinstall.bat
   ```
4. Press **Enter** to accept default parameters when prompted by the script.
5. The deinstall script will cleanly unregister Windows services, stop background processes, and unmount datafiles automatically!

---

### Step 3: Clean Up Environment Variables & Registry (Optional)

1. Open **System Properties** (`sysdm.cpl`) → **Advanced** → **Environment Variables**:
   * Delete any `ORACLE_HOME` or `ORACLE_SID` variables under System Variables.
2. Open Registry Editor (`regedit`):
   * Navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE` and delete the **ORACLE** folder if it remains.
3. Delete data directory:
   * Remove `C:\server\app\Administrator\oradata` and `C:\server\oracle\`.

---

## 🛠️ Verification & Troubleshooting Commands

### 🔴 Oracle 19c Verification Test Suite (3-Step Verification)

#### Test 1: Verify Listener Status in Command Prompt
```cmd
lsnrctl status
```
* **Expected Result:** Listener status displays `PORT=1521`, `Status READY` for Service `orcl` and `orclpdb`.

#### Test 2: Connect to SQL*Plus as `SYSDBA` & Check Open Mode
```cmd
sqlplus / as sysdba
```
Inside `SQL>` prompt:
```sql
SELECT name, open_mode FROM v$database;
SHOW pdbs;
```
* **Expected Result:** `ORCL` open_mode is `READ WRITE`. `ORCLPDB` mode is `READ WRITE`.

#### Test 3: Query Sample `HR` Employees Table in Pluggable Database (`orclpdb`)
Inside `SQL>` prompt:
```sql
ALTER SESSION SET CONTAINER = orclpdb;
SELECT employee_id, first_name, last_name, salary FROM hr.employees WHERE ROWNUM <= 5;
```
* **Expected Result:** Displays the first 5 employee rows (e.g. Steven King, Neena Kochhar) from the sample database.

---

### 🐘 PostgreSQL 18 Verification Commands

```powershell
# Check PostgreSQL Service & Port
Get-Service -Name postgresql*
Test-NetConnection -ComputerName 192.168.1.10 -Port 5432
```

---

**Document Maintained by:** System Administrator & Antigravity Agent  
**Last Updated:** August 2026  
