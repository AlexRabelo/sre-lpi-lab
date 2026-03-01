# AWS Local Lab: Amazon Linux 2023 no VirtualBox

[Arquitetura do Projeto](./doc/images/esquema.png)

Estudar para certificações Linux como a LPI exige prática agressiva em ambientes reais. O escopo das provas força o domínio de duas arquiteturas distintas. A família Debian e a família Red Hat.

A primeira opção possui uma resolução simples. A subida de uma máquina virtual com Debian ou Ubuntu nos dá um ambiente necessário para teoria e práticas do ecossistema apt. O problema real atinge a segunda opção do laboratório.

A mudança estrutural na distribuição CentOS pulverizou o ambiente de testes padrão do tipo Red Hat. A comunidade de infraestrutura precisou buscar saídas. O mercado reagiu com ramificações robustas. Projetos como Rocky Linux e AlmaLinux entregam clones perfeitos do código original. O Oracle Linux introduz uma engenharia focada em performance corporativa na mesma base. A própria REDHAT criou o programa Red Hat Developer, que distribui licenças gratuitas do sistema oficial para uso individual. Todas são ferramentas primorosas de simulação.

A nossa escolha para esta questão ignora essas rotas tradicionais. Optamos pela implantação local do Amazon Linux 2023 (AL2023). Ele adota os mesmos padrões técnicos cobrados nas provas e traz um outro benefício, é o sistema padrão da AWS. Você estuda para a sua certificação (LPI) e domina o ecossistema da maior provedora de nuvem ao mesmo tempo.

O desafio é que a AWS **não fornece um instalador amigável**. Eles entregam um disco bruto de nuvem que não sabe qual é a sua senha. Este repositório resolve esse problema. Ele automatiza a injeção de credenciais para que você rode o sistema localmente no VirtualBox, sem custo algum. Você tem um sistema operacional completo e autossuficiente. A máquina conecta nos repositórios oficiais da Amazon, executa atualizações nativas e entrega um ambiente de nuvem perfeito para a prática dos seus estudos

## 🛠️ Ferramentas Necessárias

Antes de começar, certifique-se de ter os seguintes itens na sua máquina:

1. **Windows 11**: O sistema hospedeiro.
2. **WSL (Ubuntu)**: O subsistema Linux dentro do Windows. [Veja como instalar aqui](https://learn.microsoft.com/pt-br/windows/wsl/install).
3. **VirtualBox**: O virtualizador gratuito. [Baixe a versão mais recente aqui](https://www.virtualbox.org/wiki/Downloads).

## 🚀 Guia Passo a Passo

### Passo 1: A Extração do Disco Base

A imagem oficial da AWS chega empacotada. Precisamos isolar o disco rígido virtual.

1. Acesse o [Repositório Oficial da AWS](https://cdn.amazonlinux.com/al2023/os-images/latest/vmware/) e baixe a imagem com extensão `.ova`.
2. Abra o terminal **PowerShell** no Windows 11.
3. Navegue até o diretório de download e acione o comando nativo de extração.

~~~powershell
tar -xf nome-do-arquivo-baixado.ova
~~~

O processo expõe o arquivo `.vmdk`. Guarde-o. Ele será o disco central do servidor.

### Passo 2: A Compilação do Cloud-Init

Sistemas nativos de nuvem procuram um CD virtual durante o primeiro boot. Eles leem esse disco para descobrir as credenciais de acesso. Criaremos essa imagem agora.

1. Abra o terminal do **WSL (Ubuntu)**.
2. Baixe este projeto para o seu ambiente local.

~~~bash
git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
cd SEU_REPOSITORIO
~~~

3. A pasta contém os textos de configuração `user-data` (senha de acesso) e `meta-data` (nome da máquina). Execute a automação que transforma esses textos em disco ótico.

~~~bash
chmod +x gerar_seed.sh
./gerar_seed.sh
~~~

A ferramenta compila o arquivo `seed.iso` instantaneamente na raiz do seu diretório.

### Passo 3: A Montagem do Hardware Virtual

As peças estão soltas. Vamos conectá-las na interface do hypervisor.

1. Inicie o VirtualBox e clique em **Novo**.
2. Nomeie a máquina como "Amazon Linux 2023". Defina o tipo como "Linux" e a versão como "Red Hat (64-bit)".
3. Especifique um mínimo de 2048 MB de memória RAM e 2 núcleos de processamento.
4. Na configuração de Disco Rígido, aborte a criação automática. Selecione a opção "Utilizar um arquivo de disco rígido virtual existente". Aponte o caminho para o arquivo `.vmdk` revelado no Passo 1 e conclua o assistente.
5. Clique com o botão direito sobre a máquina criada e acesse **Configurações > Armazenamento**.
6. Localize a Controladora IDE. Clique no ícone de CD vazio. No painel de detalhes à direita, clique no ícone de disco e escolha "Escolher um arquivo de disco". Selecione o arquivo `seed.iso` gerado no Passo 2. 
7. Acesse a aba **Rede** na coluna lateral esquerda. Altere o campo "Conectado a:" de *NAT* para *Placa em Modo Bridge* (Bridged Adapter). Isso garante que a máquina ganhe um IP da sua rede doméstica e o seu Windows consiga enxergá-la.
8. Confirme as alterações e inicie a máquina virtual.

### Passo 4: O Login e o Desbloqueio de SSH

A máquina consumirá a ISO e levantará os serviços base. A tela de terminal do VirtualBox exigirá suas credenciais de entrada:

- **Usuário:** `ec2-user`
- **Senha:** `AwsLinux2023!`

A arquitetura AWS possui bloqueios nativos. O acesso remoto via SSH com senha é rejeitado. Precisamos derrubar esse escudo temporariamente para enviar nossas chaves criptográficas. Digite os dois comandos abaixo na tela preta do VirtualBox.

~~~bash
echo "PasswordAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/99-custom-ssh.conf
sudo systemctl restart sshd
~~~

### Passo 5: Geração de Chaves e Configuração de Acesso

Servidores de produção recusam senhas. Eles exigem chaves assimétricas pareadas. Adotaremos o padrão corporativo para mapear um atalho veloz no sistema operacional hospedeiro.

1. Retorne para o terminal **PowerShell** no Windows 11.
2. Crie a sua identidade criptográfica. Aceite todas as opções padrão pressionando Enter.

~~~powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519" -N ""
~~~

3. Descubra o IP da máquina virtual (digite `ip a` no terminal do VirtualBox). Envie a chave pública para o servidor. Substitua o campo `IP_DA_SUA_VM` pelo endereço correto. O sistema pedirá a senha temporária para autorizar a operação.

~~~powershell
$pubKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
ssh ec2-user@IP_DA_SUA_VM "mkdir -p ~/.ssh && echo '$pubKey' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
~~~

4. Construa o atalho de rede. O script abaixo ensina o Windows a conectar na máquina usando uma palavra simples. Modifique o IP novamente na segunda linha antes de executar.

~~~powershell
$sshConfig = @"
Host awslinux
    HostName IP_DA_SUA_VM
    User ec2-user
    IdentityFile ~/.ssh/id_ed25519
"@
Add-Content -Path "$env:USERPROFILE\.ssh\config" -Value $sshConfig
~~~

### Passo 6: A Conexão Definitiva

O ciclo de infraestrutura terminou. O VirtualBox pode operar minimizado. Abra qualquer aba de terminal no seu Windows e invoque o laboratório.

~~~powershell
ssh awslinux
~~~

A barreira de entrada caiu. A conexão ocorre em milissegundos. Senhas não são mais necessárias. A proteção é máxima e o ambiente roda offline.

## 📚 Bibliografia e Arquitetura Teórica

A execução técnica perde força sem o domínio dos conceitos. Acesse as fontes abaixo para compreender mais detalhes das ferramentas.

- [A Lógica de Injeção do Cloud-Init](https://cloudinit.readthedocs.io/en/latest/)
- [Conceitos Fundamentais do Amazon Linux 2023](https://docs.aws.amazon.com/linux/al2023/ug/what-is-amazon-linux.html)
- [Criptografia de Curva Elíptica e Chaves SSH](https://www.ssh.com/academy/ssh/key)