BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "cheats" (
	"id"	INTEGER NOT NULL,
	"command_id"	INTEGER NOT NULL,
	"description"	TEXT NOT NULL,
	"template"	TEXT NOT NULL,
	FOREIGN KEY("command_id") REFERENCES "commands"("id"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE VIRTUAL TABLE commands_fts USING fts5(
	id,
	name,
	description,
	language,
	content=commands,
	content_rowid=id,
	tokenize=porter
);
CREATE TABLE IF NOT EXISTS "commands_fts_data" (
	"id"	INTEGER,
	"block"	BLOB,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "commands_fts_idx" (
	"segid"	,
	"term"	,
	"pgno"	,
	PRIMARY KEY("segid","term")
) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS "commands_fts_docsize" (
	"id"	INTEGER,
	"sz"	BLOB,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "commands_fts_config" (
	"k"	,
	"v"	,
	PRIMARY KEY("k")
) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS "clu_metadata" (
	"key"	TEXT NOT NULL,
	"value"	TEXT NOT NULL,
	PRIMARY KEY("key")
);
CREATE TABLE IF NOT EXISTS "commands" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	"usage_command"	TEXT,
	"fallback_usage"	TEXT,
	"location"	TEXT,
	"type"	TEXT,
	"language"	TEXT,
	"source_url"	TEXT,
	"source_repo_url"	TEXT,
	"asciicast_url"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
INSERT INTO "commands_fts_data" ("id","block") VALUES (1,'');
INSERT INTO "commands_fts_data" ("id","block") VALUES (10,X'00000000000000');
INSERT INTO "commands_fts_config" ("k","v") VALUES ('version',4);
INSERT INTO "clu_metadata" ("key","value") VALUES ('db_version','2.0.0');
CREATE TRIGGER commands_fts_insert AFTER INSERT ON commands
BEGIN
    INSERT INTO commands_fts (rowid, name, description, language) VALUES (new.rowid, new.name, new.description, new.language);
END;
CREATE TRIGGER commands_fts_delete AFTER DELETE ON commands
BEGIN
    INSERT INTO commands_fts
	(commands_fts, rowid, name, description, language)
	VALUES
	('delete', old.rowid, old.name, old.description, old.language);
END;
CREATE TRIGGER commands_fts_update AFTER UPDATE ON commands
BEGIN
    INSERT INTO commands_fts
	(commands_fts, rowid, name, description, language)
	VALUES ('delete', old.rowid, old.name, old.description, old.language);
    INSERT INTO commands_fts
	(rowid, name, description, language)
	VALUES
	(new.rowid, new.name, new.description, new.language);
END;
COMMIT;
