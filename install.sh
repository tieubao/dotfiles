#!/usr/bin/env bash

# Configure OSX
./osx.sh

### homebrew!
# (if your maching has /usr/local locked down (like google's), you can do this to place everything in ~/.homebrew
mkdir $HOME/.homebrew && curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C $HOME/.homebrew
export PATH=$HOME/.homebrew/bin:$HOME/.homebrew/sbin:$PATH
brew tap Homebrew/bundle
brew bundle

### XCode Command Line Tools
# http://railsapps.github.io/xcode-command-line-tools.html
# thx https://github.com/alrra/dotfiles/blob/c2da74cc333/os/os_x/install_applications.sh#L39
if [ $(xcode-select -p &> /dev/null; printf $?) -ne 0 ]; then
    xcode-select --install &> /dev/null
    # Wait until the XCode Command Line Tools are installed
    while [ $(xcode-select -p &> /dev/null; printf $?) -ne 0 ]; do
        sleep 5
    done
	xcode-select -p &> /dev/null
	if [ $? -eq 0 ]; then
        # Prompt user to agree to the terms of the Xcode license
        # https://github.com/alrra/dotfiles/issues/10
       sudo xcodebuild -license
   fi
fi

# Node packages
# npm list -g --depth=0 > npm-g-list.txt
npm install -g tern brunch eslint webpack how2

# Ruby gems
# gem query --local
gem install cocoapods
gem install tmuxinator
gem install fastlane
gem install synx

# Setup docker-machine
sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
docker-machine create dev --driver xhyve --xhyve-experimental-nfs-share

# Setup emacs
git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

# Setup todo.sh
touch /usr/local/bin/hey.txt

touch ~/.cdg_paths
cp rc/cdscuts_list_echo /usr/local/bin/cdscuts_list_echo
cp rc/cdscuts_glob_echo /usr/local/bin/cdscuts_glob_echo

cp rc/v /usr/local/bin
pip install rainbowstream

# FZF
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Copy dotfiles to $HOME
cp -rf "./rc/*" "~/"
