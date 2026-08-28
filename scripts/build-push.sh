#!/usr/bin/env bash
set -euo pipefail

REGION="${REGION:-us-east-1}"
TAG="${1:-1.0.0}"
NAME="web-ipssi"

if [[ "$TAG" == "latest" ]]; then
  echo "Tag 'latest' interdit (politique projet)." >&2
  exit 1
fi

echo "==> Verification de la session AWS Academy"
aws sts get-caller-identity >/dev/null || {
  echo "Session expiree ou credentials absents. Rafraichir via AWS Details." >&2
  exit 1
}

echo "==> Recuperation de l'URL du depot ECR"
ECR_URL=$(terraform output -raw ecr_repository_url)
REGISTRY="${ECR_URL%/*}"

echo "==> Build de l'image ${NAME}:${TAG}"
docker build -t "${NAME}:${TAG}" ./app

echo "==> Push vers ECR"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"
docker tag "${NAME}:${TAG}" "${ECR_URL}:${TAG}"
docker push "${ECR_URL}:${TAG}"

echo "==> Chargement dans Minikube (meme image, sans passer par ECR)"
if minikube status >/dev/null 2>&1; then
  minikube image load "${NAME}:${TAG}"
else
  echo "  Minikube arrete : etape ignoree."
fi

echo "==> Termine. Image disponible sur les deux cibles en ${TAG}"
