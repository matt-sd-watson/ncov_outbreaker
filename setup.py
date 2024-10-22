from setuptools import setup
from spora import __version__, _program

try:
    import pypandoc
    long_description = pypandoc.convert_file('README.md', 'rst')
except(IOError, ImportError):
    long_description = open('README.md').read()

setup(
    name='spora',
    version=__version__,
    packages=['spora'],
    package_dir={'spora': 'spora'},
    scripts=["spora/workflows/spora.smk",
    "spora/workflows/spora_summary_report.Rmd"],
    url='https://github.com/matt-sd-watson/spora/',
    project_urls = {
        "Issues": "https://github.com/matt-sd-watson/spora/issues",
        "Source": "https://github.com/matt-sd-watson/spora",
    },
    license='',
    author='Matthew Watson',
    author_email='matt.sd.watson@gmail.com',
    description='spora: Streamlined Phylogenomic Outbreak Report Analysis',
    long_description_content_type="text/markdown",
    long_description = long_description,
    install_requires = ["pandas>=1.1.5", "numpy>=1.24.3", "biopython>=1.79", "snakemake>=7.0.0", "pypandoc>=1.8",
                        "pytest>=7.1.2", "click>=8.0.3", "pulp==2.7.0"],
    entry_points="""
    [console_scripts]
    {program} = spora.main:main
    """.format(program=_program),
    include_package_data=True,
)
