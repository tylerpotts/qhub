import os
import re
import string
import random
import secrets
import tempfile
import logging

import requests

from qhub.provider.oauth.auth0 import create_client
from qhub.provider.cicd import github
from qhub.provider import git

from qhub.utils import (
    check_cloud_credentials,
)

from qhub import schema
from qhub.version import __version__

logger = logging.getLogger(__name__)


def render_config(
    project_name,
    qhub_domain,
    cloud_provider,
    ci_provider,
    repository,
    auth_provider,
    namespace=None,
    repository_auto_provision=False,
    auth_auto_provision=False,
    terraform_state=None,
    kubernetes_version=None,
    disable_prompt=False,
    ssl_cert_email=None,
):
    if project_name is None and not disable_prompt:
        project_name = input("Provide project name: ")

    if qhub_domain is None and not disable_prompt:
        qhub_domain = input("Provide domain: ")

    auth_provider = schema.AuthenticationEnum(auth_provider)
    ci_provider = schema.CiEnum(ci_provider)
    cloud_provider = schema.ProviderEnum(cloud_provider)

    qhub_config = {
        'project_name': project_name,
        # In qhub_version only use major.minor.patch version - drop
        # any pre/post/dev suffixes
        "provider": cloud_provider.value,
        "qhub_version": __version__,
        'domain': qhub_domain,
        'namespace': namespace or "dev",
        "ci_cd": schema.CICD.qhub_initialize(ci_provider),
        'theme': schema.Theme.qhub_initialize(qhub_domain, cloud_provider, project_name),
    }

    if cloud_provider == schema.ProviderEnum.local:
        qhub_config['local'] = schema.LocalProvider()
    elif cloud_provider == schema.ProviderEnum.gcp:
        qhub_config['gcp'] = schema.GoogleCloudPlatformProvider(
            kubernetes_version=kubernetes_version)
    elif cloud_provider == schema.ProviderEnum.aws:
        qhub_config['aws'] = schema.AmazonWebServicesProvider(
            kubernetes_version=kubernetes_version)
    elif cloud_provider == schema.ProviderEnum.azure:
        qhub_config['azure'] = schema.AzureProvider(
            kubernetes_version=kubernetes_version)
    elif cloud_provider == schema.ProviderEnum.do:
        qhub_config['do'] = schema.DigitalOceanProvider(
            kubernetes_version=kubernetes_version)

    if auth_provider == schema.AuthenticationEnum.password:
        auth_config = schema.PasswordAuthentication.qhub_initialize()
    elif auth_provider == schema.AuthenticationEnum.github:
        auth_config = schema.GitHubAuthentication.qhub_initialize(
            qhub_domain=qhub_domain,
            auto_provision=auth_auto_provision,
            disable_prompt=disable_prompt)
    elif auth_provider == schema.AuthenticationEnum.auth0:
        auth_config = schema.Auth0Authentication.qhub_initialize(
            qhub_domain=qhub_domain,
            project_name=project_name,
            auto_provision=auth_auto_provision,
            disable_prompt=disable_prompt)

    qhub_config['security'] = schema.Security(
        authentication=auth_config)

    if terraform_state is not None:
        qhub_config["terraform_state"] = schema.TerraformState(
            type=schema.TerraformStateEnum(terraform_state)
        )

    # # Save default password to file
    # default_password_filename = os.path.join(
    #     tempfile.gettempdir(), "QHUB_DEFAULT_PASSWORD"
    # )
    # with open(default_password_filename, "w") as f:
    #     f.write(default_password)
    # os.chmod(default_password_filename, 0o700)

    # print(
    #     f"Securely generated default random password={default_password} for Keycloak root user stored at path={default_password_filename}"
    # )

    if ssl_cert_email is not None:
        qhub_config["certificate"] = schema.Certificate(
            type=schema.CertificateEnum.letsencrypt,
            acme_email=ssl_cert_email)

    # if repository_auto_provision:
    #     GITHUB_REGEX = "(https://)?github.com/([^/]+)/([^/]+)/?"
    #     if re.search(GITHUB_REGEX, repository):
    #         match = re.search(GITHUB_REGEX, repository)
    #         git_repository = github_auto_provision(
    #             config, match.group(2), match.group(3)
    #         )
    #         git_repository_initialize(git_repository)
    #     else:
    #         raise ValueError(
    #             f"Repository to be auto-provisioned is not the full URL of a GitHub repo: {repository}"
    #         )

    return schema.QHubConfig(**qhub_config)


def github_auto_provision(config, owner, repo):
    check_cloud_credentials(
        config
    )  # We may need env vars such as AWS_ACCESS_KEY_ID depending on provider

    already_exists = True
    try:
        github.get_repository(owner, repo)
    except requests.exceptions.HTTPError:
        # repo not found
        already_exists = False

    if not already_exists:
        try:
            github.create_repository(
                owner,
                repo,
                description=f'QHub {config["project_name"]}-{config["provider"]}',
                homepage=f'https://{config["domain"]}',
            )
        except requests.exceptions.HTTPError as he:
            raise ValueError(
                f"Unable to create GitHub repo https://github.com/{owner}/{repo} - error message from GitHub is: {he}"
            )
    else:
        logger.warn(f"GitHub repo https://github.com/{owner}/{repo} already exists")

    try:
        # Secrets
        if config["provider"] == "do":
            for name in {
                "AWS_ACCESS_KEY_ID",
                "AWS_SECRET_ACCESS_KEY",
                "SPACES_ACCESS_KEY_ID",
                "SPACES_SECRET_ACCESS_KEY",
                "DIGITALOCEAN_TOKEN",
            }:
                github.update_secret(owner, repo, name, os.environ[name])
        elif config["provider"] == "aws":
            for name in {
                "AWS_ACCESS_KEY_ID",
                "AWS_SECRET_ACCESS_KEY",
            }:
                github.update_secret(owner, repo, name, os.environ[name])
        elif config["provider"] == "gcp":
            github.update_secret(owner, repo, "PROJECT_ID", os.environ["PROJECT_ID"])
            with open(os.environ["GOOGLE_CREDENTIALS"]) as f:
                github.update_secret(owner, repo, "GOOGLE_CREDENTIALS", f.read())
        elif config["provider"] == "azure":
            for name in {
                "ARM_CLIENT_ID",
                "ARM_CLIENT_SECRET",
                "ARM_SUBSCRIPTION_ID",
                "ARM_TENANT_ID",
            }:
                github.update_secret(owner, repo, name, os.environ[name])
        github.update_secret(
            owner, repo, "REPOSITORY_ACCESS_TOKEN", os.environ["GITHUB_TOKEN"]
        )
    except requests.exceptions.HTTPError as he:
        raise ValueError(
            f"Unable to set Secrets on GitHub repo https://github.com/{owner}/{repo} - error message from GitHub is: {he}"
        )

    return f"git@github.com:{owner}/{repo}.git"


def git_repository_initialize(git_repository):
    if not git.is_git_repo("./"):
        git.initialize_git("./")
    git.add_git_remote(git_repository, path="./", remote_name="origin")


def auth0_auto_provision(config):
    auth0_config = create_client(config["domain"], config["project_name"])
    config["security"]["authentication"]["config"]["client_id"] = auth0_config[
        "client_id"
    ]
    config["security"]["authentication"]["config"]["client_secret"] = auth0_config[
        "client_secret"
    ]
    config["security"]["authentication"]["config"]["auth0_subdomain"] = auth0_config[
        "auth0_subdomain"
    ]
