const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../config/db').pool;
const jwt = require('jsonwebtoken');

const router = express.Router();
const saltRounds = 10;

// !! IMPORTANTE: Use a mesma chave secreta definida no middleware !!
const JWT_SECRET = process.env.JWT_SECRET || 'suaChaveSecretaMuitoForteAqui'; // Substitua por uma chave segura

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

    // Login bem-sucedido: Gerar o token JWT
    const payload = {
        id: user.id,
        email: user.email,
        // Você pode adicionar mais dados ao payload se necessário, mas mantenha-o pequeno
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' }); // Token expira em 1 hora

    res.status(200).json({
        message: 'Login bem-sucedido!',
        token: token, // Retorna o token para o cliente
        user: { id: user.id, nome: user.nome, email: user.email } // Retorna dados do usuário também
    });

  } catch (error) {
    console.error('Erro no login:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao fazer login.' });
  }
});

module.exports = router; 