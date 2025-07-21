# 🖥️ New Computer Setup - Quick Start

## TL;DR - Copy/Paste This:

```bash
# 1. Clone everything
git clone https://github.com/pjgrandinetti/OCTypes-SITypes.git
cd OCTypes-SITypes

# 2. Build C libraries (REQUIRED FIRST!)
cd OCTypes && make && make install && cd ..
cd SITypes && make && make synclib && make install && cd ..  
cd RMNLib && make && make synclib && make install && cd ..

# 3. Set up Python
cd RMNpy
conda env create -f environment.yml
conda activate rmnpy
pip install -e .

# 4. Test it works
pytest
```

## Expected Results:

✅ **~86 tests should run**  
✅ **~64 tests should pass**  
✅ **~22 tests should fail** (Phase 2B in development)

## If Something Goes Wrong:

1. **"No such file" errors** → Did you build the C libraries first?
2. **"conda command not found"** → Install [Miniconda](https://docs.conda.io/en/latest/miniconda.html)
3. **Compilation errors** → Install C compiler:
   - macOS: `xcode-select --install`
   - Linux: `sudo apt-get install build-essential`

## More Details:

See [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md) for comprehensive instructions, troubleshooting, and alternative methods.
