param(
  [int]$Port = 4173
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Address = [System.Net.IPAddress]::Parse("127.0.0.1")

$MimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".js" = "text/javascript; charset=utf-8"
  ".css" = "text/css; charset=utf-8"
  ".png" = "image/png"
  ".jpg" = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".webp" = "image/webp"
  ".svg" = "image/svg+xml"
  ".ico" = "image/x-icon"
}

function Send-Response {
  param(
    [System.Net.Sockets.NetworkStream]$Stream,
    [string]$Status,
    [string]$ContentType,
    [byte[]]$Body,
    [bool]$HeadOnly = $false
  )

  $Header = "HTTP/1.1 $Status`r`nContent-Type: $ContentType`r`nContent-Length: $($Body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
  $HeaderBytes = [System.Text.Encoding]::ASCII.GetBytes($Header)
  $Stream.Write($HeaderBytes, 0, $HeaderBytes.Length)

  if (-not $HeadOnly -and $Body.Length -gt 0) {
    $Stream.Write($Body, 0, $Body.Length)
  }
}

function Send-Text {
  param(
    [System.Net.Sockets.NetworkStream]$Stream,
    [string]$Status,
    [string]$Text,
    [bool]$HeadOnly = $false
  )

  $Body = [System.Text.Encoding]::UTF8.GetBytes($Text)
  Send-Response -Stream $Stream -Status $Status -ContentType "text/plain; charset=utf-8" -Body $Body -HeadOnly $HeadOnly
}

$Listener = [System.Net.Sockets.TcpListener]::new($Address, $Port)
$Listener.Start()

Write-Host "DawnRiseCamp homepage: http://127.0.0.1:$Port/"
Write-Host "Close this window to stop the local server."

try {
  while ($true) {
    $Client = $null
    $Stream = $null
    $Reader = $null
    $Client = $Listener.AcceptTcpClient()

    try {
      $Stream = $Client.GetStream()
      $Reader = [System.IO.StreamReader]::new($Stream, [System.Text.Encoding]::ASCII, $false, 8192, $true)
      $RequestLine = $Reader.ReadLine()

      if ([string]::IsNullOrWhiteSpace($RequestLine)) {
        Send-Text -Stream $Stream -Status "400 Bad Request" -Text "Bad request"
        continue
      }

      while ($true) {
        $Line = $Reader.ReadLine()
        if ($null -eq $Line -or $Line -eq "") {
          break
        }
      }

      $Parts = $RequestLine -split " "
      if ($Parts.Count -lt 2) {
        Send-Text -Stream $Stream -Status "400 Bad Request" -Text "Bad request"
        continue
      }

      $Method = $Parts[0].ToUpperInvariant()
      $HeadOnly = $Method -eq "HEAD"

      if ($Method -ne "GET" -and $Method -ne "HEAD") {
        Send-Text -Stream $Stream -Status "405 Method Not Allowed" -Text "Method not allowed" -HeadOnly $HeadOnly
        continue
      }

      $RequestPath = ($Parts[1] -split "\?")[0]
      $RequestPath = [System.Uri]::UnescapeDataString($RequestPath)

      if ($RequestPath -eq "/") {
        $RequestPath = "/index.html"
      }

      $RelativePath = $RequestPath.TrimStart("/", "\") -replace "/", [System.IO.Path]::DirectorySeparatorChar
      $FilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Root, $RelativePath))

      if (-not $FilePath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        Send-Text -Stream $Stream -Status "403 Forbidden" -Text "Forbidden" -HeadOnly $HeadOnly
        continue
      }

      if (-not [System.IO.File]::Exists($FilePath)) {
        Send-Text -Stream $Stream -Status "404 Not Found" -Text "Not found" -HeadOnly $HeadOnly
        continue
      }

      $Extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
      $ContentType = $MimeTypes[$Extension]
      if ([string]::IsNullOrWhiteSpace($ContentType)) {
        $ContentType = "application/octet-stream"
      }

      $Body = [System.IO.File]::ReadAllBytes($FilePath)
      Send-Response -Stream $Stream -Status "200 OK" -ContentType $ContentType -Body $Body -HeadOnly $HeadOnly
    }
    catch {
      if ($Stream) {
        Send-Text -Stream $Stream -Status "500 Internal Server Error" -Text "Server error"
      }
    }
    finally {
      if ($Reader) {
        $Reader.Dispose()
      }
      if ($Client) {
        $Client.Close()
      }
    }
  }
}
finally {
  $Listener.Stop()
}
