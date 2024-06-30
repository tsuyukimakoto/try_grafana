# Define the provider
provider "google" {
  project     = var.project_id
  region      = "asia-northeast1"
}

# TF_VARでセットする変数
# TF_VAR_project_id=<Google CloudのProject_id> TF_VAR_grafana_settings_bucket_name=<gcsのバケット名> TF_VAR_google_artifact_registry_repository_name=<Artifact Registryに作るRepository名> TF_VAR_image_name=<Dockerのイメージ名> terraform apply
variable "project_id" {
  description = "The project ID"
}
variable "grafana_settings_bucket_name" {
  description = "The name of the Grafana settings bucket"
}
variable "google_artifact_registry_repository_name" {
  description = "The name of the Google Artifact Registry repository"
}
variable "image_name" {
  description = "The name of the image to be deployed"
}


# CloudRunのサービス。イメージをpushしていないと起動できないため
# 1. このresourceとgoogle_cloud_run_service_iam_memberリソースをコメントアウトした状態でterraform applyする
# 2. イメージをpushする
# 3. イメージをpushしたらコメントアウトを外す
# 4. terraform applyする
resource "google_cloud_run_service" "my_service" {
  name     = "grafana-cloud-run"
  location = "asia-northeast1"
  template {
    metadata {
      annotations = {
        # 複数インスタンスが起動しないように
        "autoscaling.knative.dev/maxScale" = "1"
      }
    }
    spec {
      service_account_name = google_service_account.cloudrun_service_account.email
      containers {
        image = format(
          "asia-northeast1-docker.pkg.dev/%s/%s/%s:latest",
          var.project_id,
          var.google_artifact_registry_repository_name,
          var.image_name
        )
      }
    }
  }
  depends_on = [
    google_storage_bucket.grafana_settings_bucket
  ]
}

# Cloud Runのサービスをインターネットに公開する（最初のterraform applyではコメントアウトしておく）
resource "google_cloud_run_service_iam_member" "noauth" {
  service = google_cloud_run_service.my_service.name
  location = google_cloud_run_service.my_service.location
  role = "roles/run.invoker"
  member = "allUsers"  # ClourRunのサービスを認証無しで公開
}

# Artifact RegistryにDockerフォーマットのリポジトリを作成
resource "google_artifact_registry_repository" "my_repository" {
  provider = google
  location = "asia-northeast1"
  repository_id = var.google_artifact_registry_repository_name
  format = "DOCKER"
}

# Grafanaの設定ファイルを保存するGCSバケット（Litestreamがレプリカを置く場所）
resource "google_storage_bucket" "grafana_settings_bucket" {
  name     = var.grafana_settings_bucket_name
  location = "asia-northeast1"
  storage_class = "STANDARD"
  force_destroy = true # 必要に応じてfalseに
}

# Cloud Run起動用のサービスアカウント
resource "google_service_account" "cloudrun_service_account" {
  account_id   = "forcloudrun"
  display_name = "Cloud Run use GCS"
}

# Cloud RunのサービスがGCSにアクセスできるように権限を付与
resource "google_storage_bucket_iam_member" "grafana_bucket_iam" {
  bucket = google_storage_bucket.grafana_settings_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloudrun_service_account.email}"
}
