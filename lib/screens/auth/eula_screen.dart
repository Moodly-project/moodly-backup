import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/auth/api_key_setup_screen.dart'; // Importar a próxima tela

class EulaScreen extends StatelessWidget {
  const EulaScreen({super.key});

  final String eulaText = """
**Termos de Uso e Política de Privacidade - Moodly**

**Última atualização:** [2025/04/09]

Bem-vindo(a) ao Moodly! Ao usar nosso aplicativo, você concorda com estes termos.

**1. Coleta e Uso de Dados:**
   - **Dados de Humor:** Você insere dados sobre seus humores e observações associadas. Esses dados são armazenados localmente em seu dispositivo e enviados para nossa API segura para backup e processamento (ex: geração de relatórios).
   - **NÃO Coletamos Dados Pessoais Identificáveis:** Não coletamos seu nome real, endereço de e-mail (exceto para login/autenticação), ou outras informações que o identifiquem diretamente, a menos que você as forneça voluntariamente (por exemplo, no conteúdo das entradas do diário).
   - **Uso para Melhoria:** Podemos usar dados agregados e anonimizados (que não podem ser vinculados a você) para melhorar o aplicativo e seus recursos.

**2. Funcionalidade de IA (com API Externa):**
   - **Chave de API:** Para usar os recursos de análise de IA, você DEVE fornecer sua própria chave de API de um serviço de terceiros (como OpenAI GPT ou Google Gemini).
   - **Responsabilidade da Chave:** Você é responsável por obter e proteger sua chave de API. Os custos associados ao uso dessa chave são de sua inteira responsabilidade, de acordo com os termos do provedor da API.
   - **Envio de Dados para IA:** Ao usar a funcionalidade de IA, seus dados de humor e o conteúdo das entradas do diário (de forma anonimizada, se possível, dependendo da implementação) SERÃO enviados para o serviço de IA externo correspondente à sua chave de API para processamento.
   - **Privacidade da API Externa:** O uso dos seus dados pelo provedor de API externo é regido pela política de privacidade DESSE provedor. O Moodly não tem controle sobre como o provedor externo usa seus dados. Recomendamos que você leia a política de privacidade do provedor da API antes de fornecer sua chave.
   - **Moodly NÃO Armazena Respostas da IA:** As respostas e análises geradas pela IA externa não são armazenadas permanentemente pelo Moodly, apenas exibidas temporariamente no aplicativo.

**3. Segurança:**
   - Empregamos medidas de segurança razoáveis para proteger seus dados armazenados em nossa API (como criptografia e autenticação).
   - A segurança da sua chave de API externa e dos dados enviados para o provedor externo depende das práticas de segurança desse provedor e de como você gerencia sua chave.

**4. Suas Responsabilidades:**
   - Manter a segurança da sua conta e senha.
   - Fornecer informações precisas para login.
   - Gerenciar e proteger sua chave de API externa.
   - Usar o aplicativo de forma legal e ética.

**5. Limitação de Responsabilidade:**
   - O Moodly é fornecido "como está". Não garantimos que o aplicativo ou os insights da IA sejam sempre precisos, completos ou adequados para qualquer finalidade específica.
   - Não somos responsáveis por quaisquer custos, danos ou problemas decorrentes do uso da sua chave de API externa ou das respostas fornecidas pelo serviço de IA de terceiros.

**6. Alterações nos Termos:**
   - Podemos atualizar estes termos periodicamente. Notificaremos você sobre mudanças significativas. Seu uso continuado após as alterações constitui aceitação dos novos termos.

**7. Contato:**
   - Se tiver dúvidas, entre em contato conosco em [Inserir E-mail de Contato ou Link].

**Ao clicar em "Aceitar", você confirma que leu, entendeu e concorda com estes Termos de Uso e Política de Privacidade.**
"""; // Coloque o texto EULA aqui

  final _storage = const FlutterSecureStorage();

  Future<void> _acceptEula(BuildContext context) async {
    await _storage.write(key: 'eula_accepted', value: 'true');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ApiKeySetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso e Privacidade'),
        automaticallyImplyLeading: false, // Impede de voltar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(eulaText),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _acceptEula(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Botão largo
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white
              ),
              child: const Text('Li e Aceito os Termos'),
            )
          ],
        ),
      ),
    );
  }
}