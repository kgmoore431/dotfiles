HOMEDIR=~/

# Load .bashrc if it exists
test -f ${HOME}/.bashrc && source ${HOME}/.bashrc


# Load everything from profile.d folder
for file in ${HOME}/.profile.d/*.sh; do
  source ${file};
done

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

#Make sure ~/bin is in the path
[[ ! "$PATH" =~ "${HOME}/bin" ]] && export PATH="${HOME}/bin:${PATH}"

#Determine where a shell function is defined / declared
function find_function {
  shopt -s extdebug
  declare -F "$1"
  shopt -u extdebug
}

