# 🌐 Step 3: Web Server (IIS) & Proxy Server (Reverse Proxy) Deep Dive

## 1. What is it? 🤔

### Web Server (IIS)
**Full Name:** Internet Information Services
**Definition:** Microsoft's enterprise web server that runs on Windows Server. It is responsible for serving HTTP/HTTPS web pages and web applications to clients over a network.
**🍕 Analogy:** Think of IIS as a **Restaurant Kitchen**. When a customer (browser) orders a meal (requests a webpage), the kitchen prepares the food (processes the request) and serves it to the customer.

### Reverse Proxy
**Definition:** A server that sits between clients and backend application servers, intercepting client requests and forwarding them to the appropriate backend. In IIS, this is achieved using **Application Request Routing (ARR)** and the **URL Rewrite** module.
**🛎️ Analogy:** Think of a reverse proxy as a **Hotel Receptionist**. When guests arrive or call with a request, the receptionist doesn't fulfill the request directly but routes it to the correct department (room service, housekeeping, concierge).

### Next.js & PM2
**Next.js:** A React-based web framework that can run as a standalone Node.js server. It provides server-side rendering (SSR) and modern web application capabilities.
**PM2:** A production process manager for Node.js applications.
**⚙️ Analogy:** PM2 is like a **Restaurant Manager** who ensures the kitchen staff (Next.js application) never stops working. If the application crashes, PM2 instantly restarts it, keeping it running 24/7.

---

## 2. Objective & Purpose 🎯

| Objective | Description |
| :--- | :--- |
| **Host Websites (IIS)** | Provide a platform to host static websites, dynamic web applications, and APIs. |
| **Virtual Hosting** | Allow multiple websites (e.g., `portfolio.e6.local`, `intranet.e6.local`) to run on a single server using different host headers or ports. |
| **Reverse Proxy Routing** | Forward external web traffic safely to internal backend servers (like Next.js on port 3000) without exposing them directly. |
| **SSL/TLS Termination** | Handle encryption and decryption centrally at the IIS level, offloading the CPU-intensive task from backend servers. |
| **Application Process Management** | Ensure modern Node.js applications stay alive in production, restarting them automatically upon failure (PM2). |

---

## 3. What Are They Used For? 🌍

1. **Corporate Intranet & Public Hosting:** Hosting company internal portals or public-facing marketing websites on `WIN-J17IMHCEMA9`.
2. **Modern Web Application Deployment:** Running complex, React-based web applications (like a student portfolio) built with Next.js, accessible via `portfolio.e6.local`.
3. **API Gateway:** Using the reverse proxy to route different URL paths to different backend microservices (e.g., `/api/v1` goes to Server A, `/api/v2` goes to Server B).
4. **Security & Load Distribution:** Hiding internal application architectures from the outside world and distributing traffic across multiple backend servers to prevent overload.

---

## 4. Advantages 🌟

| Advantage | Explanation |
| :--- | :--- |
| **Enhanced Security** | Backend servers (Node.js) are never exposed to the public internet. IIS handles the public exposure, filtering out malicious traffic before it reaches the app. |
| **Simplified SSL Management** | You only need to install SSL certificates on IIS. The internal traffic between IIS and the Next.js backend can remain unencrypted (HTTP), saving setup time and CPU overhead. |
| **Zero Downtime (PM2)** | Node.js apps can crash. PM2 monitors the process and restarts it in milliseconds if it fails, ensuring high availability. |
| **Resource Efficiency** | IIS can serve static files (images, CSS) very efficiently, while passing only complex dynamic requests to the backend Node.js server. |
| **Unified Access Point** | Users only need to remember one URL (`http://portfolio.e6.local`). The reverse proxy handles the complexity of knowing that the app is actually running on `localhost:3000`. |

---

## 5. What Happens WITH vs WITHOUT ⚖️

### ❌ WITHOUT Web Server
```text
[ Client: pro-win-client ]
      |
      v
[ Server: pro-win-server ] -> 🚫 NO IIS INSTALLED
      |
      +-> Browser gets "Site cannot be reached"
      +-> No platform to host web content
      +-> Cannot use port 80/443 for web traffic
```

### ✅ WITH Web Server (IIS)
```text
[ Client: pro-win-client ]
      | (HTTP Request on Port 80)
      v
[ Server: pro-win-server (192.168.1.10) ]
      |
      +-> [ IIS Web Server ] 
             |-> Intercepts Port 80
             |-> Logs request
             |-> Serves static files directly
```

### ❌ WITHOUT Reverse Proxy (App exposed directly)
```text
[ Client: pro-win-client ]
      |
      | (Must know the weird port)
      v
http://192.168.1.10:3000  <-- 🚨 Security Risk! 
      |                         Backend exposed directly.
      v                         No SSL! Cannot use port 80 easily.
[ Next.js App ]
```

### ✅ WITH Reverse Proxy (IIS + ARR)
```text
[ Client: pro-win-client ]
      |
      | (Clean URL: http://portfolio.e6.local)
      v
[ IIS on 192.168.1.10:80 ] <-- 🛡️ Shield/Proxy
      |
      | (ARR routes traffic internally)
      v
[ localhost:3000 ] <-- 🔒 Safe Backend
      |
      v
[ Next.js App managed by PM2 ]
```

---

## 6. How It Works Internally ⚙️

### How IIS Works Internally
When a request hits `WIN-J17IMHCEMA9` (192.168.1.10):
1. **HTTP.sys:** This kernel-level driver intercepts the network request on Port 80 (HTTP) or 443 (HTTPS).
2. **W3SVC (World Wide Web Publishing Service):** The service that looks at the request and determines which website it belongs to based on bindings (e.g., host header `portfolio.e6.local`).
3. **Application Pool (w3wp.exe):** An isolated worker process that actually executes the request.
4. **Modules:** The request passes through a pipeline of modules (Authentication, Logging, etc.) before returning a response.

### How Reverse Proxy Works Internally
1. Client requests `http://portfolio.e6.local`.
2. IIS intercepts it on Port 80.
3. The **URL Rewrite Module** checks its rules. It sees a rule saying "Send everything for this site to `http://localhost:3000`".
4. The **Application Request Routing (ARR) Module** acts as the forwarder, making a new HTTP request to the Next.js server on behalf of the client.
5. ARR adds **Proxy Headers** (like `X-Forwarded-For` with the client's IP, `192.168.1.100`) so the backend knows who the original user is.

### How the Full Stack Works Together in the Lab
```text
1. 🌐 Browser (CLIENT): User types http://portfolio.e6.local
        |
2. 🗺️ DNS: Resolves portfolio.e6.local -> 192.168.1.10
        |
3. 🚪 IIS (Port 80): W3SVC receives request, matches binding
        |
4. 🔄 ARR/Rewrite: "Ah, this is a proxy site! Route to port 3000."
        |
5. 💻 Backend: Request hits localhost:3000
        |
6. 🏃 PM2/Next.js: Generates the React HTML page
        |
7. ⏪ Response: Sends HTML back to ARR -> IIS -> Client
```

---

## 7. Full Abbreviation & Terminology Glossary 📚

| Term / Abbreviation | Full Form / Meaning | Description |
| :--- | :--- | :--- |
| **IIS** | Internet Information Services | Microsoft's web server software. |
| **HTTP** | HyperText Transfer Protocol | Unencrypted protocol for transferring web pages (Port 80). |
| **HTTPS** | HTTP Secure | Encrypted protocol for transferring web pages (Port 443). |
| **SSL / TLS** | Secure Sockets Layer / Transport Layer Security | Cryptographic protocols providing communications security. |
| **ARR** | Application Request Routing | IIS module that enables proxying and load balancing. |
| **URL Rewrite** | Uniform Resource Locator Rewrite | IIS module used to manipulate incoming URLs and route them. |
| **Reverse Proxy** | N/A | A server that retrieves resources on behalf of a client from backend servers. |
| **Forward Proxy** | N/A | A server that retrieves resources on behalf of internal clients from the internet. |
| **App Pool** | Application Pool | A group of URLs routed to a single worker process (w3wp.exe) for isolation. |
| **w3wp.exe** | IIS Worker Process | The actual Windows process that runs the website code. |
| **HTTP.sys** | HTTP Protocol Stack | Windows kernel-mode driver that listens for HTTP/HTTPS requests. |
| **W3SVC** | World Wide Web Publishing Service | Service managing HTTP.sys and App Pools. |
| **Node.js** | N/A | A JavaScript runtime built on Chrome's V8 JavaScript engine. |
| **Next.js** | N/A | A React framework for production-grade web applications. |
| **PM2** | Process Manager 2 | Advanced, production process manager for Node.js. |
| **NPM** | Node Package Manager | Default package manager for Node.js. |
| **React** | N/A | A JavaScript library for building user interfaces. |
| **SSR / CSR** | Server-Side Rendering / Client-Side Rendering | Where the webpage HTML is generated (Server vs Browser). |
| **Virtual Host** | N/A | Running multiple websites on a single server/IP. |
| **Binding** | N/A | The combination of IP, Port, and Hostname that IIS uses to identify a site. |
| **SNI** | Server Name Indication | Allows multiple SSL certificates to be hosted on a single IP address. |
