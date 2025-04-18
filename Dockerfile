FROM node:20

WORKDIR /app

COPY Strapi-proj/package.json ./
RUN npm install

COPY Strapi-proj ./
RUN npm run build

EXPOSE 1337
CMD ["npm", "start"]
