const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../config/db').pool;

const router = express.Router();
const saltRounds = 10;

// Rota de Registro (POST /api/auth/register)
router.post('/register', async (req, res) => {
  const { nome, email, senha } = req.body;

  if (!nome || !email || !senha) {
    return res.status(400).json({ message: 'Nome, email e senha são obrigatórios.' });
  }

  if (senha.length < 6) {
      return res.status(400).json({ message: 'A senha deve ter pelo menos 6 caracteres.' });
  }

  try {
    // Verificar se o email já existe
    const [existingUsers] = await db.query('SELECT id FROM usuarios WHERE email = ? AND deleted_at IS NULL', [email]);
    if (existingUsers.length > 0) {
      return res.status(409).json({ message: 'Email já cadastrado.' });
    }

    // Hash da senha
    const senhaHash = await bcrypt.hash(senha, saltRounds);

    // Inserir usuário no banco
    const [result] = await db.query(
      'INSERT INTO usuarios (nome, email, senha_hash) VALUES (?, ?, ?)',
      [nome, email, senhaHash]
    );

    res.status(201).json({ message: 'Usuário registrado com sucesso!', userId: result.insertId });

  } catch (error) {
    console.error('Erro no registro:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao registrar usuário.' });
  }
});

// Rota de Login (POST /api/auth/login)
router.post('/login', async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ message: 'Email e senha são obrigatórios.' });
  }

  try {
    // Buscar usuário pelo email (não deletado)
    const [users] = await db.query('SELECT id, nome, email, senha_hash FROM usuarios WHERE email = ? AND deleted_at IS NULL', [email]);

    if (users.length === 0) {
      return res.status(401).json({ message: 'Email ou senha inválidos.' }); // Usuário não encontrado
    }

    const user = users[0];

    // Comparar a senha fornecida com o hash armazenado
    const match = await bcrypt.compare(senha, user.senha_hash);

    if (!match) {
      return res.status(401).json({ message: 'Email ou senha inválidos.' }); // Senha incorreta
    }

    // Login bem-sucedido (aqui você pode gerar um token JWT, por exemplo)
    // Por agora, apenas retornamos uma mensagem de sucesso e dados básicos do usuário
    res.status(200).json({ message: 'Login bem-sucedido!', user: { id: user.id, nome: user.nome, email: user.email } });

  } catch (error) {
    console.error('Erro no login:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao fazer login.' });
  }
});

module.exports = router; 