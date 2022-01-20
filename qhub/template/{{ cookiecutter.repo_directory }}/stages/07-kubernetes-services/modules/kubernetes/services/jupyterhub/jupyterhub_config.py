import os

{% if cookiecutter.cdsdashboards.enabled %}

# ================ CDSDASHBOARDS =====================
c.JupyterHub.allow_named_servers = True
from cdsdashboards.hubextension import cds_extra_handlers
c.JupyterHub.extra_handlers = cds_extra_handlers
from cdsdashboards.app import CDS_TEMPLATE_PATHS
c.JupyterHub.template_paths = CDS_TEMPLATE_PATHS
c.JupyterHub.spawner_class = 'cdsdashboards.hubextension.spawners.variablekube.VariableKubeSpawner'
c.CDSDashboardsConfig.builder_class = 'cdsdashboards.builder.kubebuilder.KubeBuilder'
c.VariableMixin.default_presentation_cmd = ['python3', '-m', 'jhsingle_native_proxy.main']

c.JupyterHub.default_url = '/hub/home'

# Force dashboard creator to select an instance size
c.CDSDashboardsConfig.spawn_default_options = False

c.CDSDashboardsConfig.conda_envs = [
{%- for key in cookiecutter.environments %}
    "{{ cookiecutter.environments[key].name }}",
{%- endfor %}
]

{% else %}

c.JupyterHub.allow_named_servers = False
c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'
c.JupyterHub.template_paths = []
c.JupyterHub.extra_handlers = []

{% endif %}

# ==================== THEME =========================
import tornado.web
from qhub_jupyterhub_theme import theme_extra_handlers, theme_template_paths

c.JupyterHub.extra_handlers += theme_extra_handlers

c.JupyterHub.template_paths = theme_template_paths + c.JupyterHub.template_paths

c.JupyterHub.template_vars = {
{%- for key, value in cookiecutter.theme.jupyterhub.items() %}
    "{{ key }}": {{ value | jsonify }},
{%- endfor %}
{% if cookiecutter.cdsdashboards.enabled %}
    "cdsdashboards_enabled": True,
    {% if cookiecutter.cdsdashboards.cds_hide_user_named_servers is defined %}
    "cds_hide_user_named_servers": {{ cookiecutter.cdsdashboards.cds_hide_user_named_servers }},
    {% endif %}
    {% if cookiecutter.cdsdashboards.cds_hide_user_dashboard_servers is defined %}
    "cds_hide_user_dashboard_servers": {{ cookiecutter.cdsdashboards.cds_hide_user_dashboard_servers }},
    {% endif %}
{% endif %}
}

# ================= Keycloak =====================

from keycloak import KeycloakAdmin

keycloak_admin = KeycloakAdmin(
    server_url=os.environ.get(
        "KEYCLOAK_SERVER_URL", "http://localhost:8080/auth/"
    ),
    username=os.environ.get("KEYCLOAK_USERNAME", "admin"),
    password=os.environ.get("KEYCLOAK_PASSWORD", "admin"),
    realm_name=os.environ.get("KEYCLOAK_REALM_NAME", "qhub"),
    user_realm_name="master",
    auto_refresh_token=("get", "put", "post", "delete"),
)

# ================= Profiles =====================
from urllib.request import urlopen, Request
import json

QHUB_PROFILES = json.loads("{{ cookiecutter.profiles.jupyterlab | jsonify | replace('"', '\\"') }}")

import escapism
import string

def qhub_get_nss_user(username):
    kid = keycloak_admin.get_user_id(username)

    usergroups = keycloak_admin.get_user_groups(kid)

    groups = [keycloak_admin.get_group(group_id=g["id"]) for g in usergroups]

    return {
        "username": username,
        "groups": groups
    }

    # Example:
    # { "username": "dan",
    # "groups": [ { "name": "admin", "attributes": {"profiles": ["small"]} },
    #    { "name": "users", "attributes": {"profiles": ["small"]}, }
    #  ] }

def qhub_configure_profile(user_nss_json, safe_username, profile):
    username = user_nss_json['username']
    groups = user_nss_json['groups']

    envvars_fixed = {
       'NB_UMASK': '0002',
       'SHELL': '/bin/bash',
       'HOME': '/home/jovyan',
       **(profile.get('kubespawner_override', {}).get('environment', {}))
    }

    def preserve_envvars(spawner):
        # This adds in JUPYTERHUB_ANYONE/GROUP rather than overwrite all env vars,
        # if set for a dashboard to control access.
        return {**envvars_fixed, **spawner.environment}

    profile.setdefault('kubespawner_override', {})['environment'] = preserve_envvars

    profile['kubespawner_override']['lifecycle_hooks'] = {
        "postStart": {
            "exec": {
                "command": ["/bin/sh", "-c", (
                     "ln -sfn /home/shared /home/jovyan/shared"
                )]
            }
        }
    }

    # The recursive chown is important when migrating from an
    # older uid/gid-based NFS, but may be slow for a lot of files.
    # The .migrateuser-{username}.txt etc files below are checks so this only
    # needs to happen the first time a user/group is encountered post-upgrade.
    # Those checks can probably be removed in a future release.

    profile['kubespawner_override']['init_containers'] = [
        {
             "name": "init-nfs",
             "image": "busybox:1.31",
             "command": ["sh", "-c", ' && '.join([
                  "mkdir -p /mnt/home/{username}",
                  "chmod 700 /mnt/home/{username}",
                  #"chown 1000:100 /mnt/home/{username}",
                  "if [ ! -f /mnt/home/.migrateuser-{username}.txt ] ; then chown -R 1000:100 /mnt/home/{username} ; touch /mnt/home/.migrateuser-{username}.txt ; fi",
                  "mkdir -p /mnt/home/shared",
                  "chmod 777 /mnt/home/shared",
                  ] + [
                    (' && '.join([
                        "mkdir -p /mnt/home/shared/{groupname}",
                        "chmod 2770 /mnt/home/shared/{groupname}",
                        #"chown 1000:100 /mnt/home/shared/{groupname}",
                        "if [ ! -f /mnt/home/.migrategroup-{groupname}.txt ] ; then chown -R 1000:100 /mnt/home/shared/{groupname} ; touch /mnt/home/.migrategroup-{groupname}.txt ; fi",
                    ])
                    ).format(groupname=g['name'])
                     for g in groups
                  ]
                ).format(username=safe_username)],
             "securityContext": {"runAsUser": 0},
             "volumeMounts": [{"mountPath": "/mnt", "name": "home"}]
        }
    ]

    profile['kubespawner_override']['uid'] = 1000
    profile['kubespawner_override']['gid'] = 100
    profile['kubespawner_override']['fs_gid'] = 100
    profile['kubespawner_override']['volume_mounts'] = c.KubeSpawner.volume_mounts + [
        {
            "name"      : "home",
            "mountPath" : f"/home/shared/{g['name']}",
            "subPath"   : f"home/shared/{g['name']}",
        }
        for g in groups
    ]

    # Cost monitoring labels
    k8s_safe_chars = set(string.ascii_lowercase + string.digits + '.-_')
    k8s_safe_username = escapism.escape(username.lower().replace('@', '_'), safe=k8s_safe_chars, escape_char='-', allow_collisions=True)

    primary_group_name = "users"
    groupnames_not_users = set([g['name'] for g in groups]) - {"users"}
    if len(groupnames_not_users) > 0:
        primary_group_name = sorted(groupnames_not_users)[0]

    profile['kubespawner_override']['extra_labels'] = {
        'owner': k8s_safe_username,
        'team': primary_group_name
    }
    return profile

def qhub_list_available_profiles(user_nss_json):
    username = user_nss_json['username']

    safe_chars = set(string.ascii_lowercase + string.digits)
    safe_username = escapism.escape(username, safe=safe_chars, escape_char='-', allow_collisions=False).lower()

    exclude_keys = {'users', 'groups', 'kubespawner_override'}

    groups = set([g['name'] for g in user_nss_json['groups']])

    group_profiles_nested_list = [g["attributes"].get("profiles", []) for g in user_nss_json['groups'] if type(g.get("attributes", None)) == dict]
    # for example [['small'], ['small', 'medium']]

    group_profile_names = set([p for sublist in group_profiles_nested_list for p in sublist])
    # for example {"small", "medium"}

    available_profiles = []
    for profile in QHUB_PROFILES:
        restricted_profile = {k: v for k,v in profile.items() if k not in exclude_keys}
        if 'kubespawner_override' in profile:
            # This is to remove typing from kubespawner_override so that we can set
            # kubespawner_override['environment'] as a function instead of a mapping
            restricted_profile['kubespawner_override'] = {**profile['kubespawner_override']}

        include_profile = True

        if 'users' in profile:
            if username not in profile['users']:
                include_profile = False
        elif 'groups' in profile:
            if profile['groups'] is None or len(groups & set(profile['groups'])) == 0:
            # None of the YAML groups match
                # How about Keycloak-attributes?
                # Note use "##" as a delimiter if setting multiple 'profiles' attributes (i.e. a list)
                if profile["display_name"] not in group_profile_names:
                    include_profile = False

        if include_profile:
            filtered_profile = qhub_configure_profile(user_nss_json, safe_username, {k: v for k,v in profile.items() if k not in exclude_keys})
            available_profiles.append(filtered_profile)

    return available_profiles


c.JupyterHub.admin_access = True

async def custom_options_form(spawner):
    # Let KubeSpawner inspect profile_list and decide what to return
    user_nss_json = qhub_get_nss_user(spawner.user.name)
    spawner.profile_list = qhub_list_available_profiles(user_nss_json)

    return spawner._options_form_default()

c.KubeSpawner.options_form = custom_options_form
