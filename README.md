# Backup-AlfrescoCE-7.4

Passo a Passo para Backup e Restauração do Alfresco Community 7.4  
(Testado Apenas na Versão 7.4.1)

---

## 📁 1. Criação da Pasta de Backup no NAS

Crie um diretório específico no NAS para armazenar os backups do Alfresco:
![image](https://github.com/user-attachments/assets/c5385303-d6c9-405a-843f-a25e046b09bc)

## 🔗 2. Mapeamento do Volume NFS no Servidor Alfresco

No servidor onde o Alfresco está instalado, edite o arquivo `/etc/fstab` para mapear o volume NFS:  
`sudo nano /etc/fstab`

Adicione a seguinte linha ao final do arquivo:  
`IP_DO_NAS:/shares/Alfresco /mnt/alfresco-backups nfs defaults 0 0`

Salve o arquivo e monte o volume com:  
`sudo mount -a`

Verifique se o volume foi montado corretamente:  
`df -h

🧪 3. Teste de Backup
a) Adicionando Arquivos para Teste
Crie um usuário e copie alguns arquivos de teste para o Alfresco (por exemplo, pela interface do Share) para garantir que haverá conteúdo a ser recuperado.
Criei um usuario chamado teste
![image](https://github.com/user-attachments/assets/2ce906db-306d-4589-86af-0e5c341f05d3)
Adicionei as seguintes imagens nos arquivos compartilhados.
![image](https://github.com/user-attachments/assets/e97a4192-f56e-4bee-8756-148cccc892c8)

🛑 4. Parar o Ambiente Alfresco
Para simular um cenário de perda de dados:
docker-compose down
![image](https://github.com/user-attachments/assets/936ea00c-0463-4c0f-868e-97460c0bbea2)


🧹 5. Remover Dados Existentes
Acesse o diretório onde está o docker-compose do Alfresco:
cd /opt/docker-compose && rm -rf ./data/postgres/*
![image](https://github.com/user-attachments/assets/89fc3de7-82f4-4eac-aeed-b4c5e0e113d6)

Liste os volumes existentes:
docker volume ls

Remova o volume do PostgreSQL (substitua nome_do_volume pelo nome real):
docker volume rm nome_do_volume
![image](https://github.com/user-attachments/assets/1ddf8d40-dc8a-47f6-b91a-037477d6c744)


🐘 6. Subir o Container do PostgreSQL e Criar Banco Zerado
Suba apenas o serviço do PostgreSQL:
docker-compose up -d postgres
![image](https://github.com/user-attachments/assets/8c673301-1863-43ec-a425-c0def969373b)

Acesse o container do PostgreSQL:
docker exec -it nome_container_postgres psql -U alfresco
![image](https://github.com/user-attachments/assets/146bc9c6-3c8e-4dbf-8939-92da4781d653)

No prompt do PostgreSQL:
\l                      -- Lista os bancos
\c postgres             -- Conecta-se ao banco postgres
DROP DATABASE alfresco; -- Exclui o banco atual
CREATE DATABASE alfresco OWNER alfresco ENCODING 'UTF8'; -- Cria banco zerado
\q                      -- Sai do PostgreSQL
![image](https://github.com/user-attachments/assets/455a8300-7020-4e30-8930-50c9e04e24e5)


♻️ 7. Restauração do Backup
Execute o script de restauração, durante a execução, selecione a data do backup desejado para restauração:
docker-compose down && bash restore_backup.sh
![image](https://github.com/user-attachments/assets/03a9de50-bca0-42d3-b050-190b0d923d53)

Você pode notar o log do script criando as tabelas, restaurando os módulos, índices Solr e Subindo os Containers.
![image](https://github.com/user-attachments/assets/8c8d8889-b7aa-477a-9ef2-52a738afeb16)


✅ 8. Verificação
Após a conclusão da restauração:

Acesse a interface do Alfresco Share

Verifique se os arquivos inseridos anteriormente estão disponíveis















