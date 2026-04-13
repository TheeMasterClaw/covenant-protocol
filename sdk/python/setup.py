from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="covenant-sdk",
    version="1.0.0",
    author="COVENANT Protocol",
    author_email="dev@covenant-protocol.io",
    description="Python SDK for COVENANT Protocol - A decentralized agreement framework",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/covenant-protocol/sdk-python",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: System :: Distributed Computing",
    ],
    python_requires=">=3.8",
    install_requires=[
        "web3>=6.15.0",
        "eth-account>=0.11.0",
        "eth-utils>=4.0.0",
        "hexbytes>=1.0.0",
        "typing-extensions>=4.5.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-asyncio>=0.21.0",
            "black>=23.0.0",
            "isort>=5.12.0",
            "mypy>=1.5.0",
            "flake8>=6.0.0",
        ],
    },
    keywords=[
        "covenant",
        "protocol",
        "ethereum",
        "web3",
        "defi",
        "agreement",
        "task",
        "reputation",
        "dispute",
        "blockchain",
        "smart-contracts",
    ],
)
