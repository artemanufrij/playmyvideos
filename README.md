<div>
  <h1 align="center">Play My Videos</h1>
  <h3 align="center">A video player for watching local music files</h3>
</div>

<br/>

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.artemanufrij.playmyvideos">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</p>

<br/>

![screenshot](Screenshot.png)
![screenshot](Screenshot_Player.png)

## Install from Github.

As first you need elementary SDK
```
sudo apt install elementary-sdk
```
Install dependencies
```
sudo apt install cmake
sudo apt install cmake-elementary
sudo apt install debhelper
sudo apt install libgranite-dev
sudo apt install libsqlite3-dev
sudo apt install libgstreamer-plugins-base1.0-dev
sudo apt install libclutter-gtk-1.0-dev
sudo apt install libclutter-gst-3.0-dev
sudo apt install valac
```
Clone repository and change directory
```
git clone https://github.com/artemanufrij/playmyvideos.git
cd playmyvideos
```

Create **build** folder and compile application
```
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
```

Install and start Play My Videos on your system
```
sudo make install
com.github.artemanufrij.playmyvideos
```
