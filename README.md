<div>
  <h1 align="center">Cinema</h1>
  <h3 align="center"><img src="data/icons/64/com.github.artemanufrij.playmyvideos.svg"/><br>A video player for watching local video files</h3>
  <p align="center">Designed for <a href="https://elementary.io"> elementary OS</p>
</div>

### Donate
<a href="https://www.paypal.me/ArtemAnufrij">PayPal</a> | <a href="https://liberapay.com/Artem/donate">LiberaPay</a> | <a href="https://www.patreon.com/ArtemAnufrij">Patreon</a>

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.artemanufrij.playmyvideos">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</p>
<p align="center">
  <img src="screenshots/Screenshot.png"/>
  <br/>
  <img src="screenshots/Screenshot_Player.png"/>
</p>

## Install from Github.

As first you need elementary SDK
```
sudo apt install elementary-sdk
```
Install dependencies
```
sudo apt install libsqlite3-dev libsoup2.4-dev libgstreamer-plugins-base1.0-dev libclutter-gtk-1.0-dev libclutter-gst-3.0-dev
```
Clone repository and change directory
```
git clone https://github.com/artemanufrij/playmyvideos.git
cd playmyvideos
```

Create **build** folder and compile application
```
meson build --prefix=/usr
cd build
ninja
```

Install and start Play My Videos on your system
```
sudo make ninja
com.github.artemanufrij.playmyvideos
```
