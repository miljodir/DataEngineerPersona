# =============================================================================
# Extends ghcr.io/dimitri/pgloader-v4 with Azure AD (Entra ID) authentication
# support for connecting to Azure SQL.
#
# Why this is needed:
#   pgloader-v4's shipped uberjar links mssql-jdbc 12.6.1.jre11, whose
#   "authentication=ActiveDirectory*" modes need azure-identity + msal4j on
#   the classpath. Both are declared <optional>true</optional> in
#   mssql-jdbc's own POM, so the stock pgloader-v4 image does NOT bundle
#   them — using authentication=ActiveDirectoryDefault fails with
#   ClassNotFoundException / NoClassDefFoundError. This image adds:
#     1. azure-identity 1.11.1 + msal4j 1.14.1 (and their transitive deps),
#        resolved via Maven so the dependency graph is exactly right, mounted
#        onto the runtime classpath via a custom entrypoint.
#     2. The Azure CLI, so azure-identity's DefaultAzureCredential chain can
#        fall back to AzureCliCredential and reuse an existing `az login`
#        session (see az-login.sh in this folder for the one-time login).
#
# Build:
#   wsl bash -c "cd scripts/pgloader-aad && ./build.sh"
# =============================================================================

FROM docker.io/library/maven:3.9-eclipse-temurin-21 AS aad-libs
WORKDIR /build
COPY pom.xml .
RUN mvn -B -q dependency:copy-dependencies -DoutputDirectory=/build/lib -DincludeScope=runtime

FROM ghcr.io/dimitri/pgloader-v4:latest
USER root

# Azure CLI (official Microsoft install script) so AzureCliCredential works
# inside the container against a volume-mounted `az login` session.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates apt-transport-https lsb-release gnupg \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

COPY --from=aad-libs /build/lib /opt/aad-libs
# The base image's "pgloader" user has no home directory created, so
# az/azure-identity (both HOME-dependent) fail with PermissionError. Create
# it -- and pre-create .azure -- so podman's volume-mount ownership
# inheritance (copy-up on first mount) makes the AAD login volume writable
# too, even when the container later runs with --userns=keep-id --user.
# world-writable (0777): migrate-endpoint.sh runs this image with
# --userns=keep-id --user "$(id -u):$(id -g)" so it can write to the
# host-bind-mounted /tmp, which means the process uid here is the *host*
# user, not the image's uid-999 "pgloader" -- chmod 777 lets either write.
RUN mkdir -p /home/pgloader/.azure \
    && chown -R pgloader:pgloader /opt/aad-libs /home/pgloader \
    && chmod -R 0777 /home/pgloader

USER pgloader
ENV HOME=/home/pgloader

# Same Main-Class as the stock image's `pgloader` wrapper (pgloader.cli), but
# with azure-identity/msal4j prepended to the classpath.
# pgloader.jar bundles its own logback-classic + a modern slf4j-api. It must
# come FIRST on the classpath: /opt/aad-libs pulls in an older slf4j-api
# transitively (via msal4j's deps), and if that shadows pgloader.jar's own
# copy, SLF4J falls back to a no-op logger (logback silently stops working).
ENTRYPOINT ["java", "-cp", "/app/pgloader.jar:/opt/aad-libs/*", "pgloader.cli"]
CMD ["--help"]
