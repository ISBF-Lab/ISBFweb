# Development access and SSH forwarding

If direct access to `dev.isbf-one.com` stalls, use an SSH tunnel on the computer
running the browser. The server permits TCP forwarding. Substitute the SSH host
or alias already used to access the development server below.

1. Add `127.0.0.1 dev.isbf-one.com` to the local hosts file with administrator
   privileges (`/etc/hosts` on macOS/Linux, or
   `C:\Windows\System32\drivers\etc\hosts` on Windows).
2. Keep this local terminal command running, replacing `DEV_SSH_HOST`:

   ```sh
   ssh -NT -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 127.0.0.1:8443:127.0.0.1:443 DEV_SSH_HOST
   ```

3. Open `https://dev.isbf-one.com:8443/` with the existing development access
   credentials. Preserve this hostname so HTTPS certificates and Secure cookies
   work. Use a server IP or an SSH alias that does not resolve through the new
   hosts entry as the SSH destination.
4. When finished, press Ctrl+C and remove the hosts entry. If port 8443 is occupied,
   use another local port consistently in the command and browser URL.

Forwarding plain HTTP port 3000 is unsuitable for normal sign-in because the
development session cookie is Secure. The HTTPS origin including port 8443 was
verified with a successful synthetic development login. The user's local tunnel
is created by the local command; no tunnel is kept running by this documentation.

Development Caddy also compresses static frontend resources with this scoped
snippet, preserving its existing authentication and routing:

```caddyfile
@frontend_assets path /assets/* /stylesheets/* /theme-javascripts/* /extra-locales/* /svg-sprite/* /highlight-js/*
encode @frontend_assets zstd gzip
```

The measured fresh-browser transfer fell from approximately 19.5 MB to 5.3 MB,
with identical decoded JavaScript bytes. This is a development proxy change;
it does not establish a fix for every browser or network route.
