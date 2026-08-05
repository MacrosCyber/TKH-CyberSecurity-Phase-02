# SABOTAGE: Bloated base image running as root by default
FROM node:alpine

WORKDIR /usr/src/app

COPY . .

EXPOSE 8080
USER node
CMD [ "node", "app.js" ]