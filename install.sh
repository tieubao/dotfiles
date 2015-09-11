# npm list -g --depth=0 	> npm-g-list.txt

##############################################################################################################
### homebrew!
# (if your maching has /usr/local locked down (like google's), you can do this to place everything in ~/.homebrew
mkdir $HOME/.homebrew && curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C $HOME/.homebrew
export PATH=$HOME/.homebrew/bin:$HOME/.homebrew/sbin:$PATH
brew tap Homebrew/bundle
brew bundle
### end of homebrew
##############################################################################################################

cp -rf "./rc/*" "~/"
vim +PluginInstall +qall

# http://railsapps.github.io/xcode-command-line-tools.html
##############################################################################################################
### XCode Command Line Tools
#      thx  https://github.com/alrra/dotfiles/blob/c2da74cc333/os/os_x/install_applications.sh#L39

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
###
##############################################################################################################

###
##############################################################################################################
gem install cocoapods
gem install tmuxinator

# gem query --local
# cocoapods (0.39.0)
# fastlane (1.49.0)
# rvm (1.11.3.9)
# synx (0.1.1)
# tmuxinator (0.7.1)


# setting up the sublime symlink
# ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl
cp -rf "sublime/*" "~/Library/Application Support/Sublime Text 3/"

###

touch ~/.cdg_paths
cp rc/cdscuts_list_echo /usr/local/bin/cdscuts_list_echo
cp rc/cdscuts_glob_echo /usr/local/bin/cdscuts_glob_echo

# Setup todo.sh
touch /usr/local/bin/hey.txt

cp rc/v /usr/local/bin
pip install rainbowstream

##############

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
