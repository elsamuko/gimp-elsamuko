# Technicolor 2 Color Script

This script simulates the [2 Color Technicolor](http://en.wikipedia.org/wiki/Technicolor#Two-color_Technicolor) effect.

Copy it into the [scripts folder](https://docs.gimp.org/2.10/en/install-script-fu.html) from GIMP, you will find it then under **Colors → Technicolor 2 Color**.
Examples here and here:

<img src="technicolor-2.jpg" width="450">

Updates:
* I added two decomposing options.
* Batch version from John O'Daly.
Run it with:  
 `gimp -i -b '(elsamuko-technicolor-2-color-batch "picture.jpg" 0.97 FALSE 1 0.5 0 255 255 255 0 0 255 255 0 TRUE)' -b '(gimp-quit 0)'`  
or for more than one picture  
 `gimp -i -b '(elsamuko-technicolor-2-color-batch "*.jpg" 0.97 FALSE 1 0.5 0 255 255 255 0 0 255 255 0 TRUE)' -b '(gimp-quit 0)'`

See also the Technicolor 3 Color Script.
