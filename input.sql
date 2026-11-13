-- Учебные исходные данные варианта 20. Открыть в пустой базе pm07_v20.
CREATE TABLE [clients] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [clients] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'clients 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'clients 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'clients 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'clients 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [masters] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [masters] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'masters 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'masters 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'masters 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'masters 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE [services] (
  id int PRIMARY KEY,
  name nvarchar(100) NOT NULL,
  event_at datetime2 NOT NULL,
  amount decimal(10,2) NOT NULL,
  link_id int NOT NULL,
  quantity int NOT NULL,
  expires_on date NOT NULL
);
INSERT INTO [services] (id,name,event_at,amount,link_id,quantity,expires_on) VALUES
(1, N'services 1', '2026-11-04 09:00:00', 10, 1, 1, '2026-11-10'),
(2, N'services 2', '2026-11-03 12:00:00', 20, 2, 2, '2026-11-20'),
(3, N'services 3', '2026-07-01 12:00:00', 30, 3, 3, '2026-11-07'),
(4, N'services 4', '2026-11-05 12:00:00', 40, 4, 4, '2026-12-10');

CREATE TABLE access_probe (id int PRIMARY KEY, value int NOT NULL);
INSERT INTO access_probe VALUES (1,10);


SELECT SERVERPROPERTY('IsIntegratedSecurityOnly')
	AS IsWindowAuthenticationOnly;

SELECT name, is_disabled, default_database_name
FROM sys.sql_logins
WHERE name = N'readonly';

EXEC sys.sp_readerrorlog
	0, 1, N'TLS';