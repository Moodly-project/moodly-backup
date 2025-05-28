-- Schema básico para o Moodly

CREATE DATABASE IF NOT EXISTS moodly_db;

USE moodly_db;

-- Tabela de Usuários
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL, -- Armazenar hash da senha
    foto_perfil_url VARCHAR(255) NULL, -- URL para a foto de perfil do usuário
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL -- Soft delete
);

-- Tabela de Entradas do Diário
CREATE TABLE IF NOT EXISTS entradas_diario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    conteudo TEXT NOT NULL,
    humor VARCHAR(50) NOT NULL, -- Ex: 'feliz', 'triste', 'ansioso'
    data_entrada DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL, -- Soft delete
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Índices para otimização (opcional, mas recomendado)
CREATE INDEX idx_usuario_email ON usuarios(email);
CREATE INDEX idx_entrada_usuario ON entradas_diario(usuario_id);
CREATE INDEX idx_entrada_data ON entradas_diario(data_entrada); 

select * from usuarios
select * from entradas_diario   