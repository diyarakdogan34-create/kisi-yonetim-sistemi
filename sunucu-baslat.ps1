$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot 'backend_api')
$pythonPath = Join-Path (Get-Location) '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonPath)) {
    py -m venv .venv
    if ($LASTEXITCODE -ne 0) { throw 'Python sanal ortami olusturulamadi.' }
    & $pythonPath -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Bagimliliklar kurulamadi.' }
}
& $pythonPath -m app.seed
if ($LASTEXITCODE -ne 0) { throw 'Ornek veriler hazirlanamadi.' }
& $pythonPath -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
