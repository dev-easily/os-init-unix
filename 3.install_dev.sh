#!/bin/bash
# db
brew install mysql@8.0
brew install redis@6.2

# tools
brew install apifox
brew install figma

# xcode
mkdir -p ~/dev
cat > ~/dev/open_terminal.sh <<EOF
#!/bin/bash
open -a Terminal \$(pwd)
EOF
chmod +x ~/dev/open_terminal.sh