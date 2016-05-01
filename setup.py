try:
    from setuptools import setup
except ImportError:
    	from distutils.core import setup

from Cython.Build import cythonize

def read(filename):
   with open(os.path.join(os.path.dirname(__file__), filename)) as f:
       return f.read()

import os
import sys
import setuptools
setuptools.setup(
   name="VaLoR",
   version="0.0.1",
   author="Xuefang Zhao, University of Michigan",
   author_email="xuefzhao@umich.edu",
   description="Randomized tool to detect and resolve complex structural variants.",
   long_description=read("README.md"),
   packages=["valor"],
   package_data={
       "valor": [
           "templates/pred_config",
           "templates/truth_config",
           "contrib/SMCScoring.py",
       ],
   },
   license="Propriety",
   keywords="Complex Structural Variants",
   classifiers=[
       "Development Status :: 1 - Planning",
       "Environment :: Console",
       "Intended Audience :: Information Technology",
       "Intended Audience :: Science/Research",
       "License :: Other/Proprietary License",
       "Natural Language :: English",
       "Programming Language :: Python :: 2",
       "Programming Language :: Python :: 2 :: Only",
       "Topic :: Scientific/Engineering :: Bio-Informatics",
   ],
   entry_points={
       "console_scripts": [
           "VaLoR=valor.__main__:main",
           "valor=valor.__main__:main",
       ]
   },
)



setup(
    ext_modules = cythonize("VaLoR/*.pyx")
)
