# try_grafana

see: https://www.tsuyukimakoto.com/blog/2024/06/30/cloudrun-and-litestream/


## What is this repository?

Grafana is a visualization tool commonly used in the field of Monitoring/Observability.

By default, it uses SQLite, so we will try to start Grafana using Litestream.

## Set up the environment with Terraform

Note: It is simplified, so we recommend creating a dedicated Google Cloud project. Proceed at your own risk.

Here's the Terraform. Comment out the google_cloud_run_service and google_cloud_run_service_iam_member resources, and run Terraform in the Terraform folder.

You will encounter an error message asking to enable the service. Manually enable Cloud Run from the console and try again several times.

```sh
$ terraform init
$ TF_VAR_project_id=<Google Cloud Project_id> TF_VAR_grafana_settings_bucket_name=<gcs bucket name> TF_VAR_google_artifact_registry_repository_name=<Artifact Registry Repository name> TF_VAR_image_name=<Docker image name> terraform apply
```

Four resources will be created.

## Creating the Container Image

Modify the Litestream configuration file

Change the GCS bucket name to the bucket name created with Terraform.

Modify &lt;GRAFANA_SETTINGS_BUCKET_NAME&gt;.

```yaml
url: gcs://<GRAFANA_SETTINGS_BUCKET_NAME>/grafana.db
Build and push the Docker image
Run the following commands in the directory containing the Dockerfile.
```

Since I am using an Apple Silicon Mac, I add --platform linux/amd64, but this is not necessary for Intel Macs or Linux.

```sh
$ docker build --platform linux/amd64 . -t <Docker image name>
$ docker tag <Docker image name> asia-northeast1-docker.pkg.dev/<Google Cloud Project_id>/<Repository name created in Artifact Registry>/<Docker image name>
$ docker push asia-northeast1-docker.pkg.dev/<Google Cloud Project_id>/<Repository n
```

## Starting the Cloud Run Service with Terraform

Enable the previously commented out resources and run terraform apply again using the same commands as before.

```sh
$ TF_VAR_project_id=<Google Cloud Project_id> TF_VAR_grafana_settings_bucket_name=<GCS bucket name> TF_VAR_google_artifact_registry_repository_name=<Repository name created in Artifact Registry> TF_VAR_image_name=<Docker image name> terraform apply
```


## Verify the operation

Check the URL of the Cloud Run service from the Google Cloud console and access the URL.

