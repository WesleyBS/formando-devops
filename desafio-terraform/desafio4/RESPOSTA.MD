## 4. Assumindo recursos

Descreva abaixo como você construiria um `resource` terraform a partir de um recurso já existente, como uma instância `ec2`.

----
----
----

Para alcançar isto, utilizaria o comando `terraform import`, segundo a documentação disponível em: https://www.terraform.io/cli/import/usage.

O comando base consiste em: 

    terraform init
    terraform import aws_instance.example i-abcd1234

- **Dependências**

Subentende-se que o recurso **example** do tipo **aws_instance** já está criado e a EC2 na AWS também, cujo ID será substituido em **i-abcd1234**. O recurso **example** deverá ser criado em um módulo, seguindo a estrutura abaixo. 

OBS: É importante ressaltar que, caso o recurso esteja vinculado a outros recursos (*complex import*), será necessário criar outros blocos de *resource* para cada recurso relacionado e as informações poderiam ser adquiridas através do comando: `terraform state pull > arquivo.tfstate`

    resource "aws_instance" "example" {
        # Dados coletados na AWS
        ami = "ami"
        instance_type = "instanceType"
    }

Para tanto, também é necessário criar o **provider** e o **backend** no módulo. Ele será responsável pela a conexão com a AWS e por armazenar o state remotamente. OBS: o backend deve estar na mesma região que a EC2 desejada; para isto, deve haver um bucket S3.

    terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "4.33.0"
    }}}
    
    provider "aws" {
        region = "us-east-1"
    }

    terraform {
    backend "s3" {
        # Dados coletados na AWS
        bucket = "arquivo-tfstates"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
    }

Para que a conexão aconteça, os tokens de autenticação do usuário do IAM da AWS tem que ser fornecidos de alguma maneira. Uma das maneiras possíveis é exportando esses tokens em forma de variável de ambiente do SO:

    export AWS_ACCESS_KEY_ID=<valor_id>
    export SECRET_ACCESS_KEY=<valor_key>

- **Inserindo no controle local**

Uma vez preenchido corretamente as variáveis com os dados coletados da AWS, é o momento de inserir a máquina importada dentro do state atual. Neste momento, é importante ter cautela e revisar o plano para garantir que o recurso remoto não será apagado por um novo.

    
    terraform plan -out plano
    terrafor apply "plano"

Pronto, dessa forma a EC2 estará dentro da estrutura de controle do terraform.