#!/bin/bash

# show help file
function usage() {
    cat <<EOF
    usage: $0 options

    Sets up and configures the shell environment and tooling for a user
    workstation.  Accepts optional flags to do partial setup.  With no command
    arguments provided, this will do all of the following

    OPTIONS:
       -h  Show this message

       -q  Configure Bash Profile
       -w  Install packages
       -e  Install PIP Modules
       -r  Install Python
       -t  Setup for loading API tokens
       -y  Setup for AWS Credentials
       -u  Configure git
       -i  Install p4merge
       -o  Install Sublime Text 3
       -p  Install GAM cli tool
       -a  Source ops-tools bash files
       -s  Configure SSH key

EOF
}


# formatting for headers
function print_header() {
    section="${1}"
    pad_length=$(((100 - ${#section}) / 2))
    padding=""
    for ((x=1; x <= pad_length; x++)); do
        padding+="="
    done
    echo "${padding} ${section} ${padding}"
}


# constants needed for script
function declare_constants() {
    if [[ "${platform}" = "Darwin" ]]; then
        p4_app_dest="/Applications/p4merge.app"
        p4_app_path="${p4_app_dest}/Contents/Resources/launchp4merge"
    else
        p4_app_dest="/opt/p4merge"
        p4_app_path="${p4_app_dest}/bin/p4merge"
    fi
}


# detect platform
function check_which_platform() {
    platform="$(uname)"
    case "${platform}" in
        Darwin)
            echo "Platform detected: OS X"
            return 0
            ;;
        Linux)
            echo "Platform detected: Linux"
            return 1
            ;;
        *)
            echo "Platform not supported"
            exit 1
            ;;
    esac
}


# prompt user if okay to proceed
function confirm() {
    local action="${1}"
    local response
    echo "${action}"
    echo "OK to proceed? [y/N]: "
    # SC-NOTE: We don't care about backslash mangling by read - disable check 2162 https://github.com/koalaman/shellcheck/wiki/SC2162
    # shellcheck disable=SC2162
    read -sn1 response
    case "${response}" in
        [yY])
            return 0
        ;;
        *)
            return 1
        ;;
    esac

}


# get name from system whoami
function get_name_osx() {
    full_name="$(id -F)"
}


# get name from system whoami
function get_name_lnx() {
    gecos_name="$(getent passwd "$(whoami)" | cut -d ':' -f 5 | cut -d ',' -f1)"
    if [[ -n "${gecos_name}" ]]; then
        full_name="${gecos_name}"
    else
        echo "Can't find real name ..."
        fix_name
    fi
}


# allow user to enter own name
function fix_name() {
    echo "Please enter or correct your name"
    sudo chfn "${USER}"

}


# set up user's name and associated info
function parse_name_info() {
    local names=(${full_name})
    email_domain="aurora.tech"

    echo "Welcome ${names[0]}"

    # Add test to see if initials are already set in the environment, otherwise prompt
    # SC-NOTE: We don't care about backslash mangling on read - disable check 2162 https://github.com/koalaman/shellcheck/wiki/SC2162
    # shellcheck disable=SC2162
    if [[ -z ${INITIALS+x} ]]; then
        read -p "What is your middle initial? " middle_i
    else
        middle_i="${INITIALS:1:1}"
    fi

    inits="${names[0]:0:1}${middle_i}${names[1]:0:1}"
    inits="$(tr '[:lower:]' '[:upper:]' <<< "${inits}")"

    if [[ -n ${CORP_USERNAME} ]]; then
        username="${CORP_USERNAME}"
    else

        username="${names[0]:0:1}${names[1]}"
        username="$(tr '[:upper:]' '[:lower:]' <<< "${username}")"
    fi

    dot_name="$(tr '[:upper:]' '[:lower:]' <<< "${full_name}" | tr -d '[:punct:]' | tr ' ' \.)"

    if [[ -n ${CORP_GPGKEY_ADDRESS} ]]; then
        email_addy="${CORP_GPGKEY_ADDRESS}"
    else
        email_addy="${dot_name}@${email_domain}"
    fi

}


# parse and display user's name/name-based info
function do_name_stuff() {
    if [[ "${platform}" = "Darwin" ]]; then
        get_name_osx
    else
        get_name_lnx
    fi
    parse_name_info

    echo "Username: ${username}"
    echo "Initials: ${inits}"
    echo "Dot Name: ${dot_name}"
    echo "Email: ${email_addy}"
}


# set up standard bash_profile
function std_bash_profile() {

cat <<-EOF
HOMEDIR=~/

# Load .bashrc if it exists
test -f \${HOME}/.bashrc && source \${HOME}/.bashrc


# Load everything from profile.d folder
for file in \${HOME}/.profile.d/*.sh; do
  source \${file};
done

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

#Make sure ~/bin is in the path
[[ ! "\$PATH" =~ "\${HOME}/bin" ]] && export PATH="\${HOME}/bin:\${PATH}"

#Determine where a shell function is defined / declared
function find_function {
  shopt -s extdebug
  declare -F "\$1"
  shopt -u extdebug
}

EOF

}


# set up more personalized bash_profile
function get_user_bash() {

    cat <<-EOF

############################################################
# Update the following to personalize your bash_profile
# this file will be automatically be sourced via ${HOME}/.bash_profile

## GPG Email
#The email address associated with your GPG key
export CORP_GPGKEY_ADDRESS="${email_addy}"

export INITIALS="${inits}"

#Folder path to where you will be checking out git projects
export CORP_HOME="\${HOME}/src"

#Path to your ipsec secrets file
export IPSEC_SECRETS_FILE=/usr/local/etc/ipsec.secrets

export CORP_USERNAME=\${USER}

export KEY_SUFFIX="[DOMAIN]"
export GIT_ORG="[GITORG]"

# Set architecture flags for Ruby RVM to play nice
export ARCHFLAGS="-arch x86_64"

##########################################################

## Feel free to add your own shell customizations here

EOF

}


# sets up bash_profile
function do_bash_profile() {
    print_header "Setting up bash profile"

    if [[ -e "${HOME}/.bash_profile" ]]; then
        backup_file="old_bash_profile_$(date +%F)"
        echo "Backing up existing .bash_profile as: ${backup_file}"
        sleep 1
        mv "${HOME}/.bash_profile" "${HOME}/${backup_file}"
    fi
    echo "Writing new bash profile from template"
    std_bash_profile > "${HOME}/.bash_profile"

    mkdir -p "${HOME}/.profile.d"

    pushd "${HOME}/.profile.d" >/dev/null 2>&1
        if [[ -e "00-${username}.sh" ]]; then
            echo "Personal profile exists as 00-${username}.sh skipping"
        else
            echo "Creating Personal profile 00-${username}.sh"
            get_user_bash > "00-${username}.sh"
        fi
    popd >/dev/null 2>&1

    #Re-source the bash profile so it is available for the rest of this run
    # SC-NOTE: Disable non-constant source check https://github.com/koalaman/shellcheck/wiki/SC1090
    # SC-NOTE: we know what ~ will eval to even though sc can't
    #shellcheck disable=SC1090
    source ~/.bash_profile

}


# installs packages via homebrew for OS X
function do_install_homebrew_pkgs_osx() {
    print_header "Installing HomeBrew"

    brew_packages=(awscli bash-completion cairo gdk-pixbuf gist git jq libffi
                   libxml2 libxslt pango pigz pv python python3 shellcheck
                   wget ykpers figlet)

    # Future TODO: Support yubikey via brew cask
    # brew_cask_packages=(yubikey-neo-manager yubikey-personalization-gui)

    if [[ ! $(which brew) ]]; then
        echo "Installing homebrew"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew update
    echo "Installing brew packages"
    for pkg in "${brew_packages[@]}"; do
        yes |brew install "${pkg}"
    done

    echo "Making sure all Homebrew 'leaf' packages are up to date"
    brewable=("$(comm -12 <(brew leaves) <(brew outdated))")

    for leaf in "${brewable[@]}"; do
        yes |brew upgrade "${leaf}"
    done

}


# installs packages via apt for Linux
function do_install_apt_pkgs_lnx() {
    print_header "Installing Packages"

    apt_packages=(awscli bash-completion curl libcairo2-dev libgdk-pixbuf2.0-0 gist git jq
                  libffi-dev libxml2-dev libxslt-dev libpango1.0-dev pigz pv
                  python-dev python-pip python3-pip shellcheck wget libykpers-1-1 figlet)

    sudo apt-get -qq update
    echo "Installing apt packages"
    for pkg in "${apt_packages[@]}"; do
        sudo apt-get -qq install "${pkg}"
    done

}


# pip install list of modules
function pip_install() {
    module_list="$*"
    # SC-NOTE: We want the array expansion below, so not quoting.
    # Disable 2068 - https://github.com/koalaman/shellcheck/wiki/SC2068
    #shellcheck disable=SC2068
    for module in ${module_list[@]}; do
        sudo pip install --quiet --upgrade "${module}"
    done
}


# pip3 install list of modules
function pip3_install() {
    module_list="$*"
    # SC-NOTE: We want the array expansion below, so not quoting.
    # Disable 2068 - https://github.com/koalaman/shellcheck/wiki/SC2068
    #shellcheck disable=SC2068
    for module in ${module_list[@]}; do
        sudo pip3 install --quiet --upgrade "${module}"
    done
}


# install pip modules to system python
function do_sys_pip_modules() {
    print_header "Installing pip modules"
    pip_modules=(pip requests virtualenv pep8 flake8)

    pip_install "${pip_modules[*]}"
    pip3_modules=(pip pep8 flake8 boto3 passlib python-gnupg)
    pip3_install "${pip3_modules[*]}"
}


# configure python for virtualenv and install pip/pip3 modules
# SC-NOTE: Disable non-constant source check https://github.com/koalaman/shellcheck/wiki/SC1090
# We know what ${HOME} will eval to but shellcheck can't
#shellcheck disable=SC1090
function do_python_setup() {
    print_header "Configuring Python and VirtualEnv"
    echo "Setting up python for an Onboarding virtualenv"
    mkdir -p "${HOME}/.virtualenv/onboarding"
    virtualenv -p python3 "${HOME}/.virtualenv/onboarding"
    source "${HOME}/.virtualenv/onboarding/bin/activate"
    if [[ "${platform}" = "Darwin" ]]; then
        pip_virtenv_modules=(requests jinja2 WeasyPrint passlib code128 slacker)
        pip_install "${pip_virtenv_modules[*]}"
    else
        pip_virtenv_modules=(requests jinja2 WeasyPrint passlib slacker)
        pip_install "${pip_virtenv_modules[*]}"
        pip3_virtenv_modules=(code128)
        pip3_install "${pip3_virtenv_modules[*]}"
    fi
}


# create empty directory for API tokens
function do_setup_api_tokens() {
    mkdir -p "${HOME}/.api_tokens"

}


# create empty directory for AWS creds
function do_setup_aws_creds() {
    mkdir -p "${HOME}/.aws-creds"

}


# basic git config
function do_configure_git() {
    print_header "Configuring git"

    echo "Getting key fingerprint for your ${email_addy} gpg key"
    my_key=($(gpg --list-secret-keys --with-fingerprint --with-colons "${email_addy}" 2>/dev/null |grep -A1 sec:u|grep fpr:|cut -d':' -f10 ))

    if [[ "${#my_key[@]}" -eq 1 ]]; then
        # Found one matching gpg fingerprint - setup user for signed commits
        git config --global user.signingkey "${my_key[0]}"
        git config --global commit.gpgsign true

        echo "Don't forget to add your gpg key fingerprint to your github account"
        echo "my key fingerprint= ${my_key[0]}"

        if [[ "${platform}" == 'Darwin' ]]; then
            echo "gpg --export --armor ${email_addy} |pbcopy"
        else
            echo "gpg --export --armor ${email_addy} | xsel --clipboard --input"
        fi

        # echo "-- TODO Link to docs on git + gpg ----"
        echo ""

    elif [[ "${#my_key[@]}" -gt 1 ]]; then
        # Found multiple keys - warn user and skip signed commits
        echo "Uh Oh - couldn't ID a canonical gpg key for you.  We'll setup git without commit signing for now..."
        echo "Check your gpg keychain and make sure you have a single GPG key associated with your email"
        echo " gpg --list-secret-keys --with-fingerprint --with-colons ${email_addy} 2>/dev/null |grep -A1 sec:u|grep fpr:|cut -d':' -f10"
        echo "To Manually configure git signing use:"
        echo "    git config --global user.signingkey <your-key-fingerprint>"
        echo "    git config --global commit.gpgsign true"
        echo ""
    else
        echo "Error locating GPG key. Proceeding with unsigned commit setup"
        echo ""
        sleep 1
    fi

    git config --global user.name "${full_name}"
    git config --global user.email "${email_addy}"
    git config --global color.ui true
    git config --global core.excludesfile "${HOME}/.gitignore_global"
    git config --global push.default current
    git config --global pull.default current

    # Check to see if p4merge is present and offer to set it up as difftool for git
    if [[ -s "${p4_app_path}" ]]; then
        do_p4_difftool
    else
        echo "p4merge not detected. Skipping difftool setup for git."
    fi

    #Make sure the desired src directory exists if CORP_HOME is declared
    [[ ! -z ${CORP_HOME+x} ]] && mkdir -p "${CORP_HOME}"

    echo "# Ignore Mac OS specific files" >>"${HOME}/.gitignore_global"
    echo ".DS_Store" >>"${HOME}/.gitignore_global"

    echo "Created git global config as follows:"
    git config --global --list
    echo ""

}


# heredoc for OS X installation of p4merge
function do_shim_p4merge() {
    cat <<-EOF
        #!/bin/bash

        ${p4_app_path} \$*

EOF
}


# configure git to use p4merge as its git diff/merge tools
function do_p4_difftool() {
    confirm "Would you like to use p4merge as your git diff and merge tool?"
    result=$?
    if [[ ${result} -eq 0 ]]; then
        git config --global diff.tool p4mergetool
        git config --global difftool.p4mergetool.cmd "${p4_app_path} \$LOCAL \$REMOTE"
        git config --global mergetool.p4mergetool.cmd "${p4_app_path} \$LOCAL \$REMOTE"
        git config --global difftool.prompt false

        git config --global merge.tool p4mergetool
        git config --global mergetool.p4mergetool.cmd "${p4_app_path} \$BASE \$LOCAL \$REMOTE \$MERGED"
        git config --global mergetool.p4mergetool.trustExitCode false
        git config --global mergetool.keepBackup false
    fi
}


# installs p4merge
function do_install_p4merge_osx() {
    print_header "Installing Perforce P4merge"

    p4_ver="r17.3"  # - current as of 2017-10-25 visit http://filehost.perforce.com/perforce/
    p4_download_url="http://filehost.perforce.com/perforce/${p4_ver}/bin.macosx1011x86_64/P4V.dmg"
    p4_download_file="${HOME}/Downloads/P4V.dmg"
    p4_app_source="/Volumes/P4V/p4merge.app"

    if [[ ! -e "${p4_app_dest}" ]]; then
        if [[ ! -e "${p4_download_file}" ]]; then
            echo "Downloading Perforce tools ${p4_ver} dmg"
            curl -S -L "${p4_download_url}" > "${p4_download_file}"
        fi
        echo "Mounting install media"
        hdiutil attach "${p4_download_file}" -quiet

        echo "Installing p4merge in /Applications"
        cp -fR "${p4_app_source}" "${p4_app_dest}"
        xattr -d "${p4_app_dest}"
        sudo chown -R root:wheel "${p4_app_dest}"

        echo "Ejecting /Volumes/P4V"
        hdiutil detach /Volumes/P4V -quiet
        echo ""
    fi

    mkdir -p "${HOME}/bin"
    pushd "${HOME}/bin" >/dev/null 2>&1
        do_shim_p4merge >p4merge
        chmod +x p4merge
        # simple symlink no longer works w/ modern perforce: http://answers.perforce.com/articles/KB/2848
        # ln -s "/Applications/p4merge.app/Contents/Resources/launchp4merge" p4merge
    popd >/dev/null 2>&1


    # Check if user wishes to use p4merge for diffs and configure git
    do_p4_difftool

}


# installs p4merge
function do_install_p4merge_lnx() {
    print_header "Installing Perforce P4merge"

    p4_ver="r17.3"  # - current as of 2017-10-25 visit http://filehost.perforce.com/perforce/
    p4_filename="p4v.tgz"
    p4_download_url="http://filehost.perforce.com/perforce/${p4_ver}/bin.linux26x86_64/${p4_filename}"
    p4_download_file="${HOME}/Downloads/${p4_filename}"

    if [[ ! -e "${p4_app_dest}" ]]; then
        if [[ ! -e "${p4_download_file}" ]]; then
            echo "Downloading Perforce tools ${p4_ver} tgz"
            curl -S -L "${p4_download_url}" > "${p4_download_file}"
        fi
        echo "Extracting p4v.tgz file"
        sudo mkdir -p "${p4_app_dest}"
        sudo tar -zxf "${p4_download_file}" -C "${p4_app_dest}" --strip 1
    fi

    echo "Linking p4merge to ${HOME}/bin"
    mkdir -p "${HOME}/bin"
    sudo ln -fs "${p4_app_path}" "${HOME}/bin"

    # Check if user wishes to use p4merge for diffs and configure git
    do_p4_difftool
}


# install Sublime
function do_sublime_bin_osx() {
    print_header "Installing Sublime Text 3"

    subl_download_url="https://download.sublimetext.com/"
    subl_download_file="Sublime Text Build 3143.dmg"
    app_source="/Volumes/Sublime Text/Sublime Text.app"
    app_dest="/Applications/Sublime Text.app"
    dock_add="<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Sublime Text.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"

    if [[ ! -e "${app_dest}" ]]; then
        if [[ ! -e "${HOME}/Downloads/${subl_download_file}" ]]; then
            echo "Downloading Sublime Text 3"
            curl -S -L "${subl_download_url}/${subl_download_file}" > "${HOME}/Downloads/${subl_download_file}"
        fi
        echo "Mounting install media"
        hdiutil attach "${HOME}/Downloads/${subl_download_file}" -quiet
        cp -fR "${app_source}" "${app_dest}"
        xattr -d "${app_dest}"
        sudo chown -R root:wheel "${app_dest}"
        hdiutil detach "/Volumes/Sublime Text/" -quiet
        echo ""

        echo "Sublime 3 installed.  Don't forget to get a license key."
        sleep 1
        defaults write com.apple.dock persistent-apps -array-add "${dock_add}" && sleep 1 && killall -HUP Dock

    fi

    mkdir -p "${HOME}/bin"
    pushd "${HOME}/bin" >/dev/null 2>&1
        sublime_app="${app_dest}/Contents/SharedSupport/bin/subl"
        if [[ -e "${sublime_app}" ]]; then
            ln -fs "${sublime_app}" subl
        else
            echo "Did not find Sublime 3 - Make sure it is installed as ${app_dest}"
        fi
    popd >/dev/null 2>&1

}


# install Sublime
function do_sublime_bin_lnx() {
    print_header "Installing Sublime Text 3"

    sudo add-apt-repository ppa:webupd8team/sublime-text-3
    sudo apt-get -qq update
    sudo apt-get -qq install sublime-text-installer

    echo
    echo "Sublime 3 installed.  Don't forget to get a license key."
    echo
    sleep 2
}


# install GAM
function do_install_gam() {
    our_gam_version="4.32"
    print_header "Installing GAM ${our_gam_version}"

    gam_src_download="https://github.com/jay0lee/GAM/archive/v${our_gam_version}.tar.gz"
    gam_folder="GAM-${our_gam_version}"
    tar_file="gam-${our_gam_version}.tar.gz"

    mkdir -p "${HOME}/gam/"
    pushd "${HOME}/gam" >/dev/null 2>&1
        echo "Downloading gam-src ${our_gam_version}"
        curl -S -L "${gam_src_download}" > "${tar_file}"
        echo "extracting"
        tar -xzf "${tar_file}"

        if [[ -e "gam.py" ]]; then
            echo "Found existing file gam.py renaming to old_gam.py"
            mv gam.py old_gam.py
        fi

        ln -fs "${gam_folder}/src/gam.py" "gam.py"

    popd >/dev/null 2>&1

    echo "Linking GAM to ${HOME}/bin"
    mkdir -p "${HOME}/bin"
    pushd "${HOME}/bin" >/dev/null 2>&1
        ln -fs "${HOME}/gam/gam.py" gam.py
        ln -fs "${HOME}/gam/gam.py" gam
    popd >/dev/null 2>&1

    echo "Congratulations, gam-src ${our_gam_version} has been installed"
    echo "See the docs at: https://github.com/jay0lee/GAM/wiki#configure-gam"
    echo "for information on setting up and configuring authentication etc"
}


# source and symlink files for ops-tools
function do_source_ops_bash() {
    print_header "Sourcing ops-tools bash"

    ops_bash_path="${CORP_HOME}/ops-tools/bash/grnds-profile.d"

    if [[ -d "${ops_bash_path}" ]]; then
        echo "Sourcing files from ${ops_bash_path} and linking to local .profile.d/"

        mkdir -p "${HOME}/.profile.d"
        pushd "${HOME}/.profile.d" >/dev/null 2>&1
            # SC-NOTE: We want the variable expansion below, so not quoting and disable 2046 - https://github.com/koalaman/shellcheck/wiki/SC2046
            #shellcheck disable=SC2046
            for file in ${ops_bash_path}/*.sh; do
                ln -fs "${file}" $(basename "${file}")
            done
        popd >/dev/null 2>&1
    else
        echo "Warning: Failed to locate ${ops_bash_path}.  Make sure you have ops-tools checked out and up to date."
        echo "If this is the first time through you can safely ignore this warning."
    fi
}


# configure SSH key
function do_config_ssh() {
    print_header "Configuring SSH"

    if [[ ! -e $HOME/.ssh/id_rsa ]]; then
        ssh-keygen -f "$HOME/.ssh/id_rsa" -b4096 -t rsa -C "${email_addy}"
    elif [[ "$(ssh-keygen -lf "$HOME/.ssh/id_rsa" |cut -d' ' -f1 )" == "4096" ]]; then
        echo "Excellent - you have a 4k ssh key created and installed"
    else
        echo "Uh-oh. you have an existing ssh key, but it doesn't appear to be a 4k RSA key."
        echo "Contact an adult for help in resolving this."
    fi
}


# instructions for user
function do_send_cred_setup() {
    echo "visit the engineering blog and follow the steps in this article:"
    echo "http://eng.[DOMAIN]/blog/2015/06/19/securely-transmitting-credentials-from-the-commandline-with-osx-and-gmail/"
    sleep 3
}


# add each option selected by the user to a to-do list
function handle_args() {
    while getopts "hqwertyuiopas" OPTION; do
        case "${OPTION}" in
           h)
               usage
               exit 1
               ;;
           q)
               to_do_list+=('do_bash_profile')                      # opt q
               ;;
           w)
               if [[ "${platform}" = "Darwin" ]]; then              # opt w
                    to_do_list+=('do_install_homebrew_pkgs_osx')
               else
                    to_do_list+=('do_install_apt_pkgs_lnx')
               fi
               ;;
           e)
               to_do_list+=('do_sys_pip_modules')                   # opt e
               ;;
           r)
               to_do_list+=('do_python_setup')                      # opt r
               ;;
           t)
               to_do_list+=('do_setup_api_tokens')                  # opt t
               ;;
           y)
               to_do_list+=('do_setup_aws_creds')                   # opt y
               ;;
           u)
               to_do_list+=('do_configure_git')                     # opt u
               ;;
           i)
               if [[ "${platform}" = "Darwin" ]]; then              # opt i
                    to_do_list+=('do_install_p4merge_osx')
               else
                    to_do_list+=('do_install_p4merge_lnx')
               fi
               ;;
           o)
               if [[ "${platform}" = "Darwin" ]]; then              # opt o
                    to_do_list+=('do_sublime_bin_osx')
               else
                    to_do_list+=('do_sublime_bin_lnx')
               fi
               ;;
           p)
               to_do_list+=('do_install_gam')                       # opt p
               ;;
           a)
               to_do_list+=('do_source_ops_bash')                   # opt a
               ;;
           s)
               to_do_list+=('do_config_ssh')                        # opt s
               ;;
           ?)
               usage
               exit 2
               ;;
        esac
    done
}


# automatically run all functions for full workstation setup
function run_full_setup() {
    do_name_stuff                             # Always need this
    do_bash_profile                           # opt q
    if [[ "${platform}" = "Darwin" ]]; then   # opt w
        do_install_homebrew_pkgs_osx
    else
        do_install_apt_pkgs_lnx
    fi
    do_sys_pip_modules                        # opt e
    do_python_setup                           # opt r
    do_setup_api_tokens                       # opt t
    do_setup_aws_creds                        # opt y
    do_configure_git                          # opt u
    if [[ "${platform}" = "Darwin" ]]; then   # opt i
        do_install_p4merge_osx
    else
        do_install_p4merge_lnx
    fi
    if [[ "${platform}" = "Darwin" ]]; then   # opt o
        do_sublime_bin_osx
    else
        do_sublime_bin_lnx
    fi
    do_install_gam                            # opt p
    do_source_ops_bash                        # opt a
    do_config_ssh                             # opt s
}


# display finish banner when bootstrap is done running
function show_finished() {
    echo
    echo
    figlet "FINISHED" 2>/dev/null || banner "FINISHED"
    echo "Remember to 'source ~/.bash_profile' to load any profile changes into your current session."
    echo
    echo
}


main() {

    check_which_platform
    declare_constants

    if [[ "$#" -gt 0 ]]; then

        # Do some of the things based on user cli flags
        to_do_list=('do_name_stuff')

        handle_args "$@"

        for task in "${to_do_list[@]}"; do
            echo "Starting task: ${task}"
            ${task}
        done

    else
        print_header "Full Workstation Setup"
        run_full_setup
    fi

    show_finished
}

main "$@"
