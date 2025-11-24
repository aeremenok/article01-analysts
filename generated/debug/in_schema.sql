-- Создание ENUM-типов
CREATE TYPE account_status AS ENUM ('активна', 'неактивна', 'заблокирована');
CREATE TYPE access_rights AS ENUM ('чтение', 'запись', 'полный доступ');
CREATE TYPE document_status AS ENUM ('активен', 'удален');
CREATE TYPE admin_role AS ENUM ('администратор', 'суперпользователь');
CREATE TYPE admin_status AS ENUM ('активен', 'неактивен');
CREATE TYPE session_status AS ENUM ('активна', 'завершена', 'истекла');
CREATE TYPE registry_status AS ENUM ('активен', 'архивирован');
CREATE TYPE notification_type AS ENUM ('системное', 'документы', 'другие');
CREATE TYPE notification_status AS ENUM ('ожидает', 'отправлено', 'ошибки');
CREATE TYPE privilege_status AS ENUM ('активна', 'неактивна');
CREATE TYPE operation_type AS ENUM ('вход', 'выход', 'создание', 'изменение', 'удаление');
CREATE TYPE search_result_status AS ENUM ('ожидает', 'выполнен', 'ошибка');

-- Таблица физических лиц
CREATE TABLE physical_persons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    birth_date DATE,
    passport_series_number VARCHAR(100),
    passport_issued_by TEXT,
    inn VARCHAR(50),
    snils VARCHAR(50),
    account_status account_status DEFAULT 'активна',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

-- Таблица персональных папок
CREATE TABLE personal_folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    physical_person_id UUID REFERENCES physical_persons(id) ON DELETE CASCADE,
    folder_path TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    access_rights access_rights DEFAULT 'чтение',
    status registry_status DEFAULT 'активна'
);

-- Таблица документов
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personal_folder_id UUID REFERENCES personal_folders(id) ON DELETE CASCADE,
    physical_person_id UUID REFERENCES physical_persons(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    file_type VARCHAR(100),
    size BIGINT,
    file_path TEXT NOT NULL,
    md5_hash VARCHAR(32),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status document_status DEFAULT 'активен',
    metadata JSONB
);

-- Таблица администраторов НКО
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    login VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    role admin_role DEFAULT 'администратор',
    status admin_status DEFAULT 'активен',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

-- Таблица сессий пользователей
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Может ссылаться на physical_persons или admins
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('physical_person', 'admin')),
    token VARCHAR(500) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status session_status DEFAULT 'активна'
);

-- Таблица реестров физических лиц
CREATE TABLE registries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    creator_id UUID REFERENCES admins(id) ON DELETE SET NULL,
    filter_parameters JSONB,
    sort_parameters JSONB,
    status registry_status DEFAULT 'активен'
);

-- Таблица уведомлений
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL, -- Может ссылаться на physical_persons или admins
    recipient_type VARCHAR(50) NOT NULL CHECK (recipient_type IN ('physical_person', 'admin')),
    subject VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    notification_type notification_type DEFAULT 'системное',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    status notification_status DEFAULT 'ожидает',
    user_preferences JSONB
);

-- Таблица прав доступа
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    privileges TEXT[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status privilege_status DEFAULT 'активна'
);

-- Таблица логов операций
CREATE TABLE operation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Может ссылаться на physical_persons или admins
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('physical_person', 'admin')),
    operation_type operation_type NOT NULL,
    operation_description TEXT NOT NULL,
    operation_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    data_before JSONB,
    data_after JSONB,
    success BOOLEAN DEFAULT TRUE
);

-- Таблица поисковых запросов
CREATE TABLE search_queries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Может ссылаться на physical_persons или admins
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('physical_person', 'admin')),
    query TEXT NOT NULL,
    search_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    results JSONB,
    result_count INTEGER,
    filter_parameters JSONB,
    sort_parameters JSONB,
    status search_result_status DEFAULT 'ожидает'
);

-- Индексы для оптимизации запросов
CREATE INDEX idx_physical_persons_email ON physical_persons(email);
CREATE INDEX idx_documents_personal_folder ON documents(personal_folder_id);
CREATE INDEX idx_documents_physical_person ON documents(physical_person_id);
CREATE INDEX idx_sessions_token ON sessions(token);
CREATE INDEX idx_sessions_user ON sessions(user_id, user_type);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, recipient_type);
CREATE INDEX idx_operation_logs_user ON operation_logs(user_id, user_type);
CREATE INDEX idx_operation_logs_operation_type ON operation_logs(operation_type);
CREATE INDEX idx_search_queries_user ON search_queries(user_id, user_type);
CREATE INDEX idx_search_queries_search_at ON search_queries(search_at);