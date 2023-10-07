# WebGPU Cpp Integration Utility

## Requirements

Python 3.7 and above

## Usage

1. Clone this project

```bash
git clone https://github.com/DarcJC/WebGPU-Cpp-Integration.git
```

2. Initializing the dependencies of this project.

```bash
# Liunx or Unix
chmod +x Setup.sh && ./Setup.sh
# Windows
./Setup.bat
```

3. Collect your dependencies

```bash
# Linux or Unix
python3 generate_required_dependencies.py --output WebGPU
# Windows
python generate_required_dependencies.py --output WebGPU

# With webgpu.hpp
python generate_required_dependencies.py --output WebGPU --generate_cpp 1
```

## Tips

- You can modify `defaults_extra.txt` to override defaults value using by WebGPU-Cpp.
- Use `python generate_required_dependencies.py -h` to see more information.
