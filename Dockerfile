FROM nginx:1.27-alpine
COPY index.html logo.svg frog.svg /usr/share/nginx/html/
EXPOSE 80
