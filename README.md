# camerawatch
File observer for reolink camera ftp uploads with fhem integration

The observer recognizes new files with inotify and starts an separate process for sizable changes during upload. With this method, the server is able to handle multiple uploads from different cameras at the same time.

Reolink cameras are uploading pictures and videos in "packages".
Upload is finished or finally interrupted if there is no sizeable change for a given time.

The mp4 observer creates after 10 sec a short 1FPS gif animation.

## FHEM
Integration needs a dummy named like this:
defmod Kamera_Upload dummy


Debug output:
```
Picture or Video-Upload
| Upload duration / sec
| |  Filename
| |  |
V 12 K3TA_00_20220307125142.mp4 0: 12717752 34972542 11127395b/s
P 3 K3TA_00_20220307125217.jpg 0: 1012224 1287411 91729b/s bitrate=  43.1kbits/s speed=0.631x
V 14 K3TA_00_20220307125142.mp4 0: 34972542 36563013 795235b/srate=  42.0kbits/s speed=0.636x
P 6 K3TA_00_20220307125217.jpg 0: 1287411 1287411 0b/s9.85 bitrate=   0.0kbits/s speed=0.446x
V 16 K3TA_00_20220307125142.mp4 0: 36563013 38152557 794772b/strate=  41.1kbits/s speed=0.632x
V 18 K3TA_00_20220307125142.mp4 0: 38152557 39742135 794789b/srate=   0.0kbits/s speed=0.441x
P 9 K3TA_00_20220307125217.jpg 1: 1287411 1287411 0b/s1.90 bitrate=   0.0kbits/s speed=0.471x
V 20 K3TA_00_20220307125142.mp4 0: 39742135 41332655 795260b/srate=   0.0kbits/s speed=0.463x
P 12 K3TA_00_20220307125217.jpg 2: 1287411 1287411 0b/s.88 bitrate=   0.0kbits/s speed=0.486x
V 22 K3TA_00_20220307125142.mp4 0: 41332655 42923191 795268b/strate=  37.5kbits/s speed=0.643x
V 24 K3TA_00_20220307125142.mp4 0: 42923191 44512642 794725b/strate=  36.2kbits/s speed=0.65x
```
