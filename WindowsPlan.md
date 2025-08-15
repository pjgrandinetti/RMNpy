===============================================================================
RMNpy — EASIEST WINDOWS UNBLOCK PLAN (Bridge DLL, No Header Changes)
Target: MSYS2/MinGW64 on GitHub Actions and local Windows dev

OBJECTIVE

Create ONE umbrella/bridge DLL from your existing static libraries and link all
Cython extensions only against that DLL’s import library. This avoids editing
any headers or maintaining .def files, prevents code duplication across .pyds,
and unblocks CI quickly.

RESULT (WHAT YOU’LL HAVE)
	•	A single runtime DLL:        lib/rmnstack_bridge.dll
	•	Its import library:          lib/rmnstack_bridge.dll.a
	•	All Python .pyd extensions link ONLY to …/rmnstack_bridge.dll.a
	•	Exactly one copy of OCTypes/SITypes/RMN code loaded at runtime.

PRECONDITIONS
	•	MSYS2 MINGW64 shell/toolchain (x86_64-w64-mingw32-gcc, binutils) available.
	•	You already have the vendor static archives:
lib/libOCTypes.a
lib/libSITypes.a
lib/libRMN.a
	•	External libs (if required by the static libs): openblas, lapack, curl, etc.

⸻

STEP 0 — REPO LAYOUT (ASSUMED)

/
lib/
libOCTypes.a
libSITypes.a
libRMN.a
src/…                        # your Cython sources
setup.py                     # will be edited
(optional) scripts/, .github/workflows/…

⸻

STEP 1 — BUILD THE BRIDGE DLL (ONE COMMAND)

In MSYS2 MINGW64 shell:

mkdir -p lib
x86_64-w64-mingw32-gcc -shared -o lib/rmnstack_bridge.dll
-Wl,–out-implib,lib/rmnstack_bridge.dll.a
-Wl,–export-all-symbols
lib/libRMN.a lib/libSITypes.a lib/libOCTypes.a
-lopenblas -llapack -lcurl -lgcc_s -lwinpthread -lquadmath -lgomp -lm

Notes:
	•	–export-all-symbols: auto-exports everything pulled from the static libs.
(Fastest unblock; you can curate exports later if desired.)
	•	Add/remove external libs at the end as needed by your static archives.

⸻

STEP 1B — OPTIONAL MAKEFILE TARGET (DROP-IN)

Makefile snippet placed at project root

CC      ?= x86_64-w64-mingw32-gcc
MKDIR_P ?= mkdir -p

BRIDGE_DLL    := lib/rmnstack_bridge.dll
BRIDGE_IMPLIB := lib/rmnstack_bridge.dll.a

.PHONY: bridge
bridge:
@$(MKDIR_P) lib
$(CC) -shared -o $(BRIDGE_DLL)
-Wl,–out-implib,$(BRIDGE_IMPLIB)
-Wl,–export-all-symbols
lib/libRMN.a lib/libSITypes.a lib/libOCTypes.a
-lopenblas -llapack -lcurl -lgcc_s -lwinpthread -lquadmath -lgomp -lm

⸻

STEP 2 — MODIFY setup.py TO LINK ONLY TO THE BRIDGE

Inside your Windows branch in setup.py, replace vendor libs with the bridge:

inside if platform.system() == “Windows”:

mingw_prefix = os.environ.get(“MSYSTEM_PREFIX”, “/mingw64”)
include_dirs.extend([f”{mingw_prefix}/include/openblas”, f”{mingw_prefix}/include”])
library_dirs.extend([f”{mingw_prefix}/lib”])

extra_link_args = [
“-Wl,–enable-auto-import”,
“-Wl,–disable-auto-image-base”,
os.path.abspath(“lib/rmnstack_bridge.dll.a”),   # <<< the only vendor lib
]
libraries = [“curl”, “openblas”, “lapack”, “gcc_s”, “winpthread”, “quadmath”, “gomp”, “m”]

IMPORTANT:
	•	Do NOT also pass libRMN.a/libSITypes.a/libOCTypes.a to the extensions.
	•	Ensure only the bridge import lib appears in extra_link_args (explicit path).

⸻

STEP 3 — ENSURE THE DLL IS FOUND AT RUNTIME

You have two simple options. Choose ONE.

Option A (recommended): Ship the bridge DLL next to the importing .pyd files.
	•	Copy lib/rmnstack_bridge.dll into your Python package directory so it sits
alongside the compiled extension modules (e.g., src/rmnpy/ or rmnpy/).
	•	Include it in the wheel via setup.cfg or MANIFEST.in.

Example (setup.cfg):
[options.package_data]
rmnpy = rmnstack_bridge.dll

Option B: Keep the DLL in rmnpy/lib and add that folder to DLL search path.
In rmnpy/init.py (before importing Cython submodules):

import os, sys
if sys.platform == “win32”:
dll_dir = os.path.join(os.path.dirname(file), “lib”)
if hasattr(os, “add_dll_directory”):
os.add_dll_directory(dll_dir)
else:
os.environ[“PATH”] = dll_dir + os.pathsep + os.environ.get(“PATH”, “”)

⸻

STEP 4 — GITHUB ACTIONS (MSYS2) SKETCH
	•	uses: msys2/setup-msys2@v2
with:
update: true
msystem: MINGW64
install: >
mingw-w64-x86_64-toolchain
mingw-w64-x86_64-binutils
mingw-w64-x86_64-python
mingw-w64-x86_64-python-numpy
mingw-w64-x86_64-cython
mingw-w64-x86_64-openblas

Build the bridge
	•	name: Build bridge DLL
shell: msys2 {0}
run: |
mkdir -p lib
x86_64-w64-mingw32-gcc -shared -o lib/rmnstack_bridge.dll
-Wl,–out-implib,lib/rmnstack_bridge.dll.a
-Wl,–export-all-symbols
lib/libRMN.a lib/libSITypes.a lib/libOCTypes.a
-lopenblas -llapack -lcurl -lgcc_s -lwinpthread -lquadmath -lgomp -lm
objdump -p lib/rmnstack_bridge.dll | sed -n ‘/Export Table/,$p’ | head -n 120

Build & install Python package
	•	name: Build RMNpy
shell: msys2 {0}
run: |
python -m pip install -U pip wheel
python -m pip install -v .

⸻

STEP 5 — VALIDATION
	1.	Check the bridge exports (sanity):
objdump -p lib/rmnstack_bridge.dll | sed -n ‘/Export Table/,$p’ | head -n 120
	2.	Verify only the bridge import lib is used by the extensions (build log should
show …/rmnstack_bridge.dll.a and not libRMN.a/libSITypes.a/libOCTypes.a).
	3.	Import test:
python -c “import rmnpy; print(‘OK’)”
	4.	At runtime, use Process Explorer/handle.exe if desired to confirm a single
rmnstack_bridge.dll is mapped once after importing multiple rmnpy modules.

⸻

TROUBLESHOOTING
	•	Undefined external from BLAS/LAPACK/curl:
Add the missing libraries after the static archives in the bridge link line.
	•	“DLL not found” on import:
Ensure the DLL is either in the same directory as the .pyd (Option A) or the
folder is added with os.add_dll_directory (Option B). Wheels should include it.
	•	Duplicate symbol errors during bridge link:
Rare. If vendor archives contain overlapping objects, try reordering:
lib/libSITypes.a lib/libRMN.a lib/libOCTypes.a
or, as a last resort, remove -Wl,–export-all-symbols and curate with a .def.
	•	Mixing MSVC and MinGW:
Not supported. Ensure everything is MinGW-w64 built (same triplet).

⸻

ROLL-FORWARD (OPTIONAL, LATER)

When time permits, replace the bridge with proper dynamic linking:
	•	Add portable *_API export macros in each library’s public headers.
	•	Build each as a DLL with: -Wl,–out-implib,lib.dll.a
	•	Link extensions against: libRMN.dll.a libSITypes.dll.a libOCTypes.dll.a
This yields a tighter ABI but is NOT required to unblock you now.

===============================================================================
END OF PLAN — minimal changes, no header edits, fast CI unblocking
