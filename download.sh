sudo apt-get install aria2

cd softwares

aria2c -x 16 https://github.com/zsh-users/zsh-autosuggestions/archive/refs/heads/master.zip -o zsh-autosuggestions-master.zip
aria2c -x 16 https://github.com/zsh-users/zsh-syntax-highlighting/archive/refs/heads/master.zip -o zsh-syntax-highlighting-master.zip
aria2c -x 16 https://github.com/ohmyzsh/ohmyzsh/archive/refs/heads/master.zip -o ohmyzsh-master.zip
aria2c -x 16 https://root.cern/download/root_v6.28.12.Linux-ubuntu22-x86_64-gcc11.4.tar.gz
aria2c -x 16 http://cp3.irmp.ucl.ac.be/downloads/Delphes-3.5.0.tar.gz
aria2c -x 16 https://launchpad.net/mg5amcnlo/3.0/3.4.x/+download/MG5_aMC_v3.4.2.tar.gz

cd ..