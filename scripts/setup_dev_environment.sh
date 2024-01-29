#!/bin/bash

#region Local Variables ###

REQUIRED_PYTHON_VERSION="3.11.1"

#endregion


#region Environment Variables ###

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPTS_DIR}/set_vars.sh"
if [ $? -ne 0 ] ; then 
    exit 1
fi

#endregion


#region Applications ###

# go to root
cd $ROOT_DIR

# install sudo  (cwd = ROOT_DIR)
if ! sudo --version >/dev/null 2>&1 ; then 
    echo "installing sudo..."
    su root
    apt install -qqy sudo
    exit
fi
if ! sudo --version >/dev/null 2>&1 ; then 
    echo 'failed to install sudo, exiting...'
    exit 1
fi
if [ $PRINT_APP_VERSIONS ] ; then
    sudo --version | head -n 1
fi

# homebrew
if ! brew --version >/dev/null 2>&1 ; then 
    echo "installing homebrew..."
    sudo apt install -qqy build-essential procps curl file git gcc
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/$USER/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
if ! brew --version >/dev/null 2>&1 ; then 
    echo 'failed to install homebrew, exiting...'
    exit 1
fi
if [ $PRINT_APP_VERSIONS ] ; then
    brew --version
fi

# python
if ! python --version >/dev/null 2>&1 && python3 --version >/dev/null 2>&1 ; then 
    alias python=python3
fi
if [ "$(python --version)" != "Python ${REQUIRED_PYTHON_VERSION}" ] ; then 
    if ! pyenv --version >/dev/null 2>&1 ; then 
        echo "installing pyenv..."
        brew install pyenv
    fi
    if ! pyenv --version >/dev/null 2>&1 ; then 
        echo 'failed to install pyenv, exiting...'
        exit 1
    fi
    echo "installing python ${REQUIRED_PYTHON_VERSION}..."
    pyenv install $REQUIRED_PYTHON_VERSION
    pyenv global $REQUIRED_PYTHON_VERSION
fi
if [ "$(python --version)" != "Python ${REQUIRED_PYTHON_VERSION}" ] ; then 
    echo 'failed to install python, exiting...'
    exit 1
fi
if [ $PRINT_APP_VERSIONS ] ; then
    python --version
fi

# pip
if ! pip --version >/dev/null 2>&1 ; then 
    sudo apt install -qqy "python$(echo $REQUIRED_PYTHON_VERSION | cut -d'.' -f1,2)-distutils"
    wget https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py
fi
if ! pip --version >/dev/null 2>&1 ; then 
    echo 'failed to install pip, exiting...'
    exit 1
fi
if [ $PRINT_APP_VERSIONS ] ; then
    pip --version
fi

# ansible
if ! ansible --version >/dev/null 2>&1 ; then 
    pip install ansible
fi
if ! ansible --version >/dev/null 2>&1 ; then 
    echo 'failed to install ansible, exiting...'
    exit 1
fi
if [ $PRINT_APP_VERSIONS ] ; then
    ansible --version | head -n 1
fi

# terraform
if ! terraform --version >/dev/null 2>&1 ; then 
    brew install terraform
fi
if ! terraform --version >/dev/null 2>&1 ; then 
    echo 'failed to install terraform, exiting...'
    exit 1
fi
if [ $PRINT_APP_VERSIONS ] ; then
    terraform --version | head -n 1
fi

#endregion

echo -e "\n\n---===   Dev Environment Setup Completed Successfully   ===---"
