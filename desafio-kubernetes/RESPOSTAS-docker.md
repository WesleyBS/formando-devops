1. Execute o comando `hostname` em um container usando a imagem `alpine`. Certifique-se que o container será removido após a execução.

```bash
➜  docker container run alpine sh -c "hostname" && docker container prune -f && docker container ls -a

Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
213ec9aee27d: Pull complete 
Digest: sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad
Status: Downloaded newer image for alpine:latest
00c4edaa0237
Deleted Containers:
00c4edaa023727e7f454d367cf3b8671c51613432615763628af390a870eea0e
ecf40c81cd83ff43ac00611c67e2b0c2645d3b5cbc8bccd3b7fde999a4550afc

Total reclaimed space: 0B
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

2. Crie um container com a imagem `nginx` (versão 1.22), expondo a porta 80 do container para a porta 8080 do host.

```bash
➜ docker container run -d -p 8080:80 nginx:1.22
Unable to find image 'nginx:1.22' locally
1.22: Pulling from library/nginx
bd159e379b3b: Pull complete 
265da2307f4a: Pull complete 
9f5a323076dc: Pull complete 
1cb127bd9321: Pull complete 
20d83d630f2b: Pull complete 
e0c68760750a: Pull complete 
Digest: sha256:f0d28f2047853cbc10732d6eaa1b57f1f4db9b017679b9fd7966b6a2f9ccc2d1
Status: Downloaded newer image for nginx:1.22
242a4c2dfba99ac94f43bd4211058df6084393594f04b4a39399a7a57b414d66

➜  docker ps                                    
CONTAINER ID   IMAGE        COMMAND                  CREATED         STATUS         PORTS                                   NAMES
242a4c2dfba9   nginx:1.22   "/docker-entrypoint.…"   4 seconds ago   Up 2 seconds   0.0.0.0:8080->80/tcp, :::8080->80/tcp   elegant_neumann

➜  curl localhost:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

3. Faça o mesmo que a questão anterior (2), mas utilizando a porta 90 no container. O arquivo de configuração do nginx deve existir no host e ser read-only no container.
---
Aproveitando o container já criado, peguei o mesmo arquivo gerado nele ([default.conf](default.conf)) e alterei a porta para 90, no novo arquivo

```bash
➜ docker cp 242a4c2dfba9:/etc/nginx/conf.d/default.conf .

➜ sed -i "s/80/90/g" default.conf

➜ docker container run -d -p 8081:90 --mount type=bind,src=$(pwd)/default.conf,dst=/etc/nginx/conf.d/default.conf,ro nginx:1.22
86d9677cca4b75c6b9d0bf72631a582228bc67e751813fe162a7ba9d7da985c6

➜ curl localhost:8081
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

➜ docker ps
CONTAINER ID   IMAGE        COMMAND                  CREATED              STATUS              PORTS                                           NAMES
86d9677cca4b   nginx:1.22   "/docker-entrypoint.…"   About a minute ago   Up About a minute   80/tcp, 0.0.0.0:8081->90/tcp, :::8081->90/tcp   awesome_mcclintock
242a4c2dfba9   nginx:1.22   "/docker-entrypoint.…"   27 minutes ago       Up 27 minutes       0.0.0.0:8080->80/tcp, :::8080->80/tcp           elegant_neumann

➜ docker exec 86d9677cca4b sh -c "ls -lh /etc/nginx/conf.d/"            
total 4.0K
-rw-r--r--. 1 1000 1000 1.1K Oct 15 19:50 default.conf
```

4. Construa uma imagem para executar o programa abaixo:
```python
def main():
   print('Hello World in Python!')

if __name__ == '__main__':
  main()
```
---

Para este desafio, primeiro criei 2 arquivos: o [app.py](app.py) e o [requirements.txt](requirements.txt), onde o primeiro conterá o código python do desafio e o segundo terá a versão que o python deverá executar

```bash

➜ touch app.py && touch requirements.txt

➜ cat << EOF >> app.py
heredoc> def main():
   print('Hello World in Python!')

if __name__ == '__main__':
  main()
heredoc> EOF

➜ echo "requests==2.27.1" > requirements.txt
```

Após isso, foi a hora de escrever o Dockerfile

```docker
FROM python:3.8-slim-buster

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY . .

CMD [ "python", "./app.py" ]
```

Então foi o momento de construir a imagem:

```bash
➜  docker build --tag python-docker .
Sending build context to Docker daemon  14.85kB
Step 1/6 : FROM python:3.8-slim-buster
3.8-slim-buster: Pulling from library/python
f6e04ba65310: Pull complete 
b87859229fd4: Pull complete 
598a5d7238e9: Pull complete 
be1d88d97f44: Pull complete 
22a630315c5a: Pull complete 
Digest: sha256:03c12f7bbd977120133b73e4b3ef5c5707ca09be338156dc02306d41633db4c0
Status: Downloaded newer image for python:3.8-slim-buster
 ---> 5f3ce1d922f0
Step 2/6 : WORKDIR /app
 ---> Running in 72b265cc7007
Removing intermediate container 72b265cc7007
 ---> 713efe657187
Step 3/6 : COPY requirements.txt requirements.txt
 ---> ba03fe9510f5
Step 4/6 : RUN pip3 install -r requirements.txt
 ---> Running in 14abd244c469
Collecting requests==2.27.1
  Downloading requests-2.27.1-py2.py3-none-any.whl (63 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 63.1/63.1 KB 1.5 MB/s eta 0:00:00
Collecting certifi>=2017.4.17
  Downloading certifi-2022.9.24-py3-none-any.whl (161 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 161.1/161.1 KB 7.6 MB/s eta 0:00:00
Collecting idna<4,>=2.5
  Downloading idna-3.4-py3-none-any.whl (61 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 61.5/61.5 KB 27.1 MB/s eta 0:00:00
Collecting charset-normalizer~=2.0.0
  Downloading charset_normalizer-2.0.12-py3-none-any.whl (39 kB)
Collecting urllib3<1.27,>=1.21.1
  Downloading urllib3-1.26.12-py2.py3-none-any.whl (140 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 140.4/140.4 KB 41.1 MB/s eta 0:00:00
Installing collected packages: urllib3, idna, charset-normalizer, certifi, requests
Successfully installed certifi-2022.9.24 charset-normalizer-2.0.12 idna-3.4 requests-2.27.1 urllib3-1.26.12
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
WARNING: You are using pip version 22.0.4; however, version 22.3 is available.
You should consider upgrading via the '/usr/local/bin/python -m pip install --upgrade pip' command.
Removing intermediate container 14abd244c469
 ---> 08ea33b8b9f4
Step 5/6 : COPY . .
 ---> 2633e5c36d0c
Step 6/6 : CMD [ "python", "./app.py" ]
 ---> Running in 780b0256c543
Removing intermediate container 780b0256c543
 ---> a0804d24af39
Successfully built a0804d24af39
Successfully tagged python-docker:latest
```

Feito isso, a imagem foi executada para checar a saída do container:

```bash
➜ docker container run python-docker          
Hello World in Python!
```

5. Execute um container da imagem `nginx` com limite de memória 128MB e 1/2 CPU.

```bash

➜ docker container run -d --memory="128m" --cpus="0.5" nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
bd159e379b3b: Already exists 
8d634ce99fb9: Pull complete 
98b0bbcc0ec6: Pull complete 
6ab6a6301bde: Pull complete 
f5d8edcd47b1: Pull complete 
fe24ce36f968: Pull complete 
Digest: sha256:2f770d2fe27bc85f68fd7fe6a63900ef7076bc703022fe81b980377fe3d27b70
Status: Downloaded newer image for nginx:latest

➜ docker container ps                          
CONTAINER ID   IMAGE        COMMAND                  CREATED              STATUS              PORTS                                           NAMES
f321c4cefd65   nginx        "/docker-entrypoint.…"   About a minute ago   Up About a minute   80/tcp                                          angry_chaplygin
86d9677cca4b   nginx:1.22   "/docker-entrypoint.…"   57 minutes ago       Up 57 minutes       80/tcp, 0.0.0.0:8081->90/tcp, :::8081->90/tcp   awesome_mcclintock
242a4c2dfba9   nginx:1.22   "/docker-entrypoint.…"   About an hour ago    Up About an hour    0.0.0.0:8080->80/tcp, :::8080->80/tcp           elegant_neumann

➜ docker container inspect f321c4cefd65 | egrep "\"Memory\"|NanoCpus"
            "Memory": 134217728,
            "NanoCpus": 500000000,

➜ echo $(( 134217728 / 1024 / 1024 ))
128
```

6. Qual o comando usado para limpar recursos como imagens, containers parados, cache de build e networks não utilizadas?

```bash
➜ docker system prune 

WARNING! This will remove:
  - all stopped containers
  - all networks not used by at least one container
  - all dangling images
  - all dangling build cache

Are you sure you want to continue? [y/N]
```

7. Como você faria para extrair os comandos Dockerfile de uma imagem?

