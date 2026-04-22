# Proiect Fii Practic 2026 - Journey into the World of DevOps

## 1. Descriere generala
In acest proiect au fost create si configurate doua masini virtuale:
- app.fiipractic.lan
- gitlab.fiipractic.lan

Pe aceste VM-uri au fost implementate:
- provisioning automat cu Vagrant
- configurari comune si de deploy cu Ansible
- GitLab CE + GitLab Runner + Container Registry
- containerizare aplicatie backend (Spring Boot) cu Docker
- pipeline CI/CD in GitLab (test, build, push, deploy)
- observabilitate cu Netdata in spatele Nginx reverse proxy
- configurari Nginx pentru sesiunea 3 si sesiunea 4

Aplicatia folosita pentru pipeline si deploy este un backend Spring Boot, containerizat si publicat in GitLab Container Registry.

Nota: pentru partea de build al aplicatiei am folosit Maven, cu acordul profesorului.

## 2. Arhitectura pe scurt
Fluxul principal de livrare:
1. Codul este impins in GitLab.
2. Pipeline-ul ruleaza testele backend.
3. Se construieste imaginea Docker.
4. Imaginea este publicata in GitLab Container Registry.
5. Jobul de deploy ruleaza playbook-ul Ansible.
6. Pe app.fiipractic.lan este actualizat stack-ul Docker Compose.
7. Daca deploy-ul esueaza, se executa rollback automat la imaginea anterioara.

## 3. Structura proiectului
Structura reala din repository:

- Vagrantfile
- README.md
- README2.md
- Ansible/
  - common.yaml
  - inventory.ini
  - netdata.yaml
- gitlab_pipeline/
  - .gitlab-ci.yml
  - Dockerfile
  - docker-compose.yml
  - deploy.yaml
- docker_compose_sesiunea_4/
  - docker-compose.yml
- nginx_configs/
  - nginx_sesiunea_3.conf
  - nginx_sesiunea_4.conf
- bash_scripts/
  - bank.sh
  - client.sh
  - server.sh
- screenshots/
  - gitlab_runner.png
  - pipeline_overview.png
  - build_job_output_part1.png
  - build_job_output_part2.png
  - valid_certificate_gitlab.png
  - banner_ssh.png
  - netdata_fiipractic_lan_screenshot.png

## 4. Ce face fiecare componenta

### 4.1 Vagrant
Fisier: Vagrantfile

Rol:
- defineste cele doua VM-uri
- seteaza hostname-urile
- configureaza resursele CPU/RAM
- configureaza private network
- redimensioneaza discul pentru VM-ul de GitLab
- ruleaza provisioning initial (root password, configurari SSH, restart sshd, instalare git/vim)

In plus:
- copiaza cheia publica de pe host in authorized_keys pentru root (conectare SSH fara parola)
- foloseste o structura Ruby cu hash pentru a evita duplicarea configurarii intre VM-uri

### 4.2 Inventory Ansible
Fisier: Ansible/inventory.ini

Rol:
- grupeaza host-urile in:
  - app
  - gitlab

### 4.3 Playbook comun
Fisier: Ansible/common.yaml

Rol principal:
- dezactiveaza firewalld
- seteaza timezone Europe/Bucharest
- seteaza PermitRootLogin conform politicii de proiect
- configureaza SSH banner personalizat
- dezactiveaza SELinux
- instaleaza si porneste Docker
- copiaza Root CA pe masini si face update trust store

Pe host-ul gitlab:
- instaleaza gitlab-ce
- instaleaza gitlab-runner
- configureaza certificatele pentru GitLab
- configureaza registry_external_url si setarile de registry
- ruleaza gitlab-ctl reconfigure / start

### 4.4 Deploy aplicatie
Fisier: gitlab_pipeline/deploy.yaml

Rol:
- pregateste directorul de deploy
- scrie fisierul .env din variabile CI/CD
- autentifica in GitLab Container Registry
- verifica daca exista deja containerul aplicatiei
- salveaza imaginea curenta pentru rollback
- sterge containerul vechi si imaginea veche
- face pull la noile imagini si porneste stack-ul
- valideaza health endpoint-ul aplicatiei

Rollback:
- daca deploy-ul nou esueaza:
  - restaureaza .env cu imaginea anterioara
  - opreste stack-ul curent
  - face pull la imaginea veche
  - reporneste stack-ul anterior
  - valideaza din nou endpoint-ul de sanatate

### 4.5 Dockerfile aplicatie
Fisier: gitlab_pipeline/Dockerfile

Rol:
- construieste imaginea backend-ului Spring Boot
- expune portul aplicatiei
- ruleaza artefactul jar

Nota:
- build-ul este pe Maven (aprobat in cadrul proiectului)

### 4.6 Docker Compose pentru deploy
Fisier: gitlab_pipeline/docker-compose.yml

Rol:
- defineste serviciile necesare aplicatiei (backend + baza de date)
- configureaza variabilele de runtime
- configureaza dependentele dintre servicii

### 4.7 Pipeline GitLab
Fisier: gitlab_pipeline/.gitlab-ci.yml

Rol:
- include template GitLab Workflow
- ruleaza testele backend in mediu izolat
- construieste imaginea Docker
- publica imaginea in registry
- ruleaza deploy pe host-ul aplicatiei prin Ansible

Practici folosite:
- cache Maven (.m2/repository)
- variabile sensibile citite din GitLab CI/CD Variables (fara hardcodare in repo)

### 4.8 Nginx sesiunea 3
Fisier: nginx_configs/nginx_sesiunea_3.conf

Rol:
- configurare HTTPS pentru app.fiipractic.lan
- reverse proxy pentru netdata
- pagina de mentenanta pentru erori upstream
- HTTP security headers (X-Frame-Options, X-Content-Type-Options, CSP, HSTS etc.)

### 4.9 Nginx sesiunea 4
Fisier: nginx_configs/nginx_sesiunea_4.conf

Rol:
- reverse proxy + load balancing pentru doua instante backend
- terminare TLS

### 4.10 Extra Bash scripts
Fisiere:
- bash_scripts/bank.sh
- bash_scripts/client.sh
- bash_scripts/server.sh

Rol:
- aplicatie bancara simpla in Bash
- transfer de fisiere cu netcat (client/server)

### 4.11 Extra Netdata
Fisier: Ansible/netdata.yaml

Rol:
- instaleaza Netdata
- instaleaza si configureaza Nginx ca reverse proxy pentru netdata.fiipractic.lan
- adauga Basic Authentication
- configureaza pagina de mentenanta pentru indisponibilitate upstream

## 5. Evidente (screenshots)
In folderul screenshots sunt incluse:
- runner disponibil: gitlab_runner.png
- pipeline + output build: pipeline_overview.png, build_job_output_part1.png, build_job_output_part2.png
- certificat valid pe GitLab intern: valid_certificate_gitlab.png
- banner SSH: banner_ssh.png
- Netdata accesibil prin domeniu: netdata_fiipractic_lan_screenshot.png

## 6. Dificultati intampinate si cum au fost rezolvate
1. Configurarea Vagrant in Ruby
- Dificultate: sintaxa Ruby (hash-uri, interpolari) pentru configurare DRY.
- Solutie: folosirea unei structuri unice pentru definirea VM-urilor si a unui block comun de provisioning.

2. Copierea cheii SSH de pe host pe VM
- Dificultate: comenzi rulate pe guest in loc de host.
- Solutie: citirea cheii publice pe host in Ruby si injectarea ei in authorized_keys pe fiecare VM.

3. Deploy robust in CI/CD
- Dificultate: risc de downtime sau stare inconsistente la update.
- Solutie: mecanism de rollback automat in deploy.yaml, cu validare endpoint dupa deploy si dupa rollback.

4. Integrare GitLab Registry + deploy remote
- Dificultate: autentificare, pull de imagini, ordonare corecta a pasilor.
- Solutie: login explicit in registry, .env gestionat din variabile CI/CD, secventa clara pull/up/healthcheck.

## 7. Ce am adaugat in plus fata de cerinte
- rollback automat in playbook-ul de deploy
- cache Maven in pipeline pentru performanta mai buna
- security headers explicite in configurarea Nginx
- documentare extinsa a componentelor si fluxului

## 8. Observatii finale
Proiectul acopera zona de provisioning, configurare, securizare, observabilitate, containerizare si livrare automata prin CI/CD.

Separarea pe componente (Vagrant, Ansible, CI/CD, Nginx, Docker) permite extinderea usoara si mentenanta simpla.
