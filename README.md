# Proiect Fii Practic 2026

## Descriere generală
În cadrul proiectului au fost create două mașini virtuale, `app.fiipractic.lan` și `gitlab.fiipractic.lan`, 
care au fost folosite pentru a configura servicii precum nginx, GitLab, GitLab Container Registry, Docker, 
Netdata și Ansible. 

Pornirea și configurarea inițială se fac cu Vagrantfile, iar automatizarea post-provisioning se fac cu 
playbook-ul din Ansible/common.yaml. Apoi pentru partea de deploy a aplicatiei, codul acesteia ajunge pe GitLab, 
unde pipeline-ul din gitlab_pipeline/.gitlab-ci.yml rulează testele, construiește imaginea Docker, 
o publică în registry și apoi face deploy automat cu gitlab_pipeline/deploy.yaml. 
Aplicația rulează containerizat prin docker si se foloseste __Maven__ pentru build-ul aplicatiei.


## Structura proiectului
```text
FiiPractic-DevOps/
├── Ansible
│   ├── common.yaml
│   ├── inventory.ini
│   └── netdata.yaml
├── bash_scripts
│   ├── bank.sh
│   ├── client.sh
│   └── server.sh
├── docker_compose_sesiunea_4
│   └── docker-compose.yml
├── gitlab_pipeline
│   ├── deploy.yaml
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── .gitlab-ci.yml
├── nginx_configs
│   ├── nginx_sesiunea_3.conf
│   └── nginx_sesiunea_4.conf
├── README.md
├── screenshots
│   ├── banner_ssh.png
│   ├── build_job_output_part1.png
│   ├── build_job_output_part2.png
│   ├── gitlab_runner.png
│   ├── netdata_fiipractic_lan_screenshot.png
│   ├── pipeline_overview.png
│   └── valid_certificate_gitlab.png
└── Vagrantfile
```

## Descrierea componentelor:
 ### 1. **Vagrantfile**
- prin intermediul acestuia se creeaza cele doua masini virutal `app.fiipractic.lan` și `gitlab.fiipractic.lan`
care au ip-urile `192.168.56.10` si `192.168.56.20` respectiv, configurate conform celor cerute. Pentru masinile virtuale este folosit **libvirt/QEMU**.
- __In plus__ am adaugat in etapa de provision un pas care copiaza cheia de pe host si o copiaza pe cele doua masini virtuale ( `echo '#{host_key}' >> /root/.ssh/authorized_keys`)
astfel incat sa nu mai fie nevoie de parola cand vom face conexiunea ssh de pe masina gazda. Pe langa aceasta am ales sa fac configurarea cu ajutorul unui hash din Ruby
pentru a nu repeta de mai multe ori aceleasi instructiuni de config pentru cele doua masini.

### 2.1 **common.yaml (Ansible/common.yaml**
- acest fisier contine toate configurarile comune care trebuie sa apara pe cele doua masini virtuale plus instalarea gitlab pe `gitlab.fiipractic.lan` cerute in cadrul proiectului in mod obligatoriu.
- __In plus__ prin acest yaml:
  * setam si un baner pentru ssh (`screenshots/banner_ssh.png`), care este configurat in cadrul task-urilor:
    * `Create banner file on both machines`
    * `Modify sshd config to show the banner`
    * `Restart sshd`
  * realizam si configurari pentru Gitlab in mod automat:
    * configurarea certificatelor SSL pentru domeniul gitlab.fiipractic.lan
    * configurarea registry-ului Docker integrat (registry_external_url, registry_enabled, porturi)
    * aplicarea configurarilor prin comanda `gitlab-ctl reconfigure` si `gitlab-ctl start`

### 2.2 **netdata.yaml (Ansible/netdata.yaml)**
- Playbook folosit pentru a configura nginx ca si un reverse proxy pentru interfata netdata si de asemenea seteaza basic auth
  pentru `https://netdata.fiipractic.lan`
- Playbook-ul consta din taskuri care realizeaza:
  * instalare nginx, netdata si httpd-tools (necesar pentru basic auth)
  * crearea unui folder unde vor fi copiate de pe masina gitlab certificatul si cheia necesare pentru conexiunea https
  * copierea certificatului si cheii prezente in `./cert` in folderul creat anterior
  * crearea fisierului `.htpasswd`, care contine credentialele necesare autentificarii basic auth
  * crearea unui director pentru pagina de mentenanta (`/var/www/example`) si generarea acesteia
  * crearea configurarii nginx ca si reverse proxy pentru netdata in fisierul: `/etc/nginx/conf.d/netdata.conf`
  * testarea configurarii pentru orice fel de erori si restratarea serviciului nginx

### 3.1 **deploy.yaml (gitlab_pipeline/deploy.yaml)**
- playbook-ul care este responsabil pentru deployment-ul aplicatiei SpringBoot `backend` si a bd-ului asociat acesteia pe `app.fiipractic.lan`
- playbook-ul realizeaza urmatoarele lucruri:
  * pregateste folderul de deploy
  * se autentifica in gitlab container registry
  * verifica daca exista deja containerul aplicatiei
  * sterge containerul vechi si imaginea veche
  * face pull la noile imagini si porneste docker compose
- __In plus__ acesta mai are si task-uri care realizeaza:
  * scrierea in .env variabilele din CI/CD, necesare rularii aplicatiei
  * salvarea imaginii curente pentru rollback
  * validarea health endpoint-ul aplicatiei
  * rollback, in cazul in care versiunea curenta nu poate fi deployed(adica daca apare orice failed task in blockul de deploy),
    da pull la vechea imagine de docker si o reporneste pe aceasta

### 3.2 **Dockerfile (gitlab_pipeline/Dockerfile)**
- prin acest fisier se construieste imaginea backend-ului Spring Boot (__folosind Maven__),
expune portul necesar aplicatiei si ruleaza artefactul jar

### 3.3 **docker-compose.yml (gitlab_pipeline/docker-compose.yml)**
- fisier al carui rol este sa defineasca serviciile necesare aplicatiei (backend + baza de date),
sa configureze variabilele de runtime si dependentele dintre servicii( containerul de backend porneste 
doar dupa ce baza de date a pornit in mod corect si este disponibila)

### 3.4 **.gitlab-ci.yml (gitlab_pipeline/.gitlab-ci.yml)**
- acest fisier defineste pipeline-ul de CI/CD al proiectului si descrie etapele principale prin care trece aplicatia:
testare, build, publicarea imaginii Docker si deploy.
- in plus, pipeline-ul a fost configurat sa foloseasca template-ul `GitLab Workflows/Branch-Pipelines.gitlab-ci.yml`, 
care ajuta la controlul modului in care pipeline-ul este declansat in functie de branch-uri si reguli de workflow.
- stagiul `test` ruleaza testele backend-ului intr-un mediu izolat, printr-un user non-root
- stagiul `build` construieste imaginea Docker a aplicatiei backend
- stagiul `push` publica imaginea construita in GitLab Container Registry
- stagiul deploy realizeaza deploy-ul aplicatiei pe `app.fiipractic.lan` folosind un playbook Ansible(`deploy.yaml`)

### 4. **bash_scripts/**
- Acest folder contine trei scripturi de bash reprezentand: aplicatia bancara(`bank.sh`) si File transfer
  using Netcat(`client.sh` si `server.sh`) de la sesiunea 2.

### 5. **nginx_confs**
- Folderul contine doua contine 2 configs de nginx:
  * `nginx_sesiunea_3.conf` folosita in sesiunea 3 in care se configureaza headerele HTTP si pagina de mentenanta;
  * `nginx_sesiunea_4.conf` folosita in sesiunea 4 pentru configurarea reverse proxy și load balancer.
- __In plus__, am adaugat in `nginx_sesiunea_3.conf` security headers explicite:
    ```text
         add_header X-Frame-Options "DENY" always;
         add_header X-Content-Type-Options "nosniff" always;
         add_header Referrer-Policy "strict-origin-when-cross-origin" always;
         add_header Content-Security-Policy "default-src 'self';" always;
         add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    ```

### 6. **screenshots/**
- in acest folder sunt incluse pozele cerute:
  - runner disponibil: `gitlab_runner.png`
  - pipeline + output build: `pipeline_overview.png`, `build_job_output_part1.png`, `build_job_output_part2.png`
  - certificat valid pe GitLab intern: `valid_certificate_gitlab.png`
  - banner SSH: `banner_ssh.png`
  - Netdata accesibil pe `netdata.fiipractic.lan`: `netdata_fiipractic_lan_screenshot.png`

## Dificultati intampinate
- __Cateva dificultati__ care au aparut au fost:
    * faptul ca nu cunosc foarte bine Ruby si a trebuit sa caut exact cum se face/utilizeaza un hash in Ruby
    * initial cand am adaugat copierea cheii pe cele doua masini virtuale faceam `cat ~/.ssh/id_rsa.pub | echo >> /root/.ssh/authorized_keys` ceea ce este incorect deoarece
      aceste comenzi se executa pe masina virtuala si nu local, astfel a trebuit sa caut cum sa citesc dintr-un fisier
      in ruby si cum sa salvez intr-o variabila (`host_key = File.read(File.expand_path("~/.ssh/id_rsa.pub"))`) ca
      sa o pot folosi mai incolo la copierea cheii.
    * probleme cu modulul de docker comunity pentru Ansible, a trebuit sa folosesc direct comenzi de shell pentru lucru cu docker
    * cateva probleme la partea de deploy pentru pipeline:
      - faptul ca la inceput rulam testele din modulul de test direct pe masina gitlab, unde nu aveam instalat jdk-17, am trecut mai tarziu pe rularea testlor pe docker
      deoarece aduc si un layer in plus de izolare
      - probleme cu user-ul gitlab_runner, care initial nu are toate permisiunile necesare, deoarece nu facea parte din grupul wheel si docker pe masin app.fiipractic.lan
      - faptul ca userul care rula in docker testele nu era owner-ul fisierelor si nu putea sa le stearga pentru a reface testele, a trebuit sa fac `chown` astfel incat acesta sa o poata face
    * multiple probleme cu sintaxa de yaml si cu modulele de Ansible in timp ce faceam playbook-urile, problema care a fost rezolvata prin mai mult research si atentie la alinierea instructiunilor in cadrul yaml-urilor