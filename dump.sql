PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS violation_event;
DROP TABLE IF EXISTS requirement_consequence;
DROP TABLE IF EXISTS requirement_process;
DROP TABLE IF EXISTS requirement;
DROP TABLE IF EXISTS reg_act;
DROP TABLE IF EXISTS reg_act_type;
DROP TABLE IF EXISTS consequence;
DROP TABLE IF EXISTS business_process;
DROP TABLE IF EXISTS branch;

CREATE TABLE branch (
    branch_id INTEGER PRIMARY KEY,
    branch_code TEXT NOT NULL UNIQUE,
    branch_name TEXT NOT NULL,
    region TEXT
);

CREATE TABLE reg_act_type (
    reg_act_type_id INTEGER PRIMARY KEY,
    type_name TEXT NOT NULL UNIQUE
);

CREATE TABLE reg_act (
    reg_act_id INTEGER PRIMARY KEY,
    reg_act_type_id INTEGER NOT NULL,
    act_title TEXT NOT NULL,
    act_number TEXT,
    act_version TEXT,
    effective_from DATE,
    effective_to DATE,
    FOREIGN KEY (reg_act_type_id) REFERENCES reg_act_type(reg_act_type_id)
);

CREATE TABLE requirement (
    requirement_id INTEGER PRIMARY KEY,
    reg_act_id INTEGER NOT NULL,
    requirement_code TEXT NOT NULL UNIQUE,
    requirement_title TEXT NOT NULL,
    requirement_text TEXT,
    status TEXT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (reg_act_id) REFERENCES reg_act(reg_act_id)
);

CREATE TABLE business_process (
    process_id INTEGER PRIMARY KEY,
    process_code TEXT NOT NULL UNIQUE,
    process_name TEXT NOT NULL
);

CREATE TABLE consequence (
    consequence_id INTEGER PRIMARY KEY,
    consequence_name TEXT NOT NULL UNIQUE,
    severity_level INTEGER
);

CREATE TABLE requirement_process (
    requirement_id INTEGER NOT NULL,
    process_id INTEGER NOT NULL,
    is_primary INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (requirement_id, process_id),
    FOREIGN KEY (requirement_id) REFERENCES requirement(requirement_id),
    FOREIGN KEY (process_id) REFERENCES business_process(process_id)
);

CREATE TABLE requirement_consequence (
    requirement_id INTEGER NOT NULL,
    consequence_id INTEGER NOT NULL,
    expected_impact_level INTEGER,
    PRIMARY KEY (requirement_id, consequence_id),
    FOREIGN KEY (requirement_id) REFERENCES requirement(requirement_id),
    FOREIGN KEY (consequence_id) REFERENCES consequence(consequence_id)
);

CREATE TABLE violation_event (
    violation_event_id INTEGER PRIMARY KEY,
    event_datetime DATETIME NOT NULL,
    branch_id INTEGER NOT NULL,
    process_id INTEGER NOT NULL,
    requirement_id INTEGER NOT NULL,
    detection_channel TEXT,
    is_blocked INTEGER NOT NULL DEFAULT 0,
    is_override INTEGER NOT NULL DEFAULT 0,
    override_reason TEXT,
    comment TEXT,
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id),
    FOREIGN KEY (process_id) REFERENCES business_process(process_id),
    FOREIGN KEY (requirement_id) REFERENCES requirement(requirement_id)
);

INSERT INTO branch (branch_id, branch_code, branch_name, region) VALUES
(1, 'MSK01', 'Московский филиал', 'Москва'),
(2, 'SPB01', 'Санкт-Петербургский филиал', 'Санкт-Петербург'),
(3, 'EKB01', 'Екатеринбургский филиал', 'Урал');

INSERT INTO reg_act_type (reg_act_type_id, type_name) VALUES
(1, 'Федеральный закон'),
(2, 'Акт Банка России'),
(3, 'Внутренняя инструкция');

INSERT INTO reg_act (reg_act_id, reg_act_type_id, act_title, act_number, act_version, effective_from, effective_to) VALUES
(1, 1, 'ФЗ о персональных данных', '152-ФЗ', '1.0', '2020-01-01', NULL),
(2, 2, 'Положение Банка России о комплаенсе', '742-П', '2.1', '2021-06-01', NULL),
(3, 3, 'Внутренний регламент работы с ПДн', 'VR-01', '1.3', '2022-03-01', NULL);

INSERT INTO business_process (process_id, process_code, process_name) VALUES
(1, 'BP01', 'Выдача кредита'),
(2, 'BP02', 'Предоставление выписки'),
(3, 'BP03', 'Открытие счета');

INSERT INTO consequence (consequence_id, consequence_name, severity_level) VALUES
(1, 'Штраф', 3),
(2, 'Приостановление операций', 4),
(3, 'Лишение лицензии', 5);

INSERT INTO requirement (requirement_id, reg_act_id, requirement_code, requirement_title, requirement_text, status, created_at, updated_at) VALUES
(1, 1, 'REQ_PD_01', 'Запрет передачи ПД третьим лицам без согласия',
 'Передача персональных данных допускается только при наличии законного основания или согласия субъекта.', 'Active',
 '2023-01-01 00:00:00', '2023-01-01 00:00:00'),
(2, 2, 'REQ_AUD_01', 'Обязательная фиксация операций',
 'Все операции должны быть зарегистрированы в журнале аудита согласно установленным правилам.', 'Active',
 '2023-01-01 00:00:00', '2023-01-01 00:00:00'),
(3, 3, 'REQ_DOC_01', 'Хранение документов не менее 5 лет',
 'Документы по клиентским операциям хранятся не менее 5 лет, если иное не установлено законом.', 'Active',
 '2023-01-01 00:00:00', '2023-01-01 00:00:00');

INSERT INTO requirement_process (requirement_id, process_id, is_primary) VALUES
(1, 1, 1),
(1, 2, 0),
(2, 1, 1),
(2, 2, 0),
(3, 3, 1);

INSERT INTO requirement_consequence (requirement_id, consequence_id, expected_impact_level) VALUES
(1, 1, 4),
(1, 2, 5),
(2, 1, 3),
(3, 1, 2),
(3, 2, 3);

INSERT INTO violation_event (violation_event_id, event_datetime, branch_id, process_id, requirement_id, detection_channel, is_blocked, is_override, override_reason, comment) VALUES
(1, '2024-01-10 10:15:00', 1, 1, 1, 'auto_check', 1, 0, NULL, 'Попытка передачи ПД'),
(2, '2024-02-12 12:00:00', 1, 1, 1, 'audit',     1, 0, NULL, 'Нарушение согласия'),
(3, '2024-03-15 09:30:00', 2, 2, 1, 'auto_check', 1, 1, 'Решение руководства', 'Override'),
(4, '2024-04-01 14:00:00', 2, 1, 2, 'audit',     0, 0, NULL, 'Не зафиксирована операция'),
(5, '2024-05-05 11:45:00', 3, 3, 3, 'auto_check', 1, 0, NULL, 'Нарушен срок хранения'),
(6, '2024-06-10 16:20:00', 1, 1, 1, 'complaint', 1, 0, NULL, 'Жалоба клиента'),
(7, '2024-07-20 10:10:00', 2, 2, 2, 'auto_check', 0, 0, NULL, 'Ошибка журнала'),
(8, '2024-08-30 13:40:00', 3, 3, 1, 'audit',     1, 0, NULL, 'Передача данных без основания');

COMMIT;