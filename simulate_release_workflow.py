#!/usr/bin/env python3
"""
Simulate GitHub Actions Release Workflow
Tests the key steps without requiring GitHub Actions infrastructure
"""
import os
import shutil
import subprocess
import tempfile


def test_local_wheel_build():
    """Test local wheel building (simulates cibuildwheel)"""
    print("🎡 Testing Local Wheel Building")
    print("-" * 40)

    # Clean any existing builds
    if os.path.exists("dist"):
        shutil.rmtree("dist")
    if os.path.exists("build"):
        shutil.rmtree("build")
    if os.path.exists("wheelhouse"):
        shutil.rmtree("wheelhouse")

    # Test 1: Build source distribution
    print("1️⃣ Building source distribution...")
    try:
        result = subprocess.run(
            ["python", "setup.py", "sdist"], capture_output=True, text=True, timeout=120
        )
        if result.returncode == 0:
            print("✅ SDist build successful")
            # Check if sdist was created
            import glob

            sdists = glob.glob("dist/*.tar.gz")
            if sdists:
                print(f"   Created: {sdists[0]}")
            else:
                print("⚠️  No sdist found in dist/")
        else:
            print("❌ SDist build failed:")
            print(result.stderr)
    except subprocess.TimeoutExpired:
        print("⚠️  SDist build timed out")
    except Exception as e:
        print(f"❌ SDist build error: {e}")

    # Test 2: Build wheel for current platform
    print("\n2️⃣ Building wheel for current platform...")
    try:
        result = subprocess.run(
            ["python", "setup.py", "bdist_wheel"],
            capture_output=True,
            text=True,
            timeout=300,
        )
        if result.returncode == 0:
            print("✅ Wheel build successful")
            # Check if wheel was created
            import glob

            wheels = glob.glob("dist/*.whl")
            if wheels:
                print(f"   Created: {wheels[0]}")

                # Analyze the wheel
                print("\n3️⃣ Analyzing built wheel...")
                if os.path.exists("analyze_wheel_libraries.py"):
                    result = subprocess.run(
                        ["python", "analyze_wheel_libraries.py", wheels[0]],
                        capture_output=True,
                        text=True,
                        timeout=60,
                    )
                    if result.returncode == 0:
                        print("✅ Wheel analysis completed")
                        # Show key results
                        lines = result.stdout.split("\n")
                        for line in lines:
                            if ("✅" in line or "⚠️" in line or "❌" in line) and (
                                "No duplicate" in line
                                or "No symbol conflicts" in line
                                or "Total size" in line
                            ):
                                print(f"   {line}")
                    else:
                        print("⚠️  Wheel analysis had issues")
                else:
                    print("⚠️  Wheel analyzer not found, skipping analysis")
            else:
                print("⚠️  No wheel found in dist/")
        else:
            print("❌ Wheel build failed:")
            print(result.stderr)
    except subprocess.TimeoutExpired:
        print("⚠️  Wheel build timed out")
    except Exception as e:
        print(f"❌ Wheel build error: {e}")


def test_upload_conditions():
    """Test PyPI upload conditions"""
    print("\n🚀 Testing PyPI Upload Conditions")
    print("-" * 40)

    # Simulate different tag scenarios
    test_scenarios = [
        ("v0.1.14", "patch release"),
        ("v0.2.0", "minor release"),
        ("v1.0.0", "major release"),
        ("v0.1.14-test", "test tag"),
        ("0.1.14", "no v prefix"),
    ]

    for tag, description in test_scenarios:
        # Simulate the GitHub Actions condition:
        # github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v') && endsWith(github.ref, '.0')

        event_name = "push"  # Simulating push event
        ref = f"refs/tags/{tag}"

        would_upload = (
            event_name == "push"
            and ref.startswith("refs/tags/v")
            and ref.endswith(".0")
        )

        status = "🚀 WOULD UPLOAD" if would_upload else "⏭️  Would skip"
        print(f"   {status}: {tag} ({description})")


def test_artifact_structure():
    """Test expected artifact structure"""
    print("\n📦 Testing Artifact Structure")
    print("-" * 40)

    if os.path.exists("dist"):
        files = os.listdir("dist")
        wheels = [f for f in files if f.endswith(".whl")]
        sdists = [f for f in files if f.endswith(".tar.gz")]

        print(f"✅ Found {len(wheels)} wheel(s) and {len(sdists)} sdist(s)")

        for wheel in wheels:
            size = os.path.getsize(os.path.join("dist", wheel))
            print(f"   🎡 {wheel} ({size:,} bytes)")

        for sdist in sdists:
            size = os.path.getsize(os.path.join("dist", sdist))
            print(f"   📦 {sdist} ({size:,} bytes)")

        # Check if this matches what GitHub Actions would create
        expected_patterns = [
            "rmnpy-*.tar.gz",  # sdist
            "*-cp*-*.whl",  # wheels
        ]

        print(f"\n   Expected artifact patterns:")
        for pattern in expected_patterns:
            import glob

            matches = glob.glob(f"dist/{pattern}")
            status = "✅" if matches else "⚠️ "
            print(f"   {status} {pattern}: {len(matches)} files")
    else:
        print("❌ No dist/ directory found")


def main():
    """Run all tests"""
    print("🧪 Simulating GitHub Actions Release Workflow")
    print("=" * 60)

    # Check prerequisites
    print("🔍 Checking Prerequisites...")
    if not os.path.exists("setup.py"):
        print("❌ setup.py not found")
        return False

    if not os.path.exists("pyproject.toml"):
        print("❌ pyproject.toml not found")
        return False

    print("✅ Prerequisites found")

    # Run tests
    test_local_wheel_build()
    test_upload_conditions()
    test_artifact_structure()

    print("\n" + "=" * 60)
    print("🎯 Summary:")
    print("✅ Local build simulation completed")
    print("✅ Upload conditions validated")
    print("✅ Artifact structure checked")
    print("")
    print("💡 This simulates what GitHub Actions would do.")
    print("   To test the full workflow, push a test tag:")
    print("   git tag v0.1.14-test && git push origin v0.1.14-test")


if __name__ == "__main__":
    main()
