
$ErrorActionPreference = 'Stop'

# Загрузка параметров
$configPath = Join-Path $PSScriptRoot 'config.ps1'

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Не найден файл конфигурации: $configPath"
}

. $configPath

# Проверка целевой базы
if ($Database -ne 'pm07_v20') {
    throw "Неожиданное имя исходной базы: $Database"
}

if ($RestoreDatabase -ne 'pm07_v20_restore') {
    throw "Восстановление разрешено только в pm07_v20_restore."
}

if ($RestoreDatabase -eq $Database) {
    throw 'Исходная и целевая базы не должны совпадать.'
}

# Рабочие каталоги
$BackupDir = Join-Path $PSScriptRoot 'backups'
$OutputDir = Join-Path $PSScriptRoot 'out'
$LogDir = Join-Path $PSScriptRoot 'logs'

New-Item -ItemType Directory -Force -Path $OutputDir, $LogDir | Out-Null

$script:LogFile = Join-Path $LogDir 'restore.log'

function Write-Log {
    param([string]$Message)

    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message

    Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Invoke-SqlCmd {
    param([string]$Query)

    $result = & $Client -S $ServerInstance -E -b -V 16 -r 0 -h -1 -W -s '|' -Q $Query 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Ошибка SQLCMD (код $exitCode):`n$($result -join [Environment]::NewLine)"
    }

    return $result
}

function Invoke-Task {
    Write-Log 'Начало автоматизированного восстановления.'
    Write-Log "Исходная база: $Database"
    Write-Log "Целевая база: $RestoreDatabase"
    Write-Log "Дата параметра AsOf: $AsOf"

    # Проверка SQLCMD и каталогов
    if (-not (Test-Path -LiteralPath $Client -PathType Leaf)) {
        throw "Не найден SQLCMD.EXE: $Client"
    }

    if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
        throw "Не найден каталог резервных копий: $BackupDir"
    }

    if (-not (Test-Path -LiteralPath $RestoreDataDir -PathType Container)) {
        throw "Не найден каталог восстановления: $RestoreDataDir"
    }

    # Поиск последней резервной копии исходной базы
    $backup = Get-ChildItem -LiteralPath $BackupDir -Filter "$Database*.bak" -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $backup) {
        throw "Резервные копии базы $Database не найдены."
    }

    Write-Log "Выбрана резервная копия: $($backup.Name)"

    # Пути файлов восстановленной базы
    $mdfPath = Join-Path $RestoreDataDir "$RestoreDatabase.mdf"
    $ldfPath = Join-Path $RestoreDataDir "${RestoreDatabase}_log.ldf"

    # Формирование команды восстановления
    $backupPathSql = $backup.FullName.Replace("'", "''")
    $mdfPathSql = $mdfPath.Replace("'", "''")
    $ldfPathSql = $ldfPath.Replace("'", "''")

    $restoreQuery = @"
BEGIN TRY
    IF DB_ID(N'$RestoreDatabase') IS NOT NULL
        ALTER DATABASE [$RestoreDatabase]
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    RESTORE DATABASE [$RestoreDatabase]
    FROM DISK = N'$backupPathSql'
    WITH
        MOVE N'$LogicalData' TO N'$mdfPathSql',
        MOVE N'$LogicalLog' TO N'$ldfPathSql',
        REPLACE,
        RECOVERY;

    ALTER DATABASE [$RestoreDatabase] SET MULTI_USER;
END TRY
BEGIN CATCH
    IF DB_ID(N'$RestoreDatabase') IS NOT NULL
    BEGIN
        BEGIN TRY
            ALTER DATABASE [$RestoreDatabase] SET MULTI_USER;
        END TRY
        BEGIN CATCH
        END CATCH;
    END;

    THROW;
END CATCH;
"@

    Write-Log "Восстановление базы $RestoreDatabase."

    $restoreResult = Invoke-SqlCmd -Query $restoreQuery

    foreach ($line in $restoreResult) {
        if (-not [string]::IsNullOrWhiteSpace("$line")) {
            Write-Log "$line"
        }
    }

    Write-Log 'Восстановление завершено.'

    # Подсчёт записей в трёх таблицах
    $countQuery = @"
SET NOCOUNT ON;

SELECT 'clients' AS table_name, COUNT_BIG(*) AS row_count
FROM [$RestoreDatabase].dbo.clients
UNION ALL
SELECT 'masters', COUNT_BIG(*)
FROM [$RestoreDatabase].dbo.masters
UNION ALL
SELECT 'services', COUNT_BIG(*)
FROM [$RestoreDatabase].dbo.services;
"@

    $countResult = Invoke-SqlCmd -Query $countQuery

    $countLines = @(
        $countResult |
        ForEach-Object { "$_".Trim() } |
        Where-Object { $_ -ne '' }
    )

    $countFile = Join-Path $OutputDir 'restore-counts.txt'

    @('table_name|row_count') + $countLines |
        Set-Content -LiteralPath $countFile -Encoding UTF8

    Write-Log "Количество записей сохранено: $countFile"
    Write-Log "Использованная копия: $($backup.Name)"
    Write-Log "Восстановленная база: $RestoreDatabase"
    Write-Log 'Задача выполнена успешно.'
}

try {
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-Task
    $Timer.Stop()
    Write-Log "elapsed_ms=$($Timer.ElapsedMilliseconds)"
    exit 0
}

catch {
    $errorMessage = $_.Exception.Message

    Write-Host "ОШИБКА: $errorMessage" -ForegroundColor Red

    if ($script:LogFile) {
        $line = '{0} ERROR: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $errorMessage
        Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
    }

    exit 1
}
