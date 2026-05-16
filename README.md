# Routine-Documents

## Local preview

Open this site through the local server instead of double-clicking `index.html`.
Direct `file://` previews can trigger browser security errors because local files are treated as separate origins.

On Windows, run:

```bat
start-site.bat
```

This starts a local PowerShell server and opens:

```text
http://127.0.0.1:4173/
```

Or run either server manually:

```bat
PowerShell -NoProfile -ExecutionPolicy Bypass -File server.ps1
```

```bat
node server.js
```
