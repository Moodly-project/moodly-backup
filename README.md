# Moodly: Seu Diário de Emoções Inteligente

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev) [![Node.js](https://img.shields.io/badge/Node.js-Backend-green.svg)](https://nodejs.org/) [![MySQL](https://img.shields.io/badge/MySQL-Database-orange.svg)](https://www.mysql.com/)

Moodly é um aplicativo Flutter que funciona como um diário pessoal para registrar suas emoções diárias. Ele permite visualizar padrões através de gráficos e, futuramente, obter insights e sugestões personalizadas utilizando Inteligência Artificial (através de uma API externa configurável pelo usuário).

## Sobre o Código

Este projeto é fruto de um esforço colaborativo e iterativo. O código foi construído combinando:

*   **Coleta de Repositórios:** Partes da estrutura e funcionalidades foram adaptadas de outros projetos e exemplos encontrados em nosso repositório.
*   **Inspiração Online:** Buscamos soluções e ideias em documentações, tutoriais e exemplos da comunidade Flutter e Node.js (um pouquinho de ctrl c ctrl v da web, e não pode faltar o uso de IA).
*   **Desenvolvimento Incremental:** O código foi sendo refinado e modificado ao longo do tempo com base nas necessidades e feedbacks.

O objetivo sempre foi criar um aplicativo funcional e visualmente agradável, mantendo a simplicidade onde possível.

## Funcionalidades Principais

*   **Diário de Emoções:** Registro diário de humor (Feliz, Ansioso, Calmo, etc.) com espaço para notas.
*   **Visualização de Dados:** Tela de relatórios com gráficos (Pizza, Barras) mostrando distribuição de humor e frequência.
*   **Autenticação:** Sistema de login e registro seguro (utilizando JWT).
*   **Integração com IA (Configurável):** Tela para exibir análises geradas por uma API externa (Google Gemini) configurada pelo usuário com sua própria chave.
*   **Fluxo de Configuração Inicial:** Solicitação de aceite de Termos de Uso e configuração da chave de API da IA no primeiro uso.

## Como Executar o Projeto

Siga os passos abaixo para configurar e rodar o Moodly localmente.

### Pré-requisitos

*   **Flutter SDK:** Certifique-se de ter o Flutter instalado e configurado corretamente. ([Guia de Instalação Flutter](https://docs.flutter.dev/get-started/install))
*   **Node.js e npm:** Necessários para executar o backend. ([Download Node.js](https://nodejs.org/))
*   **Servidor MySQL:** Você precisa de uma instância do MySQL rodando (localmente ou em um servidor). ([Download MySQL Community Server](https://dev.mysql.com/downloads/mysql/))
*   **Cliente MySQL:** Uma ferramenta para gerenciar o banco de dados, como MySQL Workbench, DBeaver, ou a linha de comando `mysql`.
*   **Chave de API de IA (Opcional, para funcionalidade completa):** Uma chave válida do Google Gemini ou OpenAI.

### 1. Configuração do Banco de Dados

1.  **Crie o Banco de Dados:** Use seu cliente MySQL para criar um novo banco de dados. O nome padrão usado no backend é `moodly_db`, mas você pode ajustar isso no código do backend se necessário.
    ```sql
    CREATE DATABASE IF NOT EXISTS moodly_db;
    ```
2.  **Execute o Schema:** Abra o arquivo `backend/schema.sql` no seu cliente MySQL (como o SQL Workbench). Isso criará as tabelas `usuarios` e `entradas_diario` necessárias.

### 2. Executando o Backend (Servidor Node.js)

1.  **Navegue até a Pasta:** Abra um terminal ou prompt de comando e navegue até a pasta `backend` do projeto:
    ```bash
    cd backend
    ```
2.  **Instale as Dependências:** Se for a primeira vez ou se as dependências mudaram, execute:
    ```bash
    npm install
    ```
    Isso instalará pacotes como `express`, `mysql2`, `cors`, `bcrypt`, `jsonwebtoken`, etc., definidos no `package.json` (certifique-se de que ele exista e esteja correto).
3.  **Configure as Credenciais do Banco:** **Importante:** Verifique no código do servidor backend (como `server.js`, `db.js` ou `config.js`) onde as credenciais de conexão com o banco de dados MySQL (host, usuário, senha, nome do banco) são definidas e ajuste-as para corresponder à sua configuração local.
4.  **Inicie o Servidor:** Execute o comando para iniciar o servidor. Pode ser um dos seguintes (verifique seu `package.json` ou o arquivo principal do servidor):
    ```bash
    npm start
    ```
    ou
    ```bash
    node server.js # (ou o nome do seu arquivo de entrada principal)
    ```
    O terminal deverá indicar que o servidor está rodando (geralmente na porta 3000).

### 3. Executando o Frontend (App Flutter)

1.  **Navegue até a Raiz:** Se você estava na pasta `backend`, volte para a pasta raiz do projeto.
2.  **Instale as Dependências Flutter:** Abra um terminal na raiz do projeto e execute:
    ```bash
    flutter pub get
    ```
3.  **Execute o Aplicativo:** Conecte um dispositivo ou inicie um emulador e execute:
    ```bash
    flutter run
    ```
4.  **Primeiro Acesso:** Ao iniciar pela primeira vez, o aplicativo solicitará que você aceite os Termos de Uso e, em seguida, configure sua chave de API de IA.
5.  **Uso Normal:** Após a configuração inicial, você será direcionado para a tela de Login/Registro.

## Como rodar o backend local e acessar pelo celular usando ngrok

Se você quer testar o app Flutter em um celular (ou em qualquer rede diferente do seu PC), siga este passo a passo para expor seu backend local usando o ngrok:

### 1. Instale o ngrok

Se ainda não instalou, rode:

```
npm install -g ngrok
```

### 2. Crie uma conta gratuita no ngrok

Acesse: https://dashboard.ngrok.com/signup

### 3. Pegue seu token de autenticação

Após criar a conta, copie o token que aparece no dashboard.

### 4. Autentique o ngrok no seu PC

Rode no terminal (substitua pelo seu token):

```
ngrok config add-authtoken SEU_TOKEN_AQUI
```

### 5. Inicie o backend normalmente

No diretório `backend`, rode:

```
npm run dev
```

### 6. Inicie o ngrok apontando para a porta do backend

No terminal, rode:

```
ngrok http 3000
```

Vai aparecer uma URL do tipo:

```
Forwarding https://xxxx-xx-xx-xxx-xx.ngrok-free.app -> http://localhost:3000
```

### 7. Atualize a URL da API no app Flutter

No arquivo `lib/services/api_config_service.dart`, altere a linha:

```
static const String _defaultUrl = 'https://xxxx-xx-xx-xxx-xx.ngrok-free.app/api';
```

Coloque a URL exata que o ngrok mostrou (ela muda toda vez que você reinicia o ngrok!).

### 8. Rode o app Flutter no celular

- Certifique-se de que o backend e o ngrok estão rodando.
- Rode o app no celular normalmente.
- O app vai acessar o backend via internet, mesmo em redes diferentes.

### Observações importantes
- Sempre que reiniciar o ngrok, a URL muda. Atualize no código e rode o app novamente.
- O backend precisa estar rodando antes de iniciar o ngrok.
- Se der erro de JSON ou aparecer HTML, provavelmente a URL do ngrok está errada ou o backend não está rodando.
- Você pode testar a URL do ngrok no navegador: `https://xxxx-xx-xx-xxx-xx.ngrok-free.app/api/health` deve mostrar `{"status":"ok","message":"Servidor está funcionando!"}`

---

Se tiver dúvidas, consulte este guia ou peça ajuda! ;)
