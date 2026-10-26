# Home Assistant on the home rpi

HAOS (Home Assistant OS) on a Raspberry Pi 4 at `192.168.1.122`.
Everything learned while setting it up, so it doesn't have to be rediscovered.
Written for HAOS 18.x — the `ha` CLI and container naming changed recently, see
[Gotchas](#gotchas) before trusting older blog posts.

## Getting in (3 doors)

| Door | Command | Notes |
|---|---|---|
| **HAOS host** (dropbear) | `ssh hass` (= `root@192.168.1.122:22222`) | Key auth, full root on the host OS. The `hass`/`hassio` alias lives in `~/.ssh/config`. |
| **SSH & Web Terminal add-on** | `ssh hassio@192.168.1.122` (port 22) | Username `hassio` (this is where the "hassio user" folklore comes from). Auth = password / `authorized_keys` configured *in the add-on UI*, not host keys. Currently trusts only an old laptop key. |
| **Web UI** | `https://homeassistant.tail203e7d.ts.net:8123` | See HTTPS section. |

- Port 22 (OpenSSH) = the *Advanced SSH & Web Terminal* add-on.
- Port 22222 (dropbear) = the *HAOS host* SSH. Distinct daemons, distinct auth.
- `pi` user does not exist on HAOS.

## Tailscale

- The box runs the **Tailscale add-on** (community repo, same repo as the SSH
  add-on) in **userspace mode**: the add-on proxies tailnet traffic to the host,
  so no `tun` device is needed.
- It lives on the **home tailnet** (`tail203e7d.ts.net`), reachable as
  `homeassistant.tail203e7d.ts.net` (tailnet IP `100.65.17.116`).
- `orek` (and possibly other machines) carries **two Tailscale profiles** — the
  work tailnet is the active one, so the HA box shows as offline/absent until
  you `tailscale switch` to the home profile. This is expected, not a breakage.
- `tailscale cert` **must run on the node itself** — certs cannot be fetched
  from another tailnet device. The binary inside the add-on container is at
  `/opt/tailscale` (not on `$PATH`).

## HTTPS (how it's currently set up)

Real Let's Encrypt cert for `homeassistant.tail203e7d.ts.net` via Tailscale's
built-in cert provisioning (free, no domain purchase, no port forwarding, not
exposed to the internet). Prerequisite: **HTTPS toggled on** in the tailnet's
admin console under DNS.

Cert files on the host:

```
/mnt/data/supervisor/ssl/tsnet.crt   # fullchain (Let's Encrypt, 90 days)
/mnt/data/supervisor/ssl/tsnet.key
```

Paths visible *inside* the HA container as `/ssl/…`; host prefix is
`/mnt/data/supervisor/`.

### The trap: `http:` config exists in TWO places

Recent HA versions let you configure HTTP in the UI, which is stored in
`.storage/http` — and **`.storage` silently overrides `configuration.yaml`**.
Editing only the YAML and restarting changes *nothing*. Both must agree:

- `/mnt/data/supervisor/homeassistant/configuration.yaml` → `ssl_certificate: /ssl/tsnet.crt`
- `/mnt/data/supervisor/homeassistant/.storage/http` → same paths

**`.storage` must only be edited while core is stopped** (HA caches it in
memory and rewrites it on shutdown):

```sh
ssh hass 'ha core stop'                    # wait until stopped
# ...edit .storage/http (keep a backup)...
ssh hass 'ha core start'
```

Backups from the original setup are saved as `*.bak-ssl-20261026` next to both
files. The old self-signed cert (`server.crt`/`server.key`, "Home Tech Root
CA") is still in `/ssl`, unreferenced.

### Renewal (nothing auto-renews!)

```sh
ssh hass /mnt/data/supervisor/ssl-renew.sh
```

Re-runs `tailscale cert`, copies to `/ssl`, and restarts core **only if the
cert changed**. Run every ~2 months, or wire it into the SSH add-on's
`init_commands` so it refreshes on boot/update.

### Access notes

- `https://homeassistant.tail203e7d.ts.net:8123` — the good URL. Works from
  any device on the home tailnet, no browser warnings.
- `https://192.168.1.122:8123` — works but shows a name-mismatch warning
  (cert is for the ts.net name, not the IP). Expected.
- Plain HTTP on 8123 is disabled once `ssl_*` is configured.

## Gotchas

| Gotcha | Reality |
|---|---|
| "Just docker exec" | The HAOS host has **no `docker` CLI** (and no `openssl`). But the daemon socket `/var/run/docker.sock` is there — drive it with `curl --unix-socket`. |
| Container names | Not `addon_*` anymore: they're `app_a0d7b954_tailscale`, `app_a0d7b954_ssh`, `homeassistant`, `hassio_supervisor`, etc. |
| `ha addons options …` | **Doesn't exist** in the HAOS 18 `ha` CLI (add-on config is UI-only; the CLI was rebranded to `ha apps` with no config subcommand). |
| Executing in an add-on | `ha` CLI has no exec. Use the Docker API (below), or the add-on's own ingress terminal. |
| Old instructions online | Most tutorials predate HAOS 18 — check `ha --help` before trusting CLI syntax. |
| DNS on the host | The host (and containers other than via the add-on's dnsmasq proxy) **cannot resolve `*.ts.net`**. Test tailnet URLs from a tailnet client, not from the box. |
| Restarts are slow | `ha core stop/start` takes ~30-60 s on the Pi. Run via `nohup … &` over SSH so a 30 s tool timeout doesn't kill it mid-way, then poll. |

### Exec into any container from the host shell (no docker CLI)

```sh
# run a command in a container; $1 = container, $2 = JSON argv array
dexec() {
  EID=$(curl -s --unix-socket /var/run/docker.sock -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"AttachStdout\":true,\"AttachStderr\":true,\"Tty\":true,\"Cmd\":$2}" \
    http://localhost/v1.55/containers/$1/exec | sed 's/.*"Id":"\([^"]*\)".*/\1/')
  curl -s --unix-socket /var/run/docker.sock -X POST \
    -H 'Content-Type: application/json' -d '{"Detach":false,"Tty":true}' \
    http://localhost/v1.55/exec/$EID/start
}

dexec app_a0d7b954_tailscale '["/opt/tailscale","status","--json"]'
```

`Tty:true` merges stderr into stdout and emits `\r\n` — pipe through
`tr -d '\r'` when saving file output.

### Issuing / renewing the tailnet cert by hand

```sh
dexec app_a0d7b954_tailscale '["/opt/tailscale","cert","--cert-file","/tmp/ha.crt","--key-file","/tmp/ha.key","homeassistant.tail203e7d.ts.net"]'
# "does not support getting TLS certs" → HTTPS not enabled in the tailnet admin console
dexec app_a0d7b954_tailscale '["sh","-c","cat /tmp/ha.crt"]' | tr -d '\r' > /mnt/data/supervisor/ssl/tsnet.crt
```

Issuance can take >30 s (ACME) — the command may need to outlive your SSH
session timeout; check for `/tmp/ha.crt` afterwards.

## SSH quoting notes (for agents)

Nested `ssh host 'sh -s' <<'EOF' … EOF` heredocs are far more reliable than
quoting JSON argv inline — word-splitting mangles `["sh","-c","cat /tmp/x"]`
unless every layer is quoted exactly right.
