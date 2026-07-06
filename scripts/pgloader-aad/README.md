# pgloader v4 + Azure AD (Entra ID) authentication

pgloader v4 links `mssql-jdbc`, which supports `authentication=ActiveDirectoryDefault`
and friends — **but** `azure-identity` and `msal4j` are declared
`<optional>true</optional>` in mssql-jdbc's own POM, so neither the shipped
container image nor the native `pgloader4` binary bundle them. Using AAD auth
as-is fails with `ClassNotFoundException: com.microsoft.aad.msal4j...` (or,
inside `SQLServerMSAL4JUtils`, `"Failed to load MSAL4J Java library"`).

## Native `pgloader4` binary (recommended)

If you installed the native `pgloader4` binary in WSL2 (rather than running
pgloader via podman), use this path — `migrate-endpoint.sh` already wires it
up automatically.

### One-time setup

```bash
# Downloads the exact 51-jar azure-identity/msal4j dependency tree straight
# from Maven Central into ~/.local/share/pgloader4-aad-libs. No Maven, no
# podman/Docker, no sudo required.
wsl bash -c "scripts/pgloader-aad/fetch-aad-libs.sh"

# Log in with your own Azure account (only needed once, or after the
# session expires)
az login
```

### Using it

In `.env`, set:

```
SQLSERVER_AUTH_MODE=aad
```

and leave `SQLSERVER_USER`/`SQLSERVER_PASSWORD` unset — they're ignored in
`aad` mode. `scripts/migrate-endpoint.sh` builds the source connection string
as:

```
jdbc:sqlserver://<host>:<port>;databaseName=<db>;authentication=ActiveDirectoryDefault;encrypt=true;trustServerCertificate=false
```

and, instead of calling `pgloader4` directly (which uses `java -jar` and thus
ignores any extra classpath entries), it invokes:

```
java -cp /opt/pgloader4/pgloader4.jar:$HOME/.local/share/pgloader4-aad-libs/* pgloader.cli ...
```

The pgloader jar **must** come first on the classpath — it bundles its own
modern slf4j-api/logback-classic, and the azure-identity/msal4j dependency
tree pulls in an older `slf4j-api-1.7.36.jar` transitively. If that older jar
is resolved first, SLF4J silently falls back to a no-op logger.

Override `PGLOADER4_JAR` / `PGLOADER4_AAD_LIBS_DIR` env vars if pgloader4 or
the fetched jars live somewhere non-default.

### Why `ActiveDirectoryDefault` and not `ActiveDirectoryInteractive`

`ActiveDirectoryInteractive` makes MSAL4J launch a system browser via
`xdg-open`, which fails in a headless WSL2 shell with
`AcquireTokenByInteractiveFlowSupplier failed: linux_xdg_open_failed` — WSL2
has no functioning `xdg-open`/browser integration for a JVM subprocess to
call.

`ActiveDirectoryDefault` instead uses Azure Identity's `DefaultAzureCredential`
chain, which falls back to `AzureCliCredential` — it just shells out to
`az account get-access-token` and parses the JSON response, so it works fine
even though `az` resolves to the Windows CLI via WSL interop
(`/mnt/c/Program Files/.../az`). As long as you're logged in (`az login` /
`az account show` succeeds), no browser popup is needed.

mssql-jdbc has **no built-in device-code auth mode** — `ActiveDirectoryDefault`
+ an existing `az login` session is the practical headless option in WSL2.

## Alternative: podman/container image

An alternative container-based setup (building a custom image with the same
jars baked in, plus a Linux-native `az login` stored in a podman volume) is
kept for reference:

- `Dockerfile` — extends `ghcr.io/dimitri/pgloader-v4:latest`, adds the AAD
  jars and Azure CLI.
- `pom.xml` — Maven manifest used to resolve the exact dependency graph
  (`fetch-aad-libs.sh` downloads the same resolved jar list directly from
  Maven Central, so Maven itself isn't required for the native path).
- `build.sh` — builds the image.
- `az-login.sh` — one-time `az login --use-device-code` into a named podman
  volume, since the Windows `az` CLI's DPAPI-encrypted token cache can't be
  read directly from inside a Linux container (this restriction is specific
  to containers reading the cache file — it does not apply to the native
  path above, which just invokes the `az` CLI as a subprocess).

This is no longer the primary path (the native binary is simpler to keep
updated), but still works if you'd rather not install `pgloader4` directly in
WSL2.

## Why not pass a raw access token instead?

mssql-jdbc's `accessToken` connection property (raw AAD token pass-through,
no azure-identity/msal4j needed) can only be set via the JDBC `Properties`
object in Java code — Microsoft's driver explicitly disallows it in the
connection URL string, and pgloader v4's `mssql.clj` only forwards
`user`/`password` as properties. So a token-passthrough shortcut isn't
reachable without patching pgloader's Clojure source; using the driver's own
`authentication=ActiveDirectoryDefault` mode is the supported path.

## Files

- `fetch-aad-libs.sh` — downloads the 51 azure-identity/msal4j jars from
  Maven Central for the native `pgloader4` path. **Start here.**
- `Dockerfile`, `pom.xml`, `build.sh`, `az-login.sh` — legacy podman-based
  alternative (see above).
