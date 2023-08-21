# Environment for high energy physics and machine learning lab (HEP ML Lab)

## Description
`hml-env` is a comprehensive environment designed to facilitate research and
development at the crossroads of high-energy physics and machine learning.
Utilizing Docker technology, it offers a seamless, unified environment that
ensures compatibility and simplifies configuration.

`hml-env` supports a wide range of essential tools, including:

- Python3.8
- ROOT6
- MadGraph5

## History

### 1.7.2
- Fix locale via environment variables
- Add welcome banner when a user uses ssh

### 1.7.1
- Fix environment variables missing when sshing into a container

### 1.7
- Support ssh server
- Fix locales and Delphes enviroment variables

### 1.6
- Remove python packages
- Remove external Delphes, FastJet, fjcontrib
- Change entry point to allow users to run commands directly and launch zsh by
  default

### 1.5
- Fix auto-update issue of madgraph5
    > `auto_update = 0` does not work as it says "no update check" but "update check every time". So it has been set to 600 meaning 600 days.
- Remove pythia8 from conda-force
    > since `PYTHIA8DATA` environment variable is reset by it without notification and as a consequence, madgraph5 or commands from delphes raise error associated with the version of pythia8.

### 1.4.1
- Fix the conflict of pythia8 inside of madgraph5 and the one installed by conda

### 1.4
- Add support for pytorch

### 1.3.1
- Remove pythia8-config with python to fix the conflict of compiled pythia8
- Turn off the auto-updates of MG5

### 1.3
- Change python version from 3.9 to 3.8 to be compatible with pyROOT and pythia8
- Add lhapdf6.5.3 to support usage in MG5
- Add support to conda version Pythia8
- Fix the pyROOT not found in miniconda python

### 1.2
- Change zsh into official intallation way
- Fix "which conda" not correctly showing the conda path

### 1.1
- Remove GUILD_HOME
- Set zsh as the default shell and add plugins

### 1.0
- support for usual softwares used in HEP (MG5, Pythia8, Delphes3, FastJet3).
- support for machine learning.