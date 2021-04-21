# gimp-elsamuko

## Scripts

Put the *.scm files in the GIMP scripts folder (~/.config/GIMP/2.10/scripts/) and refresh scripts (<Image>/Filters/Script-Fu/Refresh Scripts) or restart GIMP.

You can view an overview of the scripts here:  
https://elsamuko.github.io/gimp-elsamuko/scripts.html

You will find the scripts then at these places in the GIMP image menu:

* elsamuko-antique-border.scm :/Filters/Decor
* elsamuko-che-guevara.scm :/Filters/Artistic
* elsamuko-color-tint.scm :/Colors
* elsamuko-cyanotype.scm :/Filters/Artistic
* elsamuko-difference-layers.scm :/Layer
* elsamuko-erosion-sharpen.scm :/Filters/Enhance
* elsamuko-error-level-analysis.scm :/Image
* elsamuko-escape-lines.scm :/Filters/Render
* elsamuko-glass-displacement.scm :/Filters/Distorts
* elsamuko-grain.scm :/Filters/Generic
* elsamuko-lomo.scm :/Filters/Light and Shadow
* elsamuko-movie-300.scm :/Filters/Artistic
* elsamuko-national-geographic.scm :/Filters/Generic
* elsamuko-obama-hope.scm :/Filters/Artistic
* elsamuko-photo-border.scm :/Filters/Generic
* elsamuko-photochrom.scm :/Filters/Artistic
* elsamuko-rainy-landscape.scm :/Filters/Light and Shadow
* elsamuko-slide-with-sprockets.scm :/Filters/Decor
* elsamuko-sunny-landscape.scm :/Filters/Light and Shadow
* elsamuko-technicolor-2-color.scm :/Colors
* elsamuko-technicolor-3-color.scm :/Colors
* elsamuko-wb-puzzle.scm :/Filters/Light and Shadow
* mm1-vintage-look.scm :/Filters/Artistic
* tuxcomputers-split-tone.scm :/Script-Fu/Color

(This list was generated with)

```bash
    for SCM in *.scm; do echo -n "* $SCM :"; tail -n1 "$SCM" | grep -Po '(?<=\<Image\>)[^"]*'; done
```

## Plugins
Some of my plugins in an incomplete state with qmake project files and source:

* elsamuko-depthmap-cv
* elsamuko-get-curves
* elsamuko-saturation

Happy GIMPing!

elsamuko
