FROM alpine:3.20

# SQLite для работы с БД
RUN apk add --no-cache sqlite

# Рабочая директория
WORKDIR /app

# Кладем дамп в образ и создаем БД на этапе сборки
COPY dump.sql /app/dump.sql
RUN sqlite3 /app/compliance.db < /app/dump.sql

# Опционально: кладем запрос отчета как артефакт внутри образа
COPY request.sql /app/request.sql

# По умолчанию контейнер просто "живёт", чтобы можно было зайти внутрь и выполнять запросы
CMD ["sh", "-c", "echo 'DB is at /app/compliance.db'; tail -f /dev/null"]
