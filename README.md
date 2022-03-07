# camerawatch
File observer for reolink camera ftp uploads with fhem integration

The observer recognizes new files with inotify and starts an separate process for sizable changes during upload. With this method, the server is able to handle multiple uploads from different cameras at the same time.

Reolink cameras are uploading pictures and videos in "packages".
Upload is finished or finally interrupted if there is no sizeable change for a given time.

Debug output:
```
echo "P $ctime $file $j: $oldsize $actsize ${speed}b/s"

Picture or Video-Upload
| Upload duration / sec
| |  Filename
| |  |                             Old-Size
| |  |                             |        New-Size
| |  |                             |        |        Speed
| |  |                             |        |        |
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

## ffmpeg
The mp4 observer creates after 10 sec a short 1FPS gif animation.

## FHEM
Integration needs a dummy named like this:
```
defmod Kamera_Upload dummy
```

 	
```
Kamera_Upload:.*Video_Datei.* {
    my $index = rindex($EVTPART1, '/') + 1;
    my $width = rindex($EVTPART1, '.') - $index;
    my $filename = substr($EVTPART1, $index, $width);

    my ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime(gettimeofday());
    my $dmyhms = sprintf("%02d.%02d.%04d %02d:%02d:%02d", $mday, $month+1, 1900+$year, $hour, $min, $sec);

    ## GetFullVideoFile
    fhem("set myTelegramBot _msg @#[TELEGRAM_GROUP_NAME] #Videodatei $dmyhms \nDatei:\n\/GFVF_$filename");
}
```

```
Kamera_Upload {
my $eventidx = index($EVENT, ":");
my $eventname = substr($EVENT, 0, $eventidx);

my @y = grep {$_} split /(\_+)/, $EVENT;
my $camname = $y[0];
my $cam_str = substr $y[0], 1, 2;
my $cam_num = sprintf("%d", $cam_str);

  if ( $eventname eq "${camname}_Bild_Name" ) {
      my $filename = ReadingsVal($NAME,"last","-");
      my $path = AttrVal($NAME,"storage","-");
      my $msgChatId = "[TELEGRAM_GROUP_NAME]";

      fhem("set myTelegramBot _msg @#[TELEGRAM_GROUP_NAME] #${camname}_Alarm $EVTPART1");
      if ($msgChatId ne "") {
          fhem("setreading Kamera${cam_num}_Small_Telegram msgChatId $msgChatId");
      }
      fhem("get Kamera${cam_num}_Small_Telegram image");
  }
}
```
