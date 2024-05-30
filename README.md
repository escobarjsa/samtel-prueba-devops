# Prueba Samtel

[Reto](https://github.com/JefryGG1K91/first-filter/blob/main/README.md "Reto")

## Ajuste a nivel de proyecto
Se utilizó el proyecto https://github.com/docker/awesome-compose/tree/master/angular para la prueba, el cual está en Angular 13. Además, se crearon los siguientes archivos:

- Dockerfile
- nginx.conf
- nginx-custom.conf

El archivo Dockerfile utilizado:

```
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

```
## Ajuste SonarQube

Se utilizo SonarQube 9.9.5 LTA, se descargo de la pagina https://www.sonarsource.com/products/sonarqube/downloads/
[![1.png](https://i.postimg.cc/Qt5c5XXz/1.png)](https://postimg.cc/LY9qFFgk)

## Ajuste a nivel de infraestructura

se instala minikube siguiendo la documentación oficial de [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download "minikube"),  adicionalmente se crea el contexto para poder usar minikube con el comando `docker context create default`

Se realizo la creación del Service Connection con Azure DevOps obteniendo el kubeconfig de Minikube, con el comando `C:\Users\<tu_usuario>\.kube\config
`

[![3.png](https://i.postimg.cc/Gtq8P6GG/3.png)](https://postimg.cc/hQQtcyCt)

## Ajuste a nivel de pipeline en Azure DevOps

El pipeline de integración continua y despliegue creado es el siguiente:

```yaml
trigger:
- master

pool:
  name: 'jescobar-pool'  # Grupo de agentes de Azure Pipelines.
  # vmImage: ubuntu-latest

stages:

# Etapada de integración continua
- stage: CI
  jobs:
  - job: Build

    steps:
      # Instala una versión específica de Node.js en el agente de compilación.
      - task: NodeTool@0
        displayName: 'Install Node Version: $(NODE_VERSION)'
        inputs:
          versionSource: 'spec'
          versionSpec: '$(NODE_VERSION)'

# Prepara el análisis del código con SonarQube, una herramienta para revisar y mejorar la calidad del código.
      - task: SonarQubePrepare@5
        displayName: 'Prepare Analysis on SonarQube'
        inputs:
          SonarQube: 'sonarqube-escobarpc'
          scannerMode: 'CLI'
          configMode: 'manual'
          cliProjectKey: 'AzureSonarDemoSamtel'
          cliProjectName: 'AzureSonarDemoSamtel'
          cliSources: 'src/'
          extraProperties: |
            sonar.exclusions=**/node_modules/**
            sonar.test.inclusions=**/*.spec.ts
            sonar.tests=src/app
            # sonar.testExecutionReportPaths=.\coverage\lcov.info
            # sonar.javascript.lcov.reportPaths=.\coverage\lcov.info
            # sonar.javascript.lcov.reportPaths=$(System.DefaultWorkingDirectory)\coverage\lcov.info
            sonar.javascript.lcov.reportPaths=C:\agent\agent-jescobar\_work\1\s\coverage\lcov.info
            # sonar.qualitygate.wait=true
            # sonar.qualitygate.timeout=900

      # Ejecuta el comando de compilación de Angular.
      - task: CmdLine@2
        displayName: 'Install Dependencies'
        inputs:
          script: 'npm install'
          workingDirectory: $(System.DefaultWorkingDirectory)
      
      # Ejecuta el comando de compilación de Angular.
      - task: CmdLine@2
        displayName: 'Build Angular App'
        inputs:
          script: 'npm run build'
          workingDirectory: $(System.DefaultWorkingDirectory)

      # Ejecuta pruebas unitarias utilizando Karma, una herramienta de prueba para aplicaciones Angular.
      - task: CmdLine@2
        displayName: 'Executing Unit Test And Coverage'
        inputs:
          script: |
            $(BUILD_UNIT_TEST_COMMAND)
          workingDirectory: $(System.DefaultWorkingDirectory)
        continueOnError: true

      # Modifica las variables de entorno para el análisis en SonarQube.
      - task: PowerShell@2
        displayName: 'Activate Analysis On SonarQube'
        inputs:
          targetType: 'inline'
          script: |
            $params = "$env:SONARQUBE_SCANNER_PARAMS" -replace '"sonar.branch.name":"[\w,/,-]*"\,?'
                Write-Host "##vso[task.setvariable variable=SONARQUBE_SCANNER_PARAMS]$params"

      # Ejecuta el análisis del código con SonarQube, una herramienta para revisar y mejorar la calidad del código.
      - task: SonarQubeAnalyze@5
        displayName: 'Run Static Code Analysis'
        # continueOnError: true

      # Publica los resultados del análisis del código en SonarQube.
      - task: SonarQubePublish@5
        displayName: 'Publish Quality Gate Result'
        # continueOnError: true
        inputs:
          pollingTimeoutSec: '400'
        
      #Publica los artefactos de compilación, como los archivos de distribución de la aplicación.
      - task: PublishBuildArtifacts@1
        displayName: 'Publish Artifacts'
        inputs:
          PathtoPublish: '$(Build.SourcesDirectory)/dist'
          ArtifactName: '$(artifactsName)'
          publishLocation: 'Container'

# Etapada de despliegue continuo
- stage: 'CD'
  displayName: Deploy
  jobs:
  - job: 'deployment'
    displayName: 'Deploy' 
    steps:

    # Tarea para construir una imagen Docker y subir a DockerHub
    - task: Docker@2
      displayName: 'Docker Build And Push to Docker Hub'
      inputs:
        containerRegistry: 'docker-hub-escobarjsa'
        repository: 'escobarjsa/samtel-prueba'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: 'latest'

    # Tarea para logearse en Kubernetes.
    - task: Kubernetes@1
      displayName: 'K8s Login'
      inputs:
        connectionType: 'Kubernetes Service Connection'
        kubernetesServiceEndpoint: 'kubernetes-escobarpc-local'
        namespace: '$(namespace)'
        command: 'login'
    
    #Tarea para reiniciar un despliegue en Kubernetes.
    - task: CmdLine@2
      displayName: 'K8s Restart'
      inputs:  
        script: 'kubectl --insecure-skip-tls-verify rollout restart deployment/angular-app -n=$(namespace)'  # Comando para reiniciar un despliegue en Kubernetes usando 'kubectl', especificando el despliegue y el namespace.

    # Script que crea 10 archivos con la fecha y luego lo imprima en consola
    - powershell: |
        for ($i = 1; $i -le 10; $i++) {
          $date = Get-Date
          $date > "file_$i.txt"
        }
        Get-ChildItem -Path . -Filter "file_*.txt"
      displayName: 'Create and List Files'

    # Imprime Hola Mundo 10 veces en pantalla con un job paralelo
  - job: ParallelJobs
    strategy:
      parallel: 10
    steps:
    - script: echo "Hola Mundo"
      displayName: 'Print Hola Mundo'
  


```

Las variables usadas son artifactsName,  BUILD_UNIT_TEST_COMMAND, namespace, NODE_VERSION.

[![4.png](https://i.postimg.cc/VkmrqQ2D/4.png)](https://postimg.cc/F7CHvqrL)


## Resultados del pipeline

Resultados obtenidos a nivel de ejecución del pipeline en el apartado de integración continua son:

- Pipeline CI

[![5.png](https://i.postimg.cc/Pfb8P5RP/5.png)](https://postimg.cc/6T3QPtwX)

- Artefacto generado después de generar el proceso de integración continua.

[![6.png](https://i.postimg.cc/9QwmwxQJ/6.png)](https://postimg.cc/nXZb6G7D)

- Extesión para verificar los resultados de SonarQube.

[![7.png](https://i.postimg.cc/kGt6cWNm/7.png)](https://postimg.cc/gLm2cXBS)

- Resultados SonarQube.

[![8.png](https://i.postimg.cc/hPdZJwdC/8.png)](https://postimg.cc/sv34qTKS)

[![9.png](https://i.postimg.cc/brxhRv5J/9.png)](https://postimg.cc/SYx3SmkF)

Los resultados obtenidos a nivel de ejecución del pipeline en el apartado de despliegue continuo son:

[![stage-ci.gif](https://i.postimg.cc/RCtjkNZp/stage-ci.gif)](https://postimg.cc/Yjpng2gQ)

Se deja tambien un video en la carpeta img para ver en mejor resolución los pasos ejecutados con el nombre de stage_cd.mp4.

Se anexa la segunda parte del reto.

[![screencast-dev-azure-com-2024-05-30-17-10-32.gif](https://i.postimg.cc/WpSGScBW/screencast-dev-azure-com-2024-05-30-17-10-32.gif)](https://postimg.cc/pyh5X4Xz)

Se deja tambien un video en la carpeta img para ver en mejor resolución los pasos ejecutados con el nombre de stage_cd2.mp4.

## Resultados Kubernetes

Los resultados obtenidos en kubernetes son:

- Dashboard de Kubernetes.

[![10.png](https://i.postimg.cc/G2Rq6Jhb/10.png)](https://postimg.cc/4K869c90)

- Verificación del ingress.

[![11.png](https://i.postimg.cc/gJ4fYkJX/11.png)](https://postimg.cc/2bbHGYnr)

- iniciando en la ruta https://aplicacion-local.com/.

[![12.png](https://i.postimg.cc/bwNLhHnT/12.png)](https://postimg.cc/VdpX9tDr)

## Recursos

Se adjuntan el recurso para consultar la ejecución:

-  [Pipeline prueba Samtel](https://dev.azure.com/celuladevopsj/samtel-prueba/_build?definitionId=145 "Pipeline prueba Samtel")

- se crea una carpeta con el nombre de "Entregable", que contine:
  - Pipeline creado en YML.
  - Carpeta environment con los archivos k8s.
  - Carpeta Log con los logs.
  - Carpeta videos con los videos de la ejecución.


# Angular

This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 13.0.1.

## Development server

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The app will automatically reload if you change any of the source files.

## Code scaffolding

Run `ng generate component component-name` to generate a new component. You can also use `ng generate directive|pipe|service|class|guard|interface|enum|module`.

## Build

Run `ng build` to build the project. The build artifacts will be stored in the `dist/` directory.

## Running unit tests

Run `ng test` to execute the unit tests via [Karma](https://karma-runner.github.io).

## Running end-to-end tests

Run `ng e2e` to execute the end-to-end tests via a platform of your choice. To use this command, you need to first add a package that implements end-to-end testing capabilities.

## Further help

To get more help on the Angular CLI use `ng help` or go check out the [Angular CLI Overview and Command Reference](https://angular.io/cli) page.
