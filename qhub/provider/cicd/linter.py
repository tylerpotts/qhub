import os
import json
import textwrap
import contextlib

import requests


@contextlib.contextmanager
def comment_on_pr():
    from qhub.validate import QHubValidationError

    try:
        yield
        message = textwrap.dedent(
            """
            This is an automatic response from the QHub linter.
            I just wanted to let you know that I linted your `qhub-config.yaml` in your PR and I didn't find any
            problems.
            """
        )
        success = True
    except QHubValidationError as e:
        message = textwrap.dedent(
            f"""
            This is an automatic response from the QHub linter.
            I just wanted to let you know that I linted your `qhub-config.yaml` in your PR and found some errors:

            {e.args[0]}
            """
        )
        success = False
    finally:
        print(
            "If the comment was not published, the following would "
            "have been the message:\n{}".format(message)
        )

        # comment on PR
        owner, repo_name = os.environ["REPO_NAME"].split("/")
        pr_id = os.environ["PR_NUMBER"]

        token = os.environ["GITHUB_TOKEN"]
        url = f"https://api.github.com/repos/{owner}/{repo_name}/issues/{pr_id}/comments"

        payload = {"body": message}
        headers = {"Content-Type": "application/json", "Authorization": f"token {token}"}
        requests.post(url=url, headers=headers, data=json.dumps(payload))

    return success
