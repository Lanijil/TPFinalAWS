# Orchestration automatisee — ECS & Kubernetes

Deploiement d'une meme application conteneurisee sur **Amazon ECS Fargate** et sur
**Kubernetes (Minikube)**, decrit en **Terraform** et pilote par un **pipeline Jenkins** unique.

IPSSI — Mastere Cybersecurite. Binome : NOM_A (ECS) / NOM_B (Kubernetes).

## Arborescence

```
.
├── app/                  # image applicative (nginx non-root, port 8080)
├── modules/ecs/          # cible 1 : ECR + Fargate + ALB      (NOM_A)
├── modules/k8s/          # cible 2 : Deployment + Ingress + HPA (NOM_B)
├── scripts/build-push.sh # build unique -> ECR + cache Minikube
├── Jenkinsfile           # pipeline validate -> plan -> approbation -> apply
└── main.tf               # racine : providers aws + kubernetes, les deux modules
```

## Prerequis

- Terraform >= 1.5, AWS CLI v2, Docker, Minikube, kubectl
- Une session AWS Academy **demarree** (bouton Start Lab vert)

## 1. Identifiants AWS Academy

Recuperer access key / secret / session token via **AWS Details → AWS CLI**,
puis les coller dans `~/.aws/credentials`. Ils expirent a chaque fin de session.

```bash
aws sts get-caller-identity   # doit repondre avant tout terraform apply
aws configure list | grep region
```

> Une erreur `ExpiredToken` en cours d'`apply` laisse un state incoherent.
> Verifier la session avant chaque execution.

## 2. Deploiement initial (sequence en deux temps)

Le service ECS ne peut demarrer que si l'image existe deja dans ECR, alors que le
depot ECR est lui-meme cree par Terraform. On amorce donc en deux phases —
uniquement la premiere fois.

```bash
terraform init
terraform apply -target=module.ecs.aws_ecr_repository.app   # 1. le depot seul
./scripts/build-push.sh 1.0.0                               # 2. build + push
terraform apply                                             # 3. tout le reste
```

Ensuite, un simple `terraform apply` suffit : le pipeline Jenkins n'applique
que les differences (idempotence).

## 3. Verification

```bash
terraform output ecs_url          # URL de l'ALB
curl "$(terraform output -raw ecs_url)/whoami"

kubectl get deploy,svc,ingress -n prod
curl http://web.ipssi.local/whoami
```

## 4. Destruction / recreation from scratch

```bash
terraform destroy
# puis reprendre la sequence du point 2
```

## Nommage

Repris des TP : depot `web-ipssi`, cluster `ipssi-ecs`, service `web-svc`,
region `us-east-1`, execution role `LabRole`, tag d'image `1.0.0` (jamais `latest`).
