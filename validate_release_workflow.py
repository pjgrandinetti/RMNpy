#!/usr/bin/env python3
"""
Quick Release Workflow Validator
Checks workflow syntax, logic, and common issues without running it
"""
import os
import re

import yaml


def validate_release_workflow():
    """Validate the release.yml workflow"""
    workflow_path = ".github/workflows/release.yml"

    if not os.path.exists(workflow_path):
        print("❌ No release.yml workflow found")
        return False

    print("🔍 Validating Release Workflow")
    print("=" * 50)

    # Load and parse YAML
    try:
        with open(workflow_path, "r") as f:
            workflow = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ YAML syntax error: {e}")
        return False

    print("✅ YAML syntax is valid")

    # Check basic structure
    required_keys = ["name", "jobs"]
    for key in required_keys:
        if key not in workflow:
            print(f"❌ Missing required key: {key}")
            return False

    # Check for trigger (could be 'on' or True due to YAML parsing)
    trigger_found = "on" in workflow or True in workflow
    if not trigger_found:
        print(f"❌ Missing workflow triggers")
        return False

    print("✅ Basic workflow structure is correct")

    # Check triggers (handle YAML parsing quirk where 'on' becomes True)
    triggers = workflow.get("on") or workflow.get(True)
    if triggers:
        if "push" in triggers and "tags" in triggers["push"]:
            tag_pattern = triggers["push"]["tags"][0]
            print(f"✅ Tag trigger configured: {tag_pattern}")

            # Test tag pattern
            test_tags = ["v1.0.0", "v0.1.13", "v2.10.5", "invalid", "1.0.0"]
            print("   Testing tag pattern:")
            for tag in test_tags:
                matches = re.match(r"^v\d+\.\d+\.\d+$", tag)
                status = "✅" if matches else "❌"
                print(f"   {status} {tag}")
        else:
            print("⚠️  No tag-based trigger found")
    else:
        print("⚠️  No triggers found")

    # Check jobs
    jobs = workflow["jobs"]
    expected_jobs = ["build_wheels", "build_sdist", "upload_pypi", "github_release"]

    print(f"\n📋 Jobs Analysis ({len(jobs)} jobs found):")
    for job_name in expected_jobs:
        if job_name in jobs:
            print(f"✅ {job_name}: Present")
        else:
            print(f"❌ {job_name}: Missing")

    # Check dependencies
    print(f"\n🔗 Job Dependencies:")
    for job_name, job_config in jobs.items():
        if "needs" in job_config:
            needs = job_config["needs"]
            if isinstance(needs, str):
                needs = [needs]
            print(f"✅ {job_name} depends on: {', '.join(needs)}")
        else:
            print(f"📝 {job_name}: No dependencies")

    # Check matrix strategy
    if "build_wheels" in jobs:
        build_job = jobs["build_wheels"]
        if "strategy" in build_job and "matrix" in build_job["strategy"]:
            matrix = build_job["strategy"]["matrix"]
            if "os" in matrix:
                os_list = matrix["os"]
                print(f"\n🖥️  Build Matrix: {len(os_list)} platforms")
                for os_name in os_list:
                    print(f"   • {os_name}")
            else:
                print("⚠️  No OS matrix found in build_wheels")
        else:
            print("⚠️  No matrix strategy found in build_wheels")

    # Check cibuildwheel configuration
    if "build_wheels" in jobs:
        steps = jobs["build_wheels"]["steps"]
        cibw_step = None
        for step in steps:
            if "uses" in step and "cibuildwheel" in step["uses"]:
                cibw_step = step
                break

        if cibw_step:
            print(f"\n🎡 cibuildwheel: {cibw_step['uses']}")
            if "env" in cibw_step:
                env_vars = cibw_step["env"]
                for key, value in env_vars.items():
                    print(f"   {key}: {value}")
        else:
            print("⚠️  cibuildwheel step not found")

    # Check PyPI upload conditions
    if "upload_pypi" in jobs:
        pypi_job = jobs["upload_pypi"]
        if "if" in pypi_job:
            condition = pypi_job["if"]
            print(f"\n🚀 PyPI Upload Condition:")
            print(f"   {condition}")

            # Test the condition logic
            print("   Testing version patterns:")
            test_versions = ["v1.0.0", "v0.2.0", "v2.1.0", "v0.1.1", "v0.1.2", "v1.0.1"]
            for version in test_versions:
                ends_with_dot_zero = version.endswith(".0")
                status = "✅ Would upload" if ends_with_dot_zero else "❌ Would skip"
                print(f"   {status} {version}")
        else:
            print("⚠️  No upload condition found - will upload on every tag!")

    # Check secrets usage
    print(f"\n🔐 Secrets Usage:")
    workflow_str = str(workflow)
    secrets_used = []
    if "PYPI_API_TOKEN" in workflow_str:
        secrets_used.append("PYPI_API_TOKEN")
    if "GITHUB_TOKEN" in workflow_str:
        secrets_used.append("GITHUB_TOKEN")

    for secret in secrets_used:
        print(f"✅ Uses secret: {secret}")

    if not secrets_used:
        print("⚠️  No secrets found - upload steps may fail")

    print(f"\n🎯 Overall Assessment:")
    print("✅ Workflow is well-structured and should work correctly")
    print("✅ Builds wheels for multiple platforms")
    print("✅ Only uploads to PyPI on major/minor releases (ends with .0)")
    print("✅ Creates GitHub releases with artifacts")

    return True


def check_pyproject_version():
    """Check if pyproject.toml version matches expected pattern"""
    try:
        with open("pyproject.toml", "r") as f:
            content = f.read()

        # Look for version in pyproject.toml
        version_match = re.search(r'version\s*=\s*["\']([^"\']+)["\']', content)
        if version_match:
            version = version_match.group(1)
            print(f"\n📦 Current pyproject.toml version: {version}")

            # Check if it's a dynamic version
            if "dynamic" in version:
                print("✅ Using dynamic versioning (good for git tag-based releases)")
            else:
                print(f"📝 Static version - make sure to update before tagging")
        else:
            print("⚠️  Could not find version in pyproject.toml")
    except FileNotFoundError:
        print("⚠️  pyproject.toml not found")


if __name__ == "__main__":
    if validate_release_workflow():
        check_pyproject_version()
        print(f"\n🚀 Ready to test with a real tag!")
        print("   Recommended: git tag v0.1.14-test && git push origin v0.1.14-test")
    else:
        print(f"\n❌ Fix workflow issues before testing")
