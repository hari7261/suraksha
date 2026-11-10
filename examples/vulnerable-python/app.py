# INTENTIONALLY VULNERABLE — DO NOT DEPLOY
import hashlib
import os
import subprocess


def weak_hash(password: str) -> str:
    return hashlib.md5(password.encode("utf-8")).hexdigest()


def run_report(filename: str) -> str:
    # Command injection + path traversal
    target = os.path.join("/var/data", filename)
    return subprocess.check_output(f"cat {target}", shell=True, text=True)

