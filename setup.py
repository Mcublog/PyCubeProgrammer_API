import os

from setuptools import setup
from distutils.extension import Extension

from Cython.Build import cythonize

bit_version = os.environ["PROCESSOR_ARCHITECTURE"]
if bit_version == "AMD64":
    bit_version = "x64"

DDL_PATH = './api/lib'
FLASH_LOADER_PATH = './api/lib/FlashLoader/'
DATA_BASE_PATH = './api/Data_Base'


dll_list = [f"{DDL_PATH}/{file}" for file in os.listdir(DDL_PATH) if "." in file]
flash_loader = [f"{FLASH_LOADER_PATH}/{file}" for file in os.listdir(FLASH_LOADER_PATH) if "." in file]
data_base = [f"{DATA_BASE_PATH}/{file}" for file in os.listdir(DATA_BASE_PATH) if "." in file]

extensions = [
    Extension(
        "CubeProgrammer_API",
        ["CubeProgrammer_API.pyx"],
        libraries=["CubeProgrammer_API"], language="c++",
        library_dirs=[f'./api/lib/{bit_version}'],
    )
]

setup(
    name="CubeProgrammer_API",
    version='0.1.2',
    description='CubeProgrammer_API.py',
    author='Jim Fred',
    author_email='jimfred@jimfred.org',
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            'language_level': "3",
            'always_allow_keywords': True  # https://github.com/cython/cython/issues/2881
        }),
    data_files=[
        ('lib/site-packages', dll_list),
        ('lib/site-packages/cube/lib/FlashLoader', flash_loader),
        ('lib/site-packages/cube/Data_Base', data_base)
    ],
    include_package_data=True,
    requires=["Cython"]
)
