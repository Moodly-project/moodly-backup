require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./config/db');
const authRoutes = require('./routes/authRoutes'); // Importa as rotas de autenticação

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Habilita CORS para permitir requisições do frontend
app.use(express.json()); // Permite que o Express entenda JSON no corpo das requisições
app.use(express.urlencoded({ extended: true })); // Permite entender dados de formulário

// Teste da conexão com o banco de dados
db.testConnection();

// Rotas
app.get('/', (req, res) => {
  res.send('Bem-vindo à API do Moodly!');
});

app.use('/api/auth', authRoutes); // Usa as rotas de autenticação no prefixo /api/auth

// Tratamento de rotas não encontradas
app.use((req, res, next) => {
  res.status(404).send({ message: 'Rota não encontrada' });
});

// Tratamento de erros global
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send({ message: 'Erro interno do servidor' });
});

app.listen(port, () => {
  console.log(`Servidor rodando na porta ${port}`);
}); 