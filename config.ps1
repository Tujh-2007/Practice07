# Параметры исходной базы данных
$Database = 'pm07_v20'

# Экземпляр SQL Server
$ServerInstance = '.\SQLEXPRESS'

# Полный путь к SQLCMD.EXE
$Client = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE'

# Дата подготовки конфигурации
$AsOf = '2026-11-12'

# Параметры восстановления
$RestoreDatabase = 'pm07_v20_restore'
$RestoreDataDir = 'C:\Practice07\restore-data'

# Логические имена файлов из RESTORE FILELISTONLY
$LogicalData = 'pm07_v20'
$LogicalLog = 'pm07_v20_log'