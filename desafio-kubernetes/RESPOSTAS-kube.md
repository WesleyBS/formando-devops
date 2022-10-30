### ```1``` - Com uma unica linha de comando capture somente linhas que contenham "erro" do log do pod `serverweb` no namespace `meusite` que tenha a label `app: ovo`.

Respostas:
> Palavras-chave: logs, label, grep

```bash
kubectl logs -f -c serverweb -n meusite -l app=ovo | grep -i -A9 ERRO
```

### ```2``` - Crie o manifesto de um recurso que seja executado em todos os nós do cluster com a imagem `nginx:latest` com nome `meu-spread`, nao sobreponha ou remova qualquer taint de qualquer um dos nós.

Respostas:
> Palavras-chave: daemonset, tolerations

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

Respostas:
> Palavras-chave: initContainer, volumeMounts, command

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

Respostas:
> Palavras-chave: label, nodeSelector, tolerations

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

Respostas:
> Palavras-chave: set, image

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
> Palavras-chave: helm, repo, install, values

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

helm install nginx-ingress ingress-nginx/ingress-nginx -f values.yaml
```

### ```7``` - Quais as linhas de comando para: 

    criar um deploy chamado `pombo` com a imagem de `nginx:1.11.9-alpine` com 4 réplicas;
    alterar a imagem para `nginx:1.16` e registre na annotation automaticamente;
    alterar a imagem para 1.19 e registre novamente; 
    imprimir a historia de alterações desse deploy;
    voltar para versão 1.11.9-alpine baseado no historico que voce registrou.
    criar um ingress chamado `web` para esse deploy

Respostas:
> Palavras-chave: set, rollout, ingress, rule

```bash
kubectl create deployment pombo --image nginx:1.11.9-alpine --replicas=4

kubectl set image deployment pombo nginx=nginx:1.16 --record

kubectl set image deployment pombo nginx=nginx:1.19 --record

kubectl rollout history deployment pombo

kubectl rollout undo deployment pombo --to-revision=1

kubectl create service clusterip pombo --clusterip="None"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml

helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace

kubectl create ingress web --class=nginx --rule="local.lab/=pombo:80"
```

### ```8``` - Linhas de comando para; 

    criar um deploy chamado `guardaroupa` com a imagem `redis`;
    criar um serviço do tipo ClusterIP desse redis com as devidas portas.

Respostas:
> Palavras-chave: service, clusterIP

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

Respostas:
> Palavras-chave: namespace, statefulset, storageclass, pv, pvc

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

Respostas:
> Palavras-chave: template, label

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

Respostas:
> Palavras-chave: custom-columns, go-template

```bash
kubectl get services -A --output=custom-columns='NAME:.metadata.name,TYPE:.spec.type,SELECTOR:.spec.selector' | egrep "LoadBalancer|NAME" 

ou

echo " NAME         TYPE       SELECTOR" && kubectl get service -A -o go-template='{{range $index, $element := .items}} {{ if (eq $element.spec.type "LoadBalancer")}}{{$element.metadata.name}}  {{$element.spec.type}}  {{$element.spec.selector}}  {{"\n"}}{{ end }}{{end}}'
```

### ```12``` - com uma linha de comando, crie uma secret chamada `meusegredo` no namespace `segredosdesucesso` com os dados, `segredo=azul` e com o conteudo do texto abaixo.

```bash
# cat chave-secreta
     aW5ncmVzcy1uZ2lueCAgIGluZ3Jlc3MtbmdpbngtY29udHJvbGxlciAgICAgICAgICAgICAgICAg
     ICAgICAgICAgICAgTG9hZEJhbGFuY2VyICAgMTAuMjMzLjE3Ljg0ICAgIDE5Mi4xNjguMS4zNSAg
     IDgwOjMxOTE2L1RDUCw0NDM6MzE3OTQvVENQICAgICAyM2ggICBhcHAua3ViZXJuZXRlcy5pby9j
     b21wb25lbnQ9Y29udHJvbGxlcixhcHAua3ViZXJuZXRlcy5pby9pbnN0YW5jZT1pbmdyZXNzLW5n
     aW54LGFwcC5rdWJlcm5ldGVzLmlvL25hbWU9aW5ncmVzcy1uZ
```

Respostas:
> Palavras-chave: from-literal, from-file

```bash
kubectl create secret generic meusegredo -n segredosdesucesso --from-literal segredo=azul --from-file=chave-secreta
```

### ```13``` - qual a linha de comando para criar um configmap chamado `configsite` no namespace `site`. Deve conter uma entrada `index.html` que contenha seu nome.

Respostas:
> Palavras-chave: from-file

```bash
kubectl create configmap configsite -n site --from-file index.html
```
```yaml
apiVersion: v1
data:
  index.html: |
    wesley
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: configsite
  namespace: site
```

### ```14``` - crie um recurso chamado `meudeploy`, com a imagem `nginx:latest`, que utilize a secret criada no exercicio 11 como arquivos no diretorio `/app`.

Respostas:
> Palavras-chave: volume, secretName

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: meudeploy
  name: meudeploy
  namespace: segredosdesucesso
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meudeploy
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: meudeploy
    spec:
      containers:
      - image: nginx:latest
        name: nginx
        resources: {}
        volumeMounts:
        - name: app
          mountPath: /app
          readOnly: true
      volumes:
      - name: app
        secret:
          secretName: meusegredo
status: {}
```

### ```15``` - crie um recurso chamado `depconfigs`, com a imagem `nginx:latest`, que utilize o configMap criado no exercicio 12 e use seu index.html como pagina principal desse recurso.

Respostas:
> Palavras-chave: volumeMounts, configmap

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: depconfigs
  name: depconfigs
  namespace: site
spec:
  replicas: 1
  selector:
    matchLabels:
      app: depconfigs
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: depconfigs
    spec:
      containers:
      - image: nginx:latest
        name: nginx
        resources: {}
        volumeMounts:
        - name: index
          mountPath: /usr/share/nginx/html
      volumes:
      - name: index
        configMap:
          name: configsite
status: {}
```

### ```16``` - crie um novo recurso chamado `meudeploy-2` com a imagem `nginx:1.16` , com a label `chaves=secretas` e que use todo conteudo da secret como variavel de ambiente criada no exercicio 11.

Respostas:
> Palavras-chave: envFrom, secretRef

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: meudeploy-2
    chaves: secretas
  name: meudeploy-2
  namespace: segredosdesucesso
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meudeploy-2
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: meudeploy-2
    spec:
      containers:
      - image: nginx:1.16
        name: nginx
        resources: {}
        envFrom:
        - secretRef:
            name: meusegredo
status: {}
```

### ```17``` - Linhas de comando que;

    crie um namespace `cabeludo`;
    um deploy chamado `cabelo` usando a imagem `nginx:latest`; 
    uma secret chamada `acesso` com as entradas `username: pavao` e `password: asabranca`;
    exponha variaveis de ambiente chamados USUARIO para username e SENHA para a password.

Respostas:
> Palavras-chave: set, env, patch, type, json

```bash
kubectl create namespace cabeludo

kubectl create deployment cabelo --image nginx:latest -n cabeludo

kubectl create secret generic acesso --from-literal username=pavao --from-literal password=asabranca

kubectl set env --from=secret/acesso deployment/cabelo -n cabeludo

kubectl patch deployment cabelo --type=json -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/0/name", "value": "SENHA"}]' -n cabeludo

kubectl patch deployment cabelo --type=json -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/1/name", "value": "USUARIO"}]' -n cabeludo
```

### ```18``` - crie um deploy `redis` usando a imagem com o mesmo nome, no namespace `cachehits` e que tenha o ponto de montagem `/data/redis` de um volume chamado `app-cache` que NÂO deverá ser persistente.

Respostas:
> Palavras-chave: volume, emptyDir

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: redis
  name: redis
  namespace: cachehits
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: redis
    spec:
      containers:
      - image: redis
        name: redis
        resources: {}
        volumeMounts:
        - name: app-cache
          mountPath: /data/redis
      volumes:
      - name: app-cache
        emptyDir: {}
status: {}
```

### ```19``` - com uma linha de comando escale um deploy chamado `basico` no namespace `azul` para 10 replicas.

Respostas:
> Palavras-chave: scale, replicas

```bash
kubectl scale --replicas=10 deployment basico -n azul
```

### ```20``` - com uma linha de comando, crie um autoscale de cpu com 90% de no minimo 2 e maximo de 5 pods para o deploy `site` no namespace `frontend`.

Respostas:
> Palavras-chave: autoscale, cpu-percent

```bash
kubectl autoscale deployment site --min=2 --max=5 --cpu-percent=90 -n frontend
```

### ```21``` - com uma linha de comando, descubra o conteudo da secret `piadas` no namespace `meussegredos` com a entrada `segredos`.

Respostas:
> Palavras-chave: get, jsonpath, base64

```bash
kubectl get secrets/piadas -o jsonpath="{.data.segredos}" -n meussegredos | base64 -d
```

### ```22``` - marque o node o nó `k8s-worker1` do cluster para que nao aceite nenhum novo pod.

Respostas:
> Palavras-chave: taint, NoSchedule

```bash
kubectl taint nodes k8s-worker1 key1=value1:NoSchedule
```

### ```23``` - esvazie totalmente e de uma unica vez esse mesmo nó com uma linha de comando.

Respostas:
> Palavras-chave: taint, NoExecute

```bash
kubectl taint nodes k8s-worker1 key1=value1:NoExecute
```

### ```24``` - qual a maneira de garantir a criaçao de um pod ( sem usar o kubectl ou api do k8s ) em um nó especifico.

Respostas:
> Palavras-chave: static-pod, nó, manifests

______
Através do << **static-pod** >>, que, em resumo, consite em usar o kubelet para criar o pod determinado, enviando o arquivo yaml do pod para o diretório */etc/kubernetes/manifests* de um nó específico.
______

### ```25``` - criar uma serviceaccount `userx` no namespace `developer`. essa serviceaccount só pode ter permissao total sobre pods (inclusive logs) e deployments no namespace `developer`. descreva o processo para validar o acesso ao namespace do jeito que achar melhor.

Respostas:
> Palavras-chave: serviceaccount, clusterrole, clusterrolebinding

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: null
  name: userx
  namespace: developer

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: userx
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - pods/log
  verbs:
  - '*'
- apiGroups:
  - apps
  resources:
  - deployments
  - deployments/log
  verbs:
  - '*'

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: userx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: userx
subjects:
- kind: ServiceAccount
  name: userx
  namespace: developer
```

```bash
# A validação é feita através da exportação e uso do token do serviceAccount "userx"

kubectl create token userx

export NAMESPACE_SA=developer

export TEAM_SA=userx

$ export TOKEN=$(kubectl get $(kubectl get secret -o name -n ${NAMESPACE_SA} | grep  ${TEAM_SA} ) -o jsonpath='{.data.token}' -n ${NAMESPACE_SA} | base64 -d)

kubectl --token=${TOKEN} get deploy,pod -n developer
```

### ```26``` - criar a key e certificado cliente para uma usuaria chamada `jane` e que tenha permissao somente de listar pods no namespace `frontend`. liste os comandos utilizados.

Respostas:
> Palavras-chave: openssl, CR, CRB, set-credentials, set-context

```bash

openssl genrsa -out jane.key 2048

openssl req -new -key jane.key -out jane.csr

# Dentro de um nó master
---
openssl x509 -req -in jane.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out jane.crt -days 500
---

kubectl create clusterrole jane --verb=list --resource=pods -n frontend

kubectl create clusterrolebinding jane --clusterrole jane --user jane

kubectl config set-credentials jane --client-certificate=jane.crt --client-key=jane.key

kubectl config set-context jane-context --cluster=kind-meuk8s --namespace=frontend --user=jane
```

### ```27``` - qual o `kubectl get` que traz o status do scheduler, controller-manager e etcd ao mesmo tempo

Respostas:
> Palavras-chave: component, stat, uses

```bash
kubectl get componentstatuses
```