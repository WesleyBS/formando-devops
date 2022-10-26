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

Respostas

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