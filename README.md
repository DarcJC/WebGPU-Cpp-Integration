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

4. Add to your project

**If you'r using a building tool other than CMake, you should configure the header path and the linker on your own.**

```cmake
find_package(WebGPU PATHS PATH/TO/CMake/DIRECTORY NO_DEFAULT_PATH REQUIRED)
target_link_libraries(YourTarget PUBLIC WebGPU)
target_include_directories(YourTarget PUBLIC ${WEBGPU_INCLUDE_DIR})
```

## Tips

- You can modify `defaults_extra.txt` to override defaults value using by WebGPU-Cpp.
- Use `python generate_required_dependencies.py -h` to see more information.
- If you encounter network issues, try to export an environment variable `ALL_PROXY=http://your-proxy:7890` to using a proxy.
