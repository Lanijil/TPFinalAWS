# Image non-root écoutant sur 8080 par défaut.
# Deux avantages pour le projet :
#  - port 8080 conforme au TP1 ;
#  - passe la ClusterPolicy Kyverno restrict-security-context (runAsNonRoot)
#    côté Kubernetes, sans adaptation.
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html   /usr/share/nginx/html/index.html

EXPOSE 8080
