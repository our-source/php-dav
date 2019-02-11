[![Docker Pulls](https://img.shields.io/docker/pulls/oursource/php-dav.svg)](https://hub.docker.com/r/oursource/php-dav/)
[![Docker layers](https://images.microbadger.com/badges/image/oursource/php-dav.svg)](https://microbadger.com/images/oursource/php-dav)
[![Github Stars](https://img.shields.io/github/stars/our-source/php-dav.svg?label=github%20%E2%98%85)](https://github.com/our-source/php-dav/)
[![Github Stars](https://img.shields.io/github/contributors/our-source/php-dav.svg)](https://github.com/our-source/php-dav/)

# A DAV enabled PHP image

## How to use

A unprotected php image that has a dav path `/dav` that points to
the root directory `/var/www/html` for updatting and manipulating the php source.

## Kubernetes example

```yaml
---

apiVersion: v1
kind: ConfigMap
metadata:
  name: php-dav-conf
data:
  webdav.conf: |-
    DavLockDB /tmp/DavLock

    Alias /dav /var/www/html
    <Location /dav>
      # Enable dav
      DAV On
      DirectorySlash Off
      php_admin_value engine Off
    </Location>

    <Directory "/var/www/html">
      Options Indexes MultiViews
      AllowOverride None
      Require all granted
    </Directory>

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: php-dav-rook-ceph-block
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---

apiVersion: v1
kind: Service
metadata:
  name: php-dav
  labels:
    app: php-dav
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: php-dav

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-dav
spec:
  # Stop old container before starting new one
  # The storage block used does allow only one access
  strategy:
    type: Recreate
    rollingUpdate: null
  selector:
    matchLabels:
      app: php-dav
  replicas: 1
  template:
    metadata:
      labels:
        app: php-dav
    spec:
      containers:
      - name: php-dav
        image: oursource/repository:latest
        imagePullPolicy: IfNotPresent
        resources:
          requests:
            cpu: 25m
            memory: 50Mi
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /var/www/html/
          name: php-dav-rook-ceph-block
        - mountPath: /etc/apache2/conf-enabled/php-dav.conf
          name: php-dav-conf
        livenessProbe:
          failureThreshold: 3
          initialDelaySeconds: 10
          periodSeconds: 2
          successThreshold: 1
          tcpSocket:
            port: 80
          timeoutSeconds: 2
      volumes:
      - name: php-dav-rook-ceph-block
        persistentVolumeClaim:
          claimName: php-dav-rook-ceph-block
      - configMap:
          defaultMode: 256
          name: php-dav-conf
          optional: false
        name: php-dav-conf

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: php-dav-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/whitelist-source-range: 172.31.0.0/16
spec:
  rules:
  - host: php-dav.example.com
    http:
      paths:
      - backend:
          serviceName: 
          servicePort: 80
  tls:
  - hosts:
    - php-dav.example.com
    secretName: php-dav
```

Apply this config with: `$ kubectl apply -f config.yaml`
