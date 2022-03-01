import os
import enum
import typing
import random
from abc import ABC
import pathlib
import string
import secrets

from ruamel.yaml import YAML
import pydantic
from pydantic import validator, root_validator, Field

from qhub.utils import namestr_regex, qhub_image_tag
from qhub.provider.cloud import digital_ocean, amazon_web_services, google_cloud, azure_cloud
from qhub.provider.oauth.auth0 import create_client
from .version import rounded_ver_parse, __version__


class CertificateEnum(str, enum.Enum):
    letsencrypt = "lets-encrypt"
    selfsigned = "self-signed"
    existing = "existing"


class TerraformStateEnum(str, enum.Enum):
    remote = "remote"
    local = "local"
    existing = "existing"


class ProviderEnum(str, enum.Enum):
    local = "local"
    do = "do"
    aws = "aws"
    gcp = "gcp"
    azure = "azure"


class CiEnum(str, enum.Enum):
    github_actions = "github-actions"
    gitlab_ci = "gitlab-ci"
    none = "none"


class AuthenticationEnum(str, enum.Enum):
    password = "password"
    github = "GitHub"
    auth0 = "Auth0"


class Base(pydantic.BaseModel):
    ...

    class Config:
        extra = "forbid"


# ============== CI/CD =============


class CICD(Base):
    type: CiEnum = CiEnum.none
    branch: str = "main"
    before_script: typing.Optional[typing.List[str]]
    after_script: typing.Optional[typing.List[str]]

    @classmethod
    def qhub_initialize(cls, ci_provider : CiEnum):
        return cls(type=ci_provider)


# ======== Generic Helm Extensions ========
class HelmExtension(Base):
    name: str
    repository: str
    chart: str
    version: str
    overrides: typing.Dict = {}


# ============== Monitoring =============


class Monitoring(Base):
    enabled: bool = True


# ============== ClearML =============


class ClearML(Base):
    enabled: bool = False
    enable_forward_auth: bool = True
    overrides: typing.Dict = {}


# ============== Prefect =============


class Prefect(Base):
    enabled: bool = False
    image: typing.Optional[str]
    overrides: typing.Dict = {}


# ============= Terraform ===============


class TerraformState(Base):
    type: TerraformStateEnum = TerraformStateEnum.local
    backend: typing.Optional[str]
    config: typing.Optional[typing.Dict[str, str]]


# ============ Certificate =============


class Certificate(Base):
    type: CertificateEnum = CertificateEnum.selfsigned
    # existing
    secret_name: typing.Optional[str]
    # lets-encrypt
    acme_email: typing.Optional[str] = Field(
        None,
        regex="^[^ @]+@[^ @]+\\.[^ @]+$",
        title="ACME email to use for registration",
        description="the provided email will recieve notifications when certificate is close to expiration",
    )
    acme_server: typing.Optional[str] = Field(
        "https://acme-staging-v02.api.letsencrypt.org/directory",
        title="ACME server to use for certificate generation",
        description="The ACME server to use for certificate generation. If you are using letsencrypt there are two major servers (production) `https://acme-v02.api.letsencrypt.org/directory` and (staging) `https://acme-staging-v02.api.letsencrypt.org/directory`"
    )


# ========== Default Images ==============


class DefaultImages(Base):
    jupyterhub: str = Field(
        f"quansight/qhub-jupyterhub:{qhub_image_tag}",
        title="JupyterHub docker image")
    jupyterlab: str = Field(
        f"quansight/qhub-jupyterlab:{qhub_image_tag}",
        title="JupyterLab default docker image")
    dask_worker: str = Field(
        f"quansight/qhub-dask-worker:{qhub_image_tag}",
        title="Dask Worker default docker image")
    dask_gateway: str = Field(
        f"quansight/qhub-dask-gateway:{qhub_image_tag}",
        title="Dask Gateway default docker image")


# =========== Authentication ==============


class GitHubConfig(Base):
    client_id: str = 'PLACEHOLDER'
    client_secret: str = 'PLACEHOLDER'


class Auth0Config(Base):
    client_id: str = 'PLACEHOLDER'
    client_secret: str = 'PLACEHOLDER'
    auth0_subdomain: str = 'PLACEHOLDER.auth0.io'


class Authentication(Base, ABC):
    _types: typing.Dict[str, type] = {}

    type: AuthenticationEnum = AuthenticationEnum.password

    # Based on https://github.com/samuelcolvin/pydantic/issues/2177#issuecomment-739578307

    # This allows type field to determine which subclass of Authentication should be used for validation.

    # Used to register automatically all the submodels in `_types`.
    def __init_subclass__(cls):
        cls._types[cls._typ.value] = cls

    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, value: typing.Union[typing.Dict[str, typing.Any], "Authentication"]) -> "Authentication":
        if isinstance(value, Authentication):
            return value

        if "type" not in value:
            raise ValueError("type field is missing from security.authentication")

        specified_type = value.get("type")
        sub_class = cls._types.get(specified_type, None)

        if not sub_class:
            raise ValueError(
                f"No registered Authentication type called {specified_type}"
            )

        # init with right submodel
        return sub_class(**value)


class PasswordAuthentication(Authentication):
    _typ = AuthenticationEnum.password

    @classmethod
    def qhub_initialize(cls):
        return Authentication(type=AuthenticationEnum.password.value)


class Auth0Authentication(Authentication):
    _typ = AuthenticationEnum.auth0
    config: Auth0Config

    @classmethod
    def qhub_initialize(cls, qhub_domain: str, project_name : str, auto_provision: bool = False, disable_prompt: bool = True):
        if not disable_prompt:
            print(
                "Visit https://auth0.com/docs/get-started/applications and create oauth application\n"
                f"  set the homepage to: https://{qhub_domain}/\n"
                f"  set the callback_url to: https://{qhub_domain}/auth/realms/qhub/broker/github/endpoint"
            )
            client_id = input("Auth0 client_id: ")
            client_secret = input("Auth0 client_secret: ")
            auth0_subdomain = input("Auth0 subdomain: ")
            return cls(
                type=AuthenticationEnum.auth0.value,
                config=Auth0Config(
                    client_id=client_id,
                    client_secret=client_secret,
                    auth0_subdomain=auth0_subdomain))
        elif auto_provision:
            auth0_config = create_client(qhub_domain, project_name)
            return cls(
                type=AuthenticationEnum.auth0.value,
                config=Auth0Config(
                    client_id=auth0_config['client_id'],
                    client_secret=auth0_config['client_secret'],
                    auth0_subdomain=auth0_config['auth0_subdomain']))

        return cls(
            type=AuthenticationEnum.auth0.value,
            config=Auth0Config())


class GitHubAuthentication(Authentication):
    _typ = AuthenticationEnum.github
    config: GitHubConfig

    @classmethod
    def qhub_initialize(cls, qhub_domain : str, auto_provision: bool = False, disable_prompt: bool = True):
        if not disable_prompt:
            print(
                "Visit https://github.com/settings/developers and create oauth application\n"
                f"  set the homepage to: https://{qhub_domain}/\n"
                f"  set the callback_url to: https://{qhub_domain}/auth/realms/qhub/broker/github/endpoint"
            )
            client_id = input("GitHub client_id: ")
            client_secret = input("GitHub client_secret: ")
            return cls(
                type=AuthenticationEnum.github.value,
                config=GitHubConfig(
                    client_id=client_id,
                    client_secret=client_secret))
        elif auto_provision:
            raise NotImplementedError('QHub auth auto provisioning for GitHub')

        return cls(
            type=AuthenticationEnum.github.value,
            config=GitHubConfig())



# ================= Keycloak ==================


class Keycloak(Base):
    initial_root_password: str = Field(
        default_factory=lambda: "".join(
            secrets.choice(string.ascii_letters + string.digits) for i in range(16)
        ),
        title="Keycloak root user password",
    )
    overrides: typing.Dict = {}
    realm_display_name: str = "QHub"


# ============== Security ================


class Security(Base):
    authentication: Authentication = Authentication()
    shared_users_group: bool = True
    keycloak: Keycloak = Keycloak()


# ================ Providers ===============


class KeyValueDict(Base):
    key: str
    value: str


class NodeSelectors(Base):
    general: KeyValueDict
    user: KeyValueDict
    worker: KeyValueDict


class NodeGroup(Base):
    instance: str
    min_nodes: int
    max_nodes: int
    gpu: typing.Optional[bool] = False

    class Config:
        extra = "allow"


class DigitalOceanProvider(Base):
    region: str = Field(
        "nyc3",
        title="Region to deploy Digital Ocean QHub cluster",
        description="Detailed list of [regions](https://docs.digitalocean.com/products/platform/availability-matrix/) for Digital Ocean",
    )
    kubernetes_version: str = Field(
        default_factory=digital_ocean.kubernetes_versions,
        title="Kubernetes version to QHub Deployment",
        description="The Digital Ocean kubernetes version changes frequently see [docs](https://docs.digitalocean.com/products/kubernetes/changelog/) for latest versions additionally you may use the command line tool `doctl kubernetes options versions`",
    )
    node_groups: typing.Dict[str, NodeGroup] = {
        "general": NodeGroup(
            instance="g-4vcpu-16gb",
            min_nodes=1,
            max_nodes=1,
        ),
        "user": NodeGroup(
            instance="g-2vcpu-8gb",
            min_nodes=1,
            max_nodes=5,
        ),
        "worker": NodeGroup(
            instance="g-2vcpu-8gb",
            min_nodes=1,
            max_nodes=5,
        )
    }

    @validator("kubernetes_version")
    def validate_kubernetes_version(cls, field_value, values):
        kubernetes_versions = digital_ocean.kubernetes_versions(values["region"])
        if field_value not in kubernetes_versions:
            raise ValueError(f'kubernetes version "{field_value}" not in Digital Ocean allowed kubernetes versions')


class GoogleCloudPlatformProvider(Base):
    project: str = os.environ.get('PROJECT_ID')
    region: str = Field(
        "us-central1",
        title="Region to deploy Google Cloud Platform QHub cluster",
        description="Available google cloud platform regions can be found [here](https://cloud.google.com/about/locations)",
    )
    availability_zones: typing.Optional[typing.List[str]]  # Genuinely optional
    kubernetes_version: str = Field(
        default_factory=lambda: google_cloud.kubernetes_versions()[-1],
        title="Kubernetes version to use for Google Cloud Platform QHub deployment",
        description="Detailed information on the release and deprication schedule of Kubernetes version can be found [here](https://cloud.google.com/kubernetes-engine/docs/release-schedule)"
    )
    node_groups: typing.Dict[str, NodeGroup] = {
        "general": NodeGroup(
            instance="n1-standard-4",
            min_nodes=1,
            max_nodes=1
        ),
        "user": NodeGroup(
            instance="n1-standard-2",
            min_nodes=0,
            max_nodes=5
        ),
        "worker": NodeGroup(
            instance="n1-standard-2",
            min_nodes=0,
            max_nodes=5
        ),
    }

    @validator("kubernetes_version")
    def validate_kubernetes_version(cls, field_value, values):
        kubernetes_versions = google_cloud.kubernetes_versions(values["region"])
        if field_value not in kubernetes_versions:
            raise ValueError(f'kubernetes version "{field_value}" not in Google Cloud Platform allowed kubernetes versions')


class AzureProvider(Base):
    region: str = Field(
        "Central US",
        title="Region to deploy Azure resources",
        description="Detailed list of Azure regions can be found [here](https://docs.microsoft.com/en-us/azure/availability-zones/az-overview)",
    )
    kubernetes_version: str = Field(
        default_factory=lambda: azure_cloud.kubernetes_versions()[-1],
        title="Kubernetes version to use for Azure QHub deployment",
        description="Detailed information on the release and deprication schedule of Kubernetes version can be found [here](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli)"
    )
    node_groups: typing.Dict[str, NodeGroup] = {
        "general": NodeGroup(
            instance="Standard_D4_v3",
            min_nodes=1,
            max_nodes=1
        ),
        "user": NodeGroup(
            instance="Standard_D2_v2",
            min_nodes=0,
            max_nodes=5
        ),
        "worker": NodeGroup(
            instance="Standard_D2_v2",
            min_nodes=0,
            max_nodes=5
        ),
    }
    storage_account_postfix: str = Field(
        default_factory=lambda: "".join(
            random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=8)
        ),
        title="Random postfix to append to storage account",
        description="Hopefully a depricated option in the future but a postfix that must be added to the Azure storage account"
    )

    @validator("kubernetes_version")
    def validate_kubernetes_version(cls, field_value, values):
        kubernetes_versions = azure_cloud.kubernetes_versions(values["region"])
        if field_value not in kubernetes_versions:
            raise ValueError(f'kubernetes version "{field_value}" not in Azure allowed kubernetes versions')


class AmazonWebServicesProvider(Base):
    region: str = Field(
        os.environ.get("AWS_DEFAULT_REGION", "us-west-2"),
        title="Region to deploy AWS resources",
        description="Available AWS regions can be found [here](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)",
    )
    availability_zones: typing.Optional[typing.List[str]] = Field(
        None,
        title="Availability zones in AWS to deploy QHub",
        description="field is optional and will be autopopulated if left empty at least two zones must be supplied if used"
    )
    kubernetes_version: str = Field(
        default_factory=lambda: amazon_web_services.kubernetes_versions()[-1],
        title="Kubernetes version to use for Azure QHub deployment",
        description="Detailed information on the release and deprication schedule of Kubernetes version can be found [here](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)",
    )
    node_groups: typing.Dict[str, NodeGroup] = {
        "general": NodeGroup(
            instance="m5.xlarge",
            min_nodes=1,
            max_nodes=1
        ),
        "user": NodeGroup(
            instance="m5.large",
            min_nodes=1,
            max_nodes=5
        ),
        "worker": NodeGroup(
            instance="m5.large",
            min_nodes=1,
            max_nodes=5
        ),
    }

    @validator("kubernetes_version")
    def validate_kubernetes_version(cls, field_value, values):
        kubernetes_versions = amazon_web_services.kubernetes_versions(values["region"])
        if field_value not in kubernetes_versions:
            raise ValueError(f'kubernetes version "{field_value}" not in Amazon Web Services allowed kubernetes versions')


class LocalProvider(Base):
    kube_context: typing.Optional[str]
    node_selectors: NodeSelectors = NodeSelectors(
        general=KeyValueDict(key="kubernetes.io/os", value="linux"),
        user=KeyValueDict(key="kubernetes.io/os", value="linux"),
        worker=KeyValueDict(key="kubernetes.io/os", value="linux"),
    )


# ================= Theme ==================

class JupyterHubTheme(Base):
    hub_title: str = "QHub"
    hub_subtitle: str = "Autoscaling Compute Environment"
    welcome: str = """Welcome to QHub. It is maintained by <a href="http://quansight.com">Quansight staff</a>. The hub's configuration is stored in a github repository based on <a href="https://github.com/Quansight/qhub/">https://github.com/Quansight/qhub/</a>. To provide feedback and report any technical problems, please use the <a href="https://github.com/Quansight/qhub/issues">github issue tracker</a>."""
    logo: str = "/hub/custom/images/jupyter_qhub_logo.svg"
    primary_color: str = "#4f4173"
    secondary_color: str = "#957da6"
    accent_color: str = "#32C574"
    text_color: str = "#111111"
    h1_color: str = "#652e8e"
    h2_color: str = "#652e8e"

    class Config:
        extra = "allow"


class Theme(Base):
    jupyterhub: JupyterHubTheme = JupyterHubTheme()

    @classmethod
    def qhub_initialize(cls, qhub_domain : str, cloud_provider : ProviderEnum, project_name : str):
        hub_subtitle = "Autoscaling Compute Environment"
        if cloud_provider == ProviderEnum.gcp:
            hub_subtitle = "Autoscaling Compute Environment on Google Cloud Platform"
        elif cloud_provider == ProviderEnum.azure:
            hub_subtitle = "Autoscaling Compute Environment on Azure"
        elif cloud_provider == ProviderEnum.aws:
            hub_subtitle = "Autoscaling Compute Environment on Amazon Web Services"
        elif cloud_provider == ProviderEnum.do:
            hub_subtitle = "Autoscaling Compute Environment on Digital Ocean"

        return cls(
            jupyterhub=JupyterHubTheme(
                hub_title = f"QHub - { project_name }",
                hub_subtitle = hub_subtitle,
                welcome = f"""Welcome to { qhub_domain }. It is maintained by <a href="http://quansight.com">Quansight staff</a>. The hub's configuration is stored in a github repository based on <a href="https://github.com/Quansight/qhub/">https://github.com/Quansight/qhub/</a>. To provide feedback and report any technical problems, please use the <a href="https://github.com/Quansight/qhub/issues">github issue tracker</a>.""",
            )
        )


# ================= JupyterHub ==================


class JupyterHub(Base):
    overrides: typing.Dict = {}


# ================== Profiles ==================


class KubeSpawner(Base):
    cpu_limit: int
    cpu_guarantee: int
    mem_limit: str
    mem_guarantee: str
    image: typing.Optional[str]

    class Config:
        extra = "allow"


class JupyterLabProfile(Base):
    display_name: str
    description: str
    default: bool = False
    users: typing.Optional[typing.List[str]]
    groups: typing.Optional[typing.List[str]]
    kubespawner_override: typing.Optional[KubeSpawner]


class DaskWorkerProfile(Base):
    worker_cores_limit: int
    worker_cores: int
    worker_memory_limit: str
    worker_memory: str
    image: typing.Optional[str]

    class Config:
        extra = "allow"


class Profiles(Base):
    jupyterlab: typing.List[JupyterLabProfile] = [
        JupyterLabProfile(
            display_name="Small Instance",
            description="Stable environment with 1 cpu / 4 GB ram",
            default=True,
            kubespawner_override=KubeSpawner(
                cpu_limit=1,
                cpu_guarantee=0.75,
                mem_limit="4G",
                mem_guarantee="2.5G",
            )
        ),
        JupyterLabProfile(
            display_name="Medium Instance",
            description="Stable environment with 2 cpu / 8 GB ram",
            kubespawner_override=KubeSpawner(
                cpu_limit=2,
                cpu_guarantee=1.5,
                mem_limit="8G",
                mem_guarantee="5G",
            )
        )

    ]
    dask_worker: typing.Dict[str, DaskWorkerProfile] = {
        "Small Worker": DaskWorkerProfile(
            worker_cores_limit=1,
            worker_cores=0.75,
            worker_memory_limit="4G",
            worker_memory="2.5G",
            worker_threads=1,
        ),
        "Medium Worker": DaskWorkerProfile(
            worker_cores_limit=2,
            worker_cores=1.5,
            worker_memory_limit="8G",
            worker_memory="5G",
            worker_threads=1,
        )
    }

    @validator("jupyterlab", pre=True)
    def check_default(cls, v, values):
        """Check if only one default value is present"""
        default = [attrs["default"] for attrs in v if "default" in attrs]
        if default.count(True) > 1:
            raise TypeError(
                "Multiple default Jupyterlab profiles may cause unexpected problems."
            )
        return v


# ================ Environment ================


class CondaEnvironment(Base):
    name: str
    channels: typing.Optional[typing.List[str]]
    dependencies: typing.List[typing.Union[str, typing.Dict[str, typing.List[str]]]]


# =============== CDSDashboards ==============


class CDSDashboards(Base):
    enabled: bool = True
    cds_hide_user_named_servers: bool = True
    cds_hide_user_dashboard_servers: bool = False


# =============== Extensions = = ==============


class QHubExtensionEnv(Base):
    name: str
    value: str


class QHubExtension(Base):
    name: str
    image: str
    urlslug: str
    private: bool = False
    oauth2client: bool = False
    keycloakadmin: bool = False
    jwt: bool = False
    qhubconfigyaml: bool = False
    logout: typing.Optional[str]
    envs: typing.Optional[typing.List[QHubExtensionEnv]]


# ======== External Container Registry ========

# This allows the user to set a private AWS ECR as a replacement for
# Docker Hub for some images - those where you provide the full path
# to the image on the ECR.
# extcr_account and extcr_region are the AWS account number and region
# of the ECR respectively. access_key_id and secret_access_key are
# AWS access keys that should have read access to the ECR.


class ExtContainerReg(Base):
    enabled: bool
    access_key_id: typing.Optional[str]
    secret_access_key: typing.Optional[str]
    extcr_account: typing.Optional[str]
    extcr_region: typing.Optional[str]

    @root_validator
    def enabled_must_have_fields(cls, values):
        if values["enabled"]:
            for fldname in (
                "access_key_id",
                "secret_access_key",
                "extcr_account",
                "extcr_region",
            ):
                if (
                    fldname not in values
                    or values[fldname] is None
                    or values[fldname].strip() == ""
                ):
                    raise ValueError(
                        f"external_container_reg must contain a non-blank {fldname} when enabled is true"
                    )
        return values


# =============== Storage =================

class Storage(Base):
    conda_store: str = Field(
        "60Gi",
        title="Conda-Store storage",
        description="storage to allocate for storing conda environments"
    )
    shared_filesystem: str = Field(
        "100Gi",
        title="JupyterLab shared storage",
        description="storage to allocate for all users of JupyterLab"
    )


# ==================== Main ===================

letter_dash_underscore_pydantic = pydantic.constr(regex=namestr_regex)


class QHubConfig(Base):
    project_name: letter_dash_underscore_pydantic
    domain: str
    provider: ProviderEnum
    namespace: letter_dash_underscore_pydantic = "dev"
    qhub_version: str = __version__
    ci_cd: CICD = CICD()
    terraform_state: TerraformState = TerraformState()
    certificate: Certificate = Certificate()
    helm_extensions: typing.List[HelmExtension] = []
    prefect: Prefect = Prefect()
    cdsdashboards: CDSDashboards = CDSDashboards()
    security: Security = Security()
    external_container_reg: typing.Optional[ExtContainerReg]
    default_images: DefaultImages = DefaultImages()
    storage: Storage = Storage()
    local: typing.Optional[LocalProvider]
    google_cloud_platform: typing.Optional[GoogleCloudPlatformProvider]
    amazon_web_services: typing.Optional[AmazonWebServicesProvider]
    azure: typing.Optional[AzureProvider]
    digital_ocean: typing.Optional[DigitalOceanProvider]
    theme: Theme = Theme()
    profiles: Profiles = Profiles()
    environments: typing.Dict[str, CondaEnvironment] = {
        "environment-dask.yaml": CondaEnvironment(
            name="dask",
            channels=["conda-forge"],
            dependencies=[
                "python",
                "ipykernel",
                "ipywidgets",
                "qhub-dask ==0.3.13",
                "python-graphviz",
                "numpy",
                "numba",
                "pandas",
            ]
        ),
        "environment-dashboard.yaml": CondaEnvironment(
            name="dashboard",
            channels=["conda-forge"],
            dependencies=[
                "python==3.9.7",
                "ipykernel==6.4.1",
                "ipywidgets==7.6.5",
                "qhub-dask==0.3.13",
                "param==1.11.1",
                "python-graphviz==0.17",
                "matplotlib==3.4.3",
                "panel==0.12.4",
                "voila==0.2.16",
                "streamlit==1.0.0",
                "dash==2.0.0",
                "cdsdashboards-singleuser==0.6.0",
            ]
        ),
    }
    monitoring: Monitoring = Monitoring()
    clearml: ClearML = ClearML()
    tf_extensions: typing.List[QHubExtension] = []
    jupyterhub: JupyterHub = JupyterHub()
    prevent_deploy: bool = (
        False  # Optional, but will be given default value if not present
    )

    # If the qhub_version in the schema is old
    # we must tell the user to first run qhub upgrade
    @validator("qhub_version", pre=True, always=True)
    def check_default(cls, v):
        """
        Always called even if qhub_version is not supplied at all (so defaults to ''). That way we can give a more helpful error message.
        """
        if not cls.is_version_accepted(v):
            if v == "":
                v = "not supplied"
            raise ValueError(
                f"qhub_version in the config file must be equivalent to {__version__} to be processed by this version of qhub (your config file version is {v})."
                " Install a different version of qhub or run qhub upgrade to ensure your config file is compatible."
            )
        return v

    @classmethod
    def is_version_accepted(cls, v):
        return v != "" and rounded_ver_parse(v) == rounded_ver_parse(__version__)

    @classmethod
    def from_file(cls, filename : typing.Union[str, pathlib.Path]):
        yaml = YAML()
        yaml.preserve_quotes = True
        yaml.default_flow_style = False

        with pathlib.Path(filename).open() as f:
            config = yaml.load(f.read())

        return cls(**config)

    def to_file(self, filename : str, overwrite : bool = False):
        yaml = YAML()
        yaml.preserve_quotes = True
        yaml.default_flow_style = False

        mode = 'w' if overwrite else 'x'
        with open(filename, mode) as f:
            import json
            yaml.dump(json.loads(self.json()), f)


def verify(config):
    return QHubConfig(**config)


def is_version_accepted(v):
    """
    Given a version string, return boolean indicating whether
    qhub_version in the qhub-config.yaml would be acceptable
    for deployment with the current QHub package.
    """
    return QHubConfig.is_version_accepted(v)
