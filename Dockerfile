FROM node:16

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install mongoose

RUN npm install express

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "nodeapp.js"]
