# Elasticsearch Init Docker

Available Environment Variables:
- `DB_IMAGE`: Base image. Defaults to `elasticsearch:7.14.0`.
- `REGISTRY`: docker registry. Defaults to `kubedb`.  
- `BIN`: new image docker repository. Defaults to `elasticsearch-init`.
- `TAG`: new image tag.
- `ES_PLUGINS`: comma separated plugin names needs to be installed. Defaults to empty list (`""`).

Available Commands:
- `make container`: Build the docker image.
- `make push`: Build the docker image and push to targeted registry.

Samples:

Make a custom elasticsearch image with plugins `repository-azure` and `repository-s3`. Push the new image to your docker registry. 
```bash
$ export DB_IMAGE=elasticsearch:7.14.0
$ export REGISTRY=kamolhasan
$ export BIN=custom-elasticsearch
$ export TAG=7.14.0
$ export ES_PLUGINS="repository-azure, repository-s3"

$ make push
...
...
Successfully tagged kamolhasan/custom-elasticsearch:7.14.0
docker push kamolhasan/custom-elasticsearch:7.14.0
... ... 
```

## Use in ElasticsearchVersion CRD

Update both `spec.db.image` and `spec.initContainer.yqImage` images with the custom build image to make your custom ElasticsearchVersion CR which you can refer from KubeDB managed Elasticsearch instance.  
```yaml
apiVersion: catalog.kubedb.com/v1alpha1
kind: ElasticsearchVersion
metadata:
  name: custom-xpack-7.14.0
spec:
  authPlugin: X-Pack
  db:
    # update here
    image: kamolhasan/custom-elasticsearch:7.14.0
  distribution: ElasticStack
  exporter:
    image: prometheuscommunity/elasticsearch-exporter:v1.2.1
  initContainer:
    image: tianon/toybox:0.8.4
    # update here
    yqImage: kamolhasan/custom-elasticsearch:7.14.0
  podSecurityPolicies:
    databasePolicyName: elasticsearch-db
  securityContext:
    runAsAnyNonRoot: true
    runAsUser: 1000
  stash:
    addon:
      backupTask:
        name: elasticsearch-backup-7.3.2
      restoreTask:
        name: elasticsearch-restore-7.3.2
  version: 7.14.0
```
