# TokenShell

**TokenShell** is an ASPX-based impersonation shell designed for red team operations and post-exploitation. It allows authenticated process spawning under arbitrary credentials via `LogonUserA` and `CreateProcessAsUser`, redirecting the spawned process I/O over a raw TCP connection.
---
## Features

- Windows impersonation via supplied **username/password/domain**
- Socket-based **reverse shell** (connect-back)
- Pure .NET/Win32 API — no external binaries
- Minimal **ASPX web interface** for live interaction
- Runs within **IIS** (or other ASP.NET hosting environments)
---
## How It Works

1. Accepts credentials (`user`, `pass`, `domain`) via input form
2. Connects to a specified IP/port using `WSASocket/connect`
3. Spawns `cmd.exe` under the impersonated user
4. Redirects stdin/stdout/stderr to the connected socket
---
## Usage

1. Deploy `tokenshell.aspx` to a writable IIS directory
2. Browse to the page in your browser
3. Fill in:

   - **Username**
   - **Password**
   - **Domain**
   - **Remote IP** (listener)
   - **Remote Port**

4. Click **Connect and Spawn**
5. Catch the shell with something like:

   ```bash
   nc -lvnp 4444
   ```
---

## ⚠️Disclaimer
For educational and authorized testing only. Use only with explicit permission. The authors assume no liability for misuse.
Do not use it against systems you do not own or have explicit permission to test.

---

## Author

- :skull: **B5null**
