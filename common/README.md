# Compiling the ARM BBR Common Library

### How to make and install STATIC library

    cd ev3dev-arm-bbr/common/
    make
    sudo make install

### How to make and install SHARED library

    cd ev3dev-arm-bbr/common/
    make shared
    sudo make shared-install

### How to use SHARED library

    cd ev3dev-arm-bbr/source/armskel
    gcc armskel.S -lev3dev-c -lev3dev-arm-bbr -o armskel

    ./armskel
