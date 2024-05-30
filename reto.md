#Prueba-Dummy

###Contar con las siguientes herramientas instaladas.
* Sonarqube
* Organización de azure DevOps.
* Docker.
* Azure Agent Pool SelfHosted
* Kubernetes
* Minikube / Hypervisor / Nube con conexión a Azure DevOps


`Utiliza un repositorio del siguiente link del apartado de framework https://docs.docker.com/samples/`

####Procedimento

1.	Descarga los archivos del repositorio elegido.
2.	Instala el framework necesario en caso de no tenerlo.
3.	Compila la aplicación luego de pasar el analisis de sonarqube.
    * Agregar dos escenarios 1 - analisis fallido | 2 - analisis exitoso
4.  Genera una imagen de docker y sube la imagen a dockerhub/ACR/ECR desde el pipeline yaml.
5.	Dentro del pipeline ejecute lo siguiente en bash o powershell.
    a.	Imprime `Hola Mundo` 10 veces en pantalla con un job paralelo. 
    b.	Script que cree 10 archivos con la fecha y luego lo imprima en consola
6.	Despliega la app a un clúster de kubernetes (minikube o EKS o AKS).
7.	Crea un endpoint externo accesible (ingress) para la aplicación
8.  Sube al repo en una carpeta `environment` todos los yaml de k8s.

####Que se espera del ejercicio

1.	Configuración de la infraestructura desde cero.
2.	Documentación para crear solución y demostración de la aplicación funcionando.
3.	Coding Standards.
4.	Enfoque hacia la meta.

####Bonus para tomar en consideración
1.	Construye un clúster de kubernetes usando IaC (terraform o eksctl).
2.	Usa un manejador de templates como Kustomize o Helm.
3.	Despliega en nube publica (AWS o Azure).
4.	Que sea accesible desde internet.
5.	Uso de metodologías DevOps.

####Resultados que debes adjuntar

1. Codigo
2. yaml de k8s
3. Pipelines
4. Logs
5. Printscreen
6. Recording de pantalla (opcional)
7. Compartir repositorio de github publico para evaluación