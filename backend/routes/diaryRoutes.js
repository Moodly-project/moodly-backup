const express = require('express');
const db = require('../config/db').pool; // Assume que a conexão com o DB está configurada aqui
const authenticateToken = require('../middleware/authenticateToken'); // Middleware para verificar JWT

const router = express.Router();

// Helper function for date validation
const isValidDateFormat = (dateString) => {
  return /^\d{4}-\d{2}-\d{2}$/.test(dateString);
};

// Rota para buscar todas as entradas do diário do usuário logado
router.get('/', authenticateToken, async (req, res) => {
  const usuarioId = req.user.id; // ID do usuário obtido do token JWT

  try {
    const [rows] = await db.query(
      'SELECT id, conteudo, humor, data_entrada FROM entradas_diario WHERE usuario_id = ? AND deleted_at IS NULL ORDER BY data_entrada DESC, created_at DESC',
      [usuarioId]
    );
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar entradas do diário:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao buscar entradas.' });
  }
});

// Rota para adicionar uma nova entrada no diário
router.post('/', authenticateToken, async (req, res) => {
  const usuarioId = req.user.id;
  const { conteudo, humor, data_entrada } = req.body; // data_entrada deve estar no formato 'YYYY-MM-DD'

  if (!conteudo || !humor || !data_entrada) {
    return res.status(400).json({ message: 'Conteúdo, humor e data são obrigatórios.' });
  }

  // Validação básica do formato da data
  if (!isValidDateFormat(data_entrada)) {
     return res.status(400).json({ message: 'Formato de data inválido. Use YYYY-MM-DD.' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO entradas_diario (usuario_id, conteudo, humor, data_entrada) VALUES (?, ?, ?, ?)',
      [usuarioId, conteudo, humor, data_entrada]
    );
    res.status(201).json({ message: 'Entrada adicionada com sucesso!', insertId: result.insertId });
  } catch (error) {
    console.error('Erro ao adicionar entrada no diário:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao adicionar entrada.' });
  }
});

// Rota para atualizar uma entrada existente (soft delete)
// Nota: Geralmente o ID da entrada vem pela URL (ex: /api/diary/123)
router.put('/:id', authenticateToken, async (req, res) => {
  const usuarioId = req.user.id;
  const entryId = req.params.id;
  const { conteudo, humor, data_entrada } = req.body;

  if (!conteudo || !humor || !data_entrada) {
    return res.status(400).json({ message: 'Conteúdo, humor e data são obrigatórios para atualização.' });
  }
   if (!isValidDateFormat(data_entrada)) {
     return res.status(400).json({ message: 'Formato de data inválido. Use YYYY-MM-DD.' });
  }

  try {
    // Verificar se a entrada pertence ao usuário
    const [check] = await db.query('SELECT id FROM entradas_diario WHERE id = ? AND usuario_id = ? AND deleted_at IS NULL', [entryId, usuarioId]);
    if (check.length === 0) {
        return res.status(404).json({ message: 'Entrada não encontrada ou não pertence a este usuário.' });
    }

    const [result] = await db.query(
      'UPDATE entradas_diario SET conteudo = ?, humor = ?, data_entrada = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND usuario_id = ?',
      [conteudo, humor, data_entrada, entryId, usuarioId]
    );

    if (result.affectedRows > 0) {
      res.json({ message: 'Entrada atualizada com sucesso!' });
    } else {
      // Isso não deveria acontecer devido à verificação anterior, mas é bom ter
      res.status(404).json({ message: 'Entrada não encontrada ou não pôde ser atualizada.' });
    }
  } catch (error) {
    console.error('Erro ao atualizar entrada no diário:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao atualizar entrada.' });
  }
});


// Rota para deletar uma entrada (soft delete)
router.delete('/:id', authenticateToken, async (req, res) => {
  const usuarioId = req.user.id;
  const entryId = req.params.id;

  try {
    // Usar soft delete: marcar como deletado sem remover do banco
    const [result] = await db.query(
      'UPDATE entradas_diario SET deleted_at = CURRENT_TIMESTAMP WHERE id = ? AND usuario_id = ? AND deleted_at IS NULL',
      [entryId, usuarioId]
    );

    if (result.affectedRows > 0) {
      res.json({ message: 'Entrada excluída com sucesso (soft delete).' });
    } else {
      res.status(404).json({ message: 'Entrada não encontrada, já excluída ou não pertence a este usuário.' });
    }
  } catch (error) {
    console.error('Erro ao deletar entrada do diário:', error);
    res.status(500).json({ message: 'Erro interno do servidor ao deletar entrada.' });
  }
});

module.exports = router; 