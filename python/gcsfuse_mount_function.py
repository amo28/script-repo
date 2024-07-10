#!/usr/bin/env python3
import os
import logging
import pprint
import shlex
import subprocess
import sys
import json

# Global constants
PP = pprint.PrettyPrinter(indent=4)

FORMAT = "PID:%(process)d\t[%(asctime)s]\t%(levelname)s\t[%(name)s.%(funcName)s:%(lineno)d]\t%(" \
        "message)s"
LOG = logging.getLogger(__name__)
LOG.setLevel(logging.DEBUG)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(
    fmt=logging.Formatter(FORMAT)
)
LOG.addHandler(handler)
fh = logging.FileHandler('log.log')
fh.setLevel(logging.DEBUG)
fh.setFormatter(
    fmt=logging.Formatter(FORMAT)
)
LOG.addHandler(fh)
LOG.info("Logger configured")

def run_command(command, noop=False, fail_on_errors=True, shell=False):
    if noop:
        LOG.info("NOOP: Running '{}'".format(command))
        return []
    else:
        LOG.info("Running '{}'".format(command))
    if shell:
        args = command
    else:
        args = shlex.split(command)
    try:
        p = subprocess.check_output(args,
                                    stderr=subprocess.STDOUT,
                                    shell=shell)
        return list(map(lambda x: x.decode("utf-8"),  p.splitlines()))
    except subprocess.CalledProcessError as e:
        LOG.error("Command '{}' returned exit code {}".format(command, e.returncode))
        for line in e.output.splitlines():
            LOG.error("Error output: {}".format(line))
        if fail_on_errors:
            raise

def gcsfuse_mount():
    # GCS bucket specific files
    # service account JSON key
    gcs_json_key = {
        "type": "service_account",
        "project_id": "{{ project_id }}",
        "private_key_id": "{{ project_key_id }}",
        "private_key": "{{ private key }}",
        "client_email": "{{ client_email }}",
        "client_id": "{{ client_id }}",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "{{ client_x509_cert_url }}",
        "universe_domain": "googleapis.com"
    }

    with open('.gcs.json', 'w') as f:
        json.dump(gcs_json_key, f)

    # gcsfuse yumrepo
    with open('/etc/yum.repos.d/gcsfuse.repo', 'w') as f:
        _ = f"""[gcsfuse]
name=gcsfuse (packages.cloud.google.com)
baseurl=https://packages.cloud.google.com/yum/repos/gcsfuse-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
"""
        f.write(_)

    # Package Install
    run_command('yum install -y fuse gcsfuse')

    # Run gcsfuse command
    run_command('gcsfuse -o ro --key-file "~/.gcs.json" --only-dir {{ directory_to_mount }} {{ GCS bucket root directory }} {{ local mountpoint }}')

    # MAIN Example

    # Mount GCS bucket for packer-builds-nightly
    LOG.info('Mounting GCS bucket')
    gcsfuse_mount()

    # Unmount GCS bucket
    LOG.info('GCS mount cleanup')
    run_command(command='fusermount -u {{ local mountpoint }}', noop=False, fail_on_errors=False)
    # Cleanup json key file
    if os.path.exists('~/.gcs.json'):
        os.remove('~/.gcs.json')