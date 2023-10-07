#!/usr/bin/env python3

from dataclasses import dataclass
from enum import Enum
from typing import List
from datetime import datetime
import re
import os
import io
import sys
from contextlib import closing
import zipfile

try:
	import requests
except ImportError:
	print("You need to install the required module! Run `Setup.bat` or `Setup.sh` first.")
	sys.exit(1)


class SystemType(Enum):
	Linux = "linux"
	MacOS = "macos"
	Windows = "windows"

class ArchType(Enum):
	Intel32 = "i686"
	AMD64 = "x86_64"
	ARM64 = "arm64"

class BuildType(Enum):
	Debug = "debug"
	Release = "release"

@dataclass
class TripleGroup:
	system: SystemType
	arch: ArchType
	build: BuildType

	def __str__(self):
		return f"{self.system.value}-{self.arch.value}-{self.build.value}"

@dataclass
class WebGPUNativeAsset:
	triple: TripleGroup
	download_url: str

	def __str__(self):
		return str(self.triple)


@dataclass
class GitHubRelease:
	version: str
	created_at: datetime
	assets: List[WebGPUNativeAsset]


def iso_timestamp_to_datetime(t: str) -> datetime:
	format = '%Y-%m-%dT%H:%M:%SZ'
	return datetime.strptime(t, format)


RELEASE_FILENAME_PATTERN = r"wgpu-(?P<system>linux|macos|windows)-(?P<arch>i686|x86_64|arm64)-(?P<build>debug|release).zip"
def resolve_filename(filename: str) -> TripleGroup:
	match = re.match(RELEASE_FILENAME_PATTERN, filename)
	groups = match.groupdict()
	if groups is None or "system" not in groups or "arch" not in groups or "build" not in groups:
		raise RuntimeError("Error to resolve the filename fetched from GitHub API. Check 'resolve_filename' function to fix up.")
	# Enum class will throw exception while value isn't exist. Just add new item when this happening.
	return TripleGroup(system=SystemType(groups["system"]), arch=ArchType(groups["arch"]), build=BuildType(groups["build"]))


def get_latest_release_from_webgpu_native() -> GitHubRelease:
	url = "https://api.github.com/repos/gfx-rs/wgpu-native/releases/latest"
	resp = requests.get(url).json()
	version_name = resp["tag_name"]
	create_time = iso_timestamp_to_datetime(resp["created_at"])
	assets = resp["assets"]
	content = []
	for asset in assets:
		if asset["content_type"] != "application/zip":
			continue
		asset_name = asset["name"]
		download_url = asset["browser_download_url"]
		triple_group = resolve_filename(asset_name)
		content.append(WebGPUNativeAsset(triple=triple_group, download_url=download_url))
	return GitHubRelease(version=version_name, created_at=create_time, assets=content)


def download_and_extract_zip(*, url: str, target_path: str):
	resp = requests.get(url)
	with closing(resp), zipfile.ZipFile(io.BytesIO(resp.content)) as archive:
		archive.extractall(target_path)


def is_windows():
	import platform
	return platform.system() == "Windows"


def call_external_command(cmd: str):
	import subprocess
	print(f"Running external command:\n{cmd}")
	subprocess.run(cmd, shell=True, check=True, capture_output=False)


WEBGPU_CPP_TOOL_PATH = "Tools/WebGPU-Cpp"
def pull_webgpu_defaults():
	script_path = os.path.join(WEBGPU_CPP_TOOL_PATH, "fetch_default_values.py")
	cmd = f"{'python' if is_windows() else 'python3'} {script_path} --output-defaults defaults.txt --output-spec spec.json"
	call_external_command(cmd)


def create_cpp_headers(*, target_path: str):
	if not os.path.exists(target_path):
		raise RuntimeError(f"Target path {target_path} isn't exists.")

	script_path = os.path.join(WEBGPU_CPP_TOOL_PATH, "generate.py")
	template_path = os.path.join(WEBGPU_CPP_TOOL_PATH, "wgpu-native/webgpu.template.hpp")
	wgpu_h_path = os.path.join(target_path, "wgpu.h") 
	output_hpp_path = os.path.join(target_path, "webgpu.hpp")
	cmd = f"{'python' if is_windows() else 'python3'} {script_path} --template {template_path} --defaults defaults.txt --defaults defaults_extra.txt --header-url {wgpu_h_path} --output {output_hpp_path}"
	call_external_command(cmd)


def move_headers_to_include(*, target_path: str):
	if not os.path.exists(target_path):
		raise RuntimeError(f"Target path {target_path} isn't exists.")
	include_path = os.path.join(target_path, "include/webgpu")
	if not os.path.exists(include_path):
		os.makedirs(include_path)

	import glob
	source_files = glob.glob(f"{target_path}/*.h*")

	import shutil
	for file_path in source_files:
		shutil.move(file_path, include_path)


if __name__ == "__main__":
	import argparse
	import shutil
	parser = argparse.ArgumentParser()
	parser.add_argument("--output", help="Set output path. Default: WebGPU")
	parser.add_argument("--force", help="Force remove output path if exists. Default: false")
	parser.add_argument("--generate_cpp", help="Generate cpp style header. Default: false")
	parser.add_argument("--update_default", help="Update defaults.txt using by WebGPU-Cpp. Default: false")
	args = parser.parse_args()

	output_path = args.output or "WebGPU"
	force_remove = args.force or False
	generate_cpp = args.generate_cpp or False
	update_default = args.update_default or False

	if os.path.exists(output_path):
		if not force_remove:
			ans = input(f"Output path {output_path} exists, do you want to remove it? (Y/n)\n")
			if ans != "Y":
				print("Aborted.")
				sys.exit(0)
		shutil.rmtree(output_path)

	if generate_cpp and (not os.path.exists("defaults.txt") or update_default):
		print("Updating default values ...")
		pull_webgpu_defaults()

	release = get_latest_release_from_webgpu_native()
	for asset in release.assets:
		target_path = os.path.join(output_path, f"{asset.triple.system.value}", f"{asset.triple.arch.value}-{asset.triple.build.value}")
		os.makedirs(target_path)
		print(f"Downloading {asset} to '{target_path}' ...")
		download_and_extract_zip(url=asset.download_url, target_path=target_path)
		create_cpp_headers(target_path=target_path)
		move_headers_to_include(target_path=target_path)
	print("Finished.")
