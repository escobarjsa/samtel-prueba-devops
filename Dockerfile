# Stage 1: Build
# Utilizamos una imagen Node.js para compilar la aplicación Angular
FROM node:14-alpine AS build

WORKDIR /app

# Copiamos el archivo package.json y package-lock.json para instalar las dependencias
COPY package*.json ./

RUN npm install

# Copiamos todos los archivos de la aplicación Angular
COPY . .

# Ejecutamos el comando de compilación para generar la aplicación Angular optimizada para producción
RUN npm run build

# Stage 2: RUN
# Utilizamos una imagen Nginx para servir la aplicación Angular
FROM nginx:latest AS nginx

# Eliminamos los archivos existentes en el directorio de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiamos los archivos generados en la etapa de construcción (Stage 1) al directorio de Nginx
COPY --from=build /app/dist/* /usr/share/nginx/html

# Copiamos el archivo de configuración personalizado de Nginx
COPY --from=build /app/nginx.conf /etc/nginx/conf.d/default.conf

# Exponemos el puerto 80 en el contenedor
EXPOSE 80

# Comando para iniciar Nginx en modo daemon off
CMD ["nginx", "-g", "daemon off;"]
