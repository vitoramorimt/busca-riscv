param(
    [Parameter(Mandatory=$true)][string]$Ripes,
    [string]$Processor = 'RV32_5S'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $root "evidencias/ripes_$Processor"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Get-ChildItem (Join-Path $root 'benchmarks') -Filter '*.s' | Sort-Object Name | ForEach-Object {
    $out = Join-Path $dest ($_.BaseName + '.json')
    & $Ripes --mode cli --src $_.FullName -t asm --proc $Processor --iret --cycles --cpi --regs --runinfo --json --output $out
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) {
        throw "Falha no benchmark $($_.Name). Consulte a ajuda do Ripes."
    }
    Write-Host "Relatorio: $out"
}
