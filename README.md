# cloud-terraform-lab

S3 事件 → Lambda → 元数据 JSON 的实验项目，配套 GitHub Actions CI/CD。

架构：

```
S3 桶 mycompany-dev-source1
   └─ incoming/…            上传对象
          ↓ S3 事件通知（仅 incoming/ 前缀，避免自我触发递归）
   Lambda pdf-metadata-cataloger（Python 3.12）
          ↓ 写入
   metadata/<bucket>/<key>/<sequencer>.json
```

## 需求对照

| 需求 | 实现方式 | 位置 |
| --- | --- | --- |
| 1. PR 格式与校验检查，且不需要 AWS 凭证 | `pull_request` 触发；`terraform fmt -check -recursive` + `terraform init -backend=false` + `terraform validate` + Python 语法检查。**没有** `id-token`、**不引用任何** secret，init 不连后端 | `.github/workflows/pr-checks.yml` |
| 2. 从 main 手动部署，使用 OIDC 角色 | `workflow_dispatch` + `if: github.ref == 'refs/heads/main'` + `aws-actions/configure-aws-credentials`（`permissions: id-token: write`），不存任何长期密钥 | `.github/workflows/deploy.yml` |
| 3. 初始化既有 S3 后端，使用本组唯一 state key 与 `use_lockfile` | `backend "s3"`：bucket `mycompany-tfstate-289138883270`、key `terraform.tfstate`、`use_lockfile = true`（Terraform ≥ 1.10 的 S3 原生锁，无需 DynamoDB） | `backend.tf` |
| 4. 生成保存的 plan，并把 plan / provider lock file / Lambda ZIP 传给 apply job | `terraform plan -out=tfplan`，随后 `upload-artifact` 上传 `tfplan`、`plan.txt`、`.terraform.lock.hcl`、`module/lambda/lambda.zip`（`include-hidden-files: true`，否则 lock 文件会被静默跳过） | `deploy.yml` 的 plan job |
| 5. 审阅 plan 并批准 `lab-apply` 环境后才 apply | plan 全文渲染进 `$GITHUB_STEP_SUMMARY`（审批人直接在 run 页面读）；apply job 声明 `environment: lab-apply`，由 Environment 的 Required reviewers 阻断 | `deploy.yml` 的 apply job |
| 6. apply 保存的 plan，而不是重新 plan | `terraform apply tfplan`，全程没有第二次 plan；provider 版本由传过来的 lock file 保证一致 | `deploy.yml` 的 apply job |
| 7. 独立的销毁入口，且需要显式确认 | 单独的 workflow：必须手打确认串 `DELETE-TEST-DATA`（guard job 校验），再经 `environment: lab-destroy` 人工审批 | `.github/workflows/destroy.yml` |

> 注意：CI 里统一用环境变量 `TF_INPUT=false`，而不是 `-input=false`。
> 在 Windows 上实测 `terraform plan -input=false …` 会报
> `Too many command line arguments`，用环境变量等效且可靠。

## 一次性设置

1. **GitHub Secrets / Variables**（Settings → Secrets and variables → Actions）
   - Secret `AWS_ROLE_ARN` = `arn:aws:iam::289138883270:role/github-actions-lab-role`
   - Variable `AWS_REGION` = `us-west-2`
2. **GitHub Environments**（Settings → Environments）
   - `lab-apply`：Required reviewers
   - `lab-destroy`：Required reviewers
3. **IAM 角色信任策略**只允许 `repo:emolastuff15/terraform:ref:refs/heads/main`（OIDC，`aud = sts.amazonaws.com`）
4. **state 桶**（bootstrap，不归本配置管理）：`mycompany-tfstate-289138883270`，已开启版本控制、AES256 加密、屏蔽公开访问

## 本地使用

需要 Terraform ≥ 1.10（本项目固定 1.16.5）：

```bash
terraform init      # 连接 S3 后端
terraform plan
terraform apply
```

销毁测试数据：

```bash
terraform destroy   # 桶已设置 force_destroy = true，会连同对象一起删除
```

或者走 GitHub Actions 的 **Destroy (deletes test data)** workflow（带确认串与环境审批）。
