# generate_dkim.ps1 - Pure Windows PowerShell 2048-bit RSA DKIM Key Generator

function Encode-Len([int]$len) {
    if ($len -lt 128) { 
        return [byte[]]@([byte]$len) 
    } elseif ($len -le 255) { 
        return [byte[]]@([byte]0x81, [byte]$len) 
    } else { 
        $b1 = [byte]($len -shr 8)
        $b2 = [byte]($len -band 0xFF)
        return [byte[]]@([byte]0x82, $b1, $b2) 
    }
}

function Encode-Int([byte[]]$bytes) {
    if ($bytes[0] -ge 128) { 
        $bytes = [byte[]]@([byte]0x00) + $bytes 
    }
    $lenBytes = Encode-Len $bytes.Length
    return [byte[]]@([byte]0x02) + $lenBytes + $bytes
}

function Encode-Seq([byte[]]$bytes) {
    $lenBytes = Encode-Len $bytes.Length
    return [byte[]]@([byte]0x30) + $lenBytes + $bytes
}

# 1. Generate 2048-bit RSA Key:
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider(2048)
$p = $rsa.ExportParameters($true)

# 2. Build PKCS#1 DER:
$der = Encode-Int ([byte[]]@([byte]0x00))
$der += Encode-Int $p.Modulus
$der += Encode-Int $p.Exponent
$der += Encode-Int $p.D
$der += Encode-Int $p.P
$der += Encode-Int $p.Q
$der += Encode-Int $p.DP
$der += Encode-Int $p.DQ
$der += Encode-Int $p.InverseQ
$privateDer = Encode-Seq $der

# 3. Format as PEM & Save Private Key:
$b64 = [Convert]::ToBase64String($privateDer, [System.Base64FormattingOptions]::InsertLineBreaks)
$pem = "-----BEGIN RSA PRIVATE KEY-----`r`n" + $b64 + "`r`n-----END RSA PRIVATE KEY-----"

$targetDir = "C:\Program Files (x86)\hMailServer\Data"
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
Set-Content -Path "$targetDir\dkim.private.key" -Value $pem -Encoding Ascii

# 4. Build Public Key (SPKI) for DNS:
$pubDer = Encode-Seq ((Encode-Int $p.Modulus) + (Encode-Int $p.Exponent))
$algId = [byte[]]@(0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00)
$bitStr = [byte[]]@(0x03) + (Encode-Len ($pubDer.Length + 1)) + [byte[]]@(0x00) + $pubDer
$spki = Encode-Seq ($algId + $bitStr)
$pubKey = [Convert]::ToBase64String($spki)

# 5. Remove old corrupted record if present, then add new one:
Remove-DnsServerResourceRecord -ZoneName "e6.local" -RRType "Txt" -Name "s1._domainkey" -Force -ErrorAction SilentlyContinue
Add-DnsServerResourceRecord -ZoneName "e6.local" -Txt -Name "s1._domainkey" -DescriptiveText "v=DKIM1; k=rsa; p=$pubKey" -ErrorAction Stop

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "✅ Real DKIM Private Key generated and saved to:" -ForegroundColor Green
Write-Host "   $targetDir\dkim.private.key" -ForegroundColor Yellow
Write-Host "✅ Real DKIM Public Key added to DNS at:" -ForegroundColor Green
Write-Host "   s1._domainkey.e6.local" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
