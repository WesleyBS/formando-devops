### ```1``` - Com uma unica linha de comando capture somente linhas que contenham "erro" do log do pod `serverweb` no namespace `meusite` que tenha a label `app: ovo`.

```bash
kubectl logs -c serverweb -n meusite -l app=ovo | grep -i -A9 ERRO

# Invetigar outra forma de filtrar o erro e adicionar opção do -f
```
### ```2``` - Crie o manifesto de um recurso que seja executado em todos os nós do cluster com a imagem `nginx:latest` com nome `meu-spread`, nao sobreponha ou remova qualquer taint de qualquer um dos nós.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: meu-spread
  namespace: default
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: meu-spread
        image: nginx:latest
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
      terminationGracePeriodSeconds: 30
```

### ```3``` - Crie um deploy `meu-webserver` com a imagem `nginx:latest` e um initContainer com a imagem `alpine`. O initContainer deve criar um arquivo /app/index.html, tenha o conteudo "HelloGetup" e compartilhe com o container de nginx que só poderá ser inicializado se o arquivo foi criado.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: meu-webserver
  name: meu-webserver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meu-webserver
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: meu-webserver
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: workdir
          mountPath: /usr/share/nginx/html
      initContainers:
      - name: index
        image: alpine
        command: ['sh', '-c', 'touch /app/index.html && echo "HelloGetup" > /app/index.html']
        volumeMounts:
        - name: workdir
          mountPath: "/app"
      dnsPolicy: Default
      volumes:
      - name: workdir
        emptyDir: {}
```

### ```4``` - Crie um deploy chamado `meuweb` com a imagem `nginx:1.16` que seja executado exclusivamente no node master.

Como os nodes que subi no kind não possuem a label ```master```, adicionei esta label ao nó control-plane

```bash
kubectl label nodes meuk8s-control-plane dedicated=master
```
Desta forma, foi possível selecioná-lo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: meuweb
  name: meuweb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meuweb
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: meuweb
    spec:
      nodeSelector:
        dedicated: master
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - image: nginx:1.16
        name: nginx
        resources: {}
status: {}
```

### ```5``` - Com uma unica linha de comando altere a imagem desse pod `meuweb` para `nginx:1.19` e salve o comando aqui no repositorio.

```bash
kubectl set image deployment meuweb nginx=nginx:1.19
```

### ```6``` - Quais linhas de comando para instalar o ingress-nginx controller usando helm, com os seguintes parametros;

    helm repository : https://kubernetes.github.io/ingress-nginx

    values do ingress-nginx : 
    controller:
      hostPort:
        enabled: true
      service:
        type: NodePort
      updateStrategy:
        type: Recreate


Respostas:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

cat << EOF >> values.yaml
controller:
      hostPort:
        enabled: true
      service:
        type: NodePort
      updateStrategy:
        type: Recreate
EOF

helm install -f values.yaml --namespace ingress-nginx --create-namespace --name=ingress-nginx ingress-nginx/ingress-nginx

#validar comandos com instalação
```

### ```7``` - Quais as linhas de comando para: 

    criar um deploy chamado `pombo` com a imagem de `nginx:1.11.9-alpine` com 4 réplicas;
    alterar a imagem para `nginx:1.16` e registre na annotation automaticamente;
    alterar a imagem para 1.19 e registre novamente; 
    imprimir a historia de alterações desse deploy;
    voltar para versão 1.11.9-alpine baseado no historico que voce registrou.
    criar um ingress chamado `web` para esse deploy

Respostas:

```bash
kubectl create deployment pombo --image nginx:1.11.9-alpine --replicas=4

kubectl set image deployment pombo nginx=nginx:1.16 --record

kubectl set image deployment pombo nginx=nginx:1.19 --record

kubectl rollout history deployment pombo

kubectl rollout undo deployment pombo --to-revision=1

# fazer ingress
```

### ```8``` - Linhas de comando para; 

    criar um deploy chamado `guardaroupa` com a imagem `redis`;
    criar um serviço do tipo ClusterIP desse redis com as devidas portas.

Resposta

```bash
kubectl create deployment guardaroupa --image redis

kubectl create service clusterip guardaroupa --tcp=6379:6379
```

### ```9``` - crie um recurso para aplicação stateful com os seguintes parametros:

    - nome : meusiteset
    - imagem nginx 
    - no namespace backend
    - com 3 réplicas
    - disco de 1Gi
    - montado em /data
    - sufixo dos pvc: data

Resposta deve incluir criação de namespace

```bash
kubectl create namespace backend
```

Manifesto StateFulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: meusiteset
  namespace: backend
spec:
  serviceName: meusiteset
  replicas: 3
  selector:
    matchLabels:
      app: meusiteset
  template:
    metadata:
      labels:
        app: meusiteset
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: meusiteset
          image: nginx
          ports:
            - containerPort: 80
              name: web
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes:
          - ReadWriteOnce
        storageClassName: standard # SC padrão kind
        resources:
          requests:
            storage: 1Gi
```

### ```10``` - crie um recurso com 2 replicas, chamado `balaclava` com a imagem `redis`, usando as labels nos pods, replicaset e deployment, `backend=balaclava` e `minhachave=semvalor` no namespace `backend`.

Resposta:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: balaclava
  name: balaclava
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: balaclava
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: balaclava
        backend: balaclava
        minhachave: semvalor
    spec:
      containers:
      - image: redis
        name: redis
        resources: {}
status: {}
```

### ```11``` - Linha de comando para listar todos os serviços do cluster do tipo `LoadBalancer` mostrando tambem `selectors`.

Resposta

```bash
kubectl get services -A --output=custom-columns='NAME:.metadata.name,TYPE:.spec.type,SELECTOR:.spec.selector' | egrep "LoadBalancer|NAME" 
```

### ```12``` - com uma linha de comando, crie uma secret chamada `meusegredo` no namespace `segredosdesucesso` com os dados, `segredo=azul` e com o conteudo do texto abaixo.

Resposta:

```bash
   # cat chave-secreta
     aW5ncmVzcy1uZ2lueCAgIGluZ3Jlc3MtbmdpbngtY29udHJvbGxlciAgICAgICAgICAgICAgICAg
     ICAgICAgICAgICAgTG9hZEJhbGFuY2VyICAgMTAuMjMzLjE3Ljg0ICAgIDE5Mi4xNjguMS4zNSAg
     IDgwOjMxOTE2L1RDUCw0NDM6MzE3OTQvVENQICAgICAyM2ggICBhcHAua3ViZXJuZXRlcy5pby9j
     b21wb25lbnQ9Y29udHJvbGxlcixhcHAua3ViZXJuZXRlcy5pby9pbnN0YW5jZT1pbmdyZXNzLW5n
     aW54LGFwcC5rdWJlcm5ldGVzLmlvL25hbWU9aW5ncmVzcy1uZ
```