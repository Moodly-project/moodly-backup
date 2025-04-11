const jwt = require('jsonwebtoken');

// !! IMPORTANTE: Use uma chave secreta forte e armazene-a de forma segura (ex: variáveis de ambiente) !!
const JWT_SECRET = process.env.JWT_SECRET || 'suaChaveSecretaMuitoForteAqui'; // Substitua por uma chave segura

function authenticateToken(req, res, next) {
  // Pega o token do header Authorization: Bearer TOKEN
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) {
    return res.sendStatus(401); // Se não há token, não autorizado
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      console.error('Erro na verificação do JWT:', err.message);
      return res.sendStatus(403); // Se o token não for válido, proibido
    }

    // Se o token for válido, anexa o payload decodificado (que contém o ID do usuário)
    // ao objeto req para uso nas rotas subsequentes
    req.user = user;
    next(); // Passa para a proxima rota
  });
}

module.exports = authenticateToken; 