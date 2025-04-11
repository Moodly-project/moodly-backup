require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',       // Usuário do MySQL
  password: process.env.DB_PASSWORD || '', // Senha do seu MySQL
  database: process.env.DB_NAME || 'moodly_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('Conexão com o banco de dados MySQL bem-sucedida!');
    connection.release();
  } catch (error) {
    console.error('Erro ao conectar com o banco de dados:', error);
    process.exit(1); // Encerra a aplicação se não conseguir conectar
  }
}

module.exports = {
    pool,
    testConnection
}; 