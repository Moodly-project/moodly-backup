import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/auth/api_key_setup_screen.dart';

class EulaScreen extends StatelessWidget {
  const EulaScreen({super.key});

  // EULA
  final String eulaText = """
Termos de Uso e Política de Privacidade - Moodly

Última atualização: 09 de abril de 2025

Bem-vindo ao Moodly! Ao utilizar nosso aplicativo, você concorda com os termos e condições descritos neste documento. Recomendamos que leia atentamente antes de prosseguir.

────────────────────────────────────────────────────

1. COLETA E USO DE DADOS

• Dados de Humor: O Moodly permite que você registre seus humores e observações associadas. Esses dados são armazenados localmente em seu dispositivo e enviados para nossa API segura para backup e processamento, como a geração de relatórios.

• Dados Pessoais: Não coletamos informações pessoais identificáveis, como nome real ou endereço de e-mail, a menos que você as forneça voluntariamente (por exemplo, no conteúdo das entradas do diário). Para fins de autenticação, podemos coletar seu endereço de e-mail.

• Uso para Melhoria: Dados agregados e anonimizados podem ser utilizados para aprimorar o aplicativo e seus recursos. Esses dados não podem ser vinculados a você individualmente.

────────────────────────────────────────────────────

2. FUNCIONALIDADE DE IA (COM API EXTERNA)

• Chave de API: Para acessar os recursos de análise de IA, é necessário fornecer uma chave de API de um serviço de terceiros, como OpenAI GPT ou Google Gemini.

• Responsabilidade da Chave: Você é responsável por obter, proteger e gerenciar sua chave de API. Todos os custos relacionados ao uso dessa chave são de sua responsabilidade, conforme os termos do provedor da API.

• Envio de Dados para IA: Ao utilizar a funcionalidade de IA, os dados de humor e o conteúdo das entradas do diário (anonimizados, quando possível) serão enviados ao serviço de IA externo correspondente à sua chave para processamento.

• Privacidade da API Externa: O uso dos seus dados pelo provedor da API externa é regido pela política de privacidade desse provedor. O Moodly não controla como esses dados são utilizados por terceiros. Recomendamos revisar a política de privacidade do provedor antes de fornecer sua chave.

• Armazenamento de Respostas da IA: As respostas e análises geradas pela IA externa não são armazenadas permanentemente pelo Moodly; elas são exibidas temporariamente no aplicativo.

────────────────────────────────────────────────────

3. SEGURANÇA

• Implementamos medidas de segurança adequadas para proteger os dados armazenados em nossa API.

• A segurança da sua chave de API externa e dos dados enviados ao provedor externo depende das práticas desse provedor e da forma como você gerencia sua chave.

────────────────────────────────────────────────────

4. RESPONSABILIDADES DO USUÁRIO

• Manter a segurança de sua conta e senha.

• Fornecer informações precisas para login e autenticação.

• Gerenciar e proteger sua chave de API externa.

• Utilizar o aplicativo de forma legal e ética.

────────────────────────────────────────────────────

5. LIMITAÇÃO DE RESPONSABILIDADE

• O Moodly é fornecido "no estado em que se encontra". Não garantimos que o aplicativo ou os insights gerados pela IA sejam sempre precisos, completos ou adequados para qualquer finalidade específica.

• Não nos responsabilizamos por custos, danos ou problemas decorrentes do uso da sua chave de API externa ou das respostas fornecidas pelo serviço de IA de terceiros.

────────────────────────────────────────────────────

6. ALTERAÇÕES NOS TERMOS

• Podemos atualizar este documento periodicamente. Você será notificado sobre mudanças significativas. O uso contínuo do aplicativo após as alterações implica aceitação dos novos termos.

────────────────────────────────────────────────────

7. CONTATO

• Para dúvidas ou suporte, entre em contato conosco em suporte@moodly.app.

────────────────────────────────────────────────────

Ao clicar em "Aceitar", você declara que leu, compreendeu e concorda com estes Termos de Uso e Política de Privacidade.
""";

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
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso e Privacidade'),
        automaticallyImplyLeading: false, // Impede de voltar
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    eulaText,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _acceptEula(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Li e Aceito os Termos',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Para mais informações, entre em contato com suporte@moodly.app')),
                );
              },
              child: Text(
                'Preciso de ajuda ou mais informações',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}