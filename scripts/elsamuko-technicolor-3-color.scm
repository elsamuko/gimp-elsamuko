; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
; http://www.gnu.org/licenses/gpl-3.0.html
;
; Copyright (C) 2008 elsamuko <elsamuko@web.de>
;
; Version 0.1 - Simulating the 3 color technicolor technique
; 
;

(define (elsamuko-technicolor-3-color aimg adraw
                                      redpart   ;redintensity
                                      greenpart ;greenintensity
                                      bluepart  ;blueintensity
                                      cyanfill magentafill yellowfill
                                      sharpen
                                      stretch
                                      retro
                                      extra)
  (let* ((img          (car (gimp-drawable-get-image adraw)))
         (owidth       (car (gimp-image-width img)))
         (oheight      (car (gimp-image-height img)))
         (sharpenlayer (car (gimp-layer-copy adraw FALSE)))
         (floatingsel  0)
         
         (redlayer     (car (gimp-layer-copy adraw FALSE)))
         (greenlayer   (car (gimp-layer-copy adraw FALSE)))
         (bluelayer    (car (gimp-layer-copy adraw FALSE)))
         (tmplayer     (car (gimp-layer-copy adraw FALSE)))
         (extralayer  0)
         (purplelayer  (car (gimp-layer-new img
                                            owidth 
                                            oheight
                                            1
                                            "Retro Layer" 
                                            100 
                                            SUBTRACT-MODE)))
         
         ;         (redmultiplylayer   (car (gimp-layer-new img
         ;                                                  owidth 
         ;                                                  oheight
         ;                                                  1
         ;                                                  "Red Multiply" 
         ;                                                  redintensity
         ;                                                  MULTIPLY-MODE)))
         ;         (greenmultiplylayer (car (gimp-layer-new img
         ;                                                  owidth 
         ;                                                  oheight
         ;                                                  1
         ;                                                  "Green Multiply" 
         ;                                                  greenintensity
         ;                                                  MULTIPLY-MODE)))
         ;         (bluemultiplylayer  (car (gimp-layer-new img
         ;                                                  owidth 
         ;                                                  oheight
         ;                                                  1
         ;                                                  "Blue Multiply" 
         ;                                                  blueintensity
         ;                                                  MULTIPLY-MODE)))
         
         ;decomposing filter colors, you may change these
         (red-R   redpart)
         (red-G   (/ (- 1 redpart)   2) )
         (red-B   (/ (- 1 redpart)   2) )
         
         (green-R (/ (- 1 greenpart) 2) )
         (green-G greenpart)
         (green-B (/ (- 1 greenpart) 2) )
         
         (blue-R  (/ (- 1 bluepart)  2) )
         (blue-G  (/ (- 1 bluepart)  2) )
         (blue-B  bluepart)
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    (gimp-context-set-foreground '(0 0 0))
    (gimp-context-set-background '(255 255 255))
    
    ;extra color layer
    (if(= extra 1)
       (begin
         (gimp-image-add-layer img tmplayer 0)
         (gimp-desaturate-full tmplayer DESATURATE-LIGHTNESS)
         (gimp-layer-set-mode tmplayer GRAIN-EXTRACT-MODE)
         (gimp-edit-copy-visible img)
         (set! extralayer (car (gimp-layer-new-from-visible img img "Extra Color") ))
         (gimp-image-add-layer img extralayer 0)
         (gimp-drawable-set-visible extralayer FALSE)
         (gimp-drawable-set-visible tmplayer FALSE)
         )
       )
    
    ;hide original layer
    (gimp-drawable-set-visible adraw FALSE)
    
    ;RGB filter
    (gimp-drawable-set-name bluelayer  "Blue -> Yellow")
    (gimp-drawable-set-name greenlayer "Green -> Magenta")
    (gimp-drawable-set-name redlayer   "Red -> Cyan")
    
    
    (gimp-image-add-layer img greenlayer -1)
    ;(gimp-image-add-layer img greenmultiplylayer -1)
    ;(gimp-drawable-fill greenmultiplylayer TRANSPARENT-FILL)
    
    (gimp-image-add-layer img bluelayer  -1)
    ;(gimp-image-add-layer img bluemultiplylayer  -1)
    ;(gimp-drawable-fill bluemultiplylayer  TRANSPARENT-FILL)
    
    (gimp-image-add-layer img redlayer   -1)
    ;(gimp-image-add-layer img redmultiplylayer   -1)
    ;(gimp-drawable-fill redmultiplylayer   TRANSPARENT-FILL)
    
    
    (plug-in-colors-channel-mixer 1 img redlayer TRUE
                                  red-R red-G red-B ;R
                                  0 0 0 ;G
                                  0 0 0 ;B
                                  )
    (plug-in-colors-channel-mixer 1 img greenlayer TRUE
                                  green-R green-G green-B ;R
                                  0 0 0 ;G
                                  0 0 0 ;B
                                  )
    (plug-in-colors-channel-mixer 1 img bluelayer TRUE
                                  blue-R blue-G blue-B ;R
                                  0 0 0 ;G
                                  0 0 0 ;B
                                  )
    
    ;stretch contrast of filter layers
    (if(= stretch TRUE)
       (begin
         (gimp-selection-all img)
         (gimp-levels-stretch redlayer)
         (gimp-levels-stretch greenlayer)
         (gimp-levels-stretch bluelayer)
         )
       )
    
    ;colorize filter layers back
    (gimp-selection-all img)
    
    (gimp-context-set-foreground cyanfill)
    (gimp-edit-bucket-fill redlayer   FG-BUCKET-FILL SCREEN-MODE 100 0 FALSE 0 0)
    
    (gimp-context-set-foreground magentafill)
    (gimp-edit-bucket-fill greenlayer FG-BUCKET-FILL SCREEN-MODE 100 0 FALSE 0 0)
    
    (gimp-context-set-foreground yellowfill)
    (gimp-edit-bucket-fill bluelayer  FG-BUCKET-FILL SCREEN-MODE 100 0 FALSE 0 0)
    
    (gimp-layer-set-mode redlayer   MULTIPLY-MODE)
    (gimp-layer-set-mode greenlayer MULTIPLY-MODE)
    (gimp-layer-set-mode bluelayer  MULTIPLY-MODE)
    
    
    ;    ;add multiply layers
    ;    (gimp-selection-all img)
    ;    
    ;    (gimp-edit-copy redlayer)
    ;    (set! floatingsel (car (gimp-edit-paste redmultiplylayer TRUE)))
    ;    (gimp-floating-sel-anchor floatingsel)
    ;    
    ;    (gimp-edit-copy greenlayer)
    ;    (set! floatingsel (car (gimp-edit-paste greenmultiplylayer TRUE)))
    ;    (gimp-floating-sel-anchor floatingsel)
    ;    
    ;    (gimp-edit-copy bluelayer)
    ;    (set! floatingsel (car (gimp-edit-paste bluemultiplylayer TRUE)))
    ;    (gimp-floating-sel-anchor floatingsel)
    
    ;sharpness + contrast layer
    (if(> sharpen 0)
       (begin
         (gimp-image-add-layer img sharpenlayer 0)
         (gimp-desaturate-full sharpenlayer DESATURATE-LIGHTNESS)
         (plug-in-unsharp-mask 1 img sharpenlayer 5 1 0)
         (gimp-layer-set-mode sharpenlayer OVERLAY-MODE)
         (gimp-layer-set-opacity sharpenlayer sharpen)
         ;(set! floatingsel (car (gimp-layer-create-mask sharpenlayer 5)))
         ;(gimp-layer-add-mask sharpenlayer floatingsel)
         ;(gimp-invert floatingsel)
         )
       )
    
    ;set extra color layer on top
    (if(= extra 1)
       (begin
         (gimp-image-raise-layer-to-top img extralayer)
         (gimp-layer-set-mode extralayer GRAIN-MERGE-MODE)
         (gimp-drawable-set-visible extralayer TRUE)
         )
       )
    
    ;add 'retro' layer
    (if(= retro TRUE)
       (begin
         (gimp-image-add-layer img purplelayer -1)
         (gimp-drawable-fill purplelayer TRANSPARENT-FILL)
         (gimp-context-set-foreground '(62 25 55))
         (gimp-selection-all img)
         (gimp-edit-bucket-fill purplelayer FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
         (gimp-selection-none img)
         (gimp-layer-set-opacity purplelayer 80)
         (gimp-layer-set-opacity redlayer 80)
         (gimp-layer-set-opacity bluelayer 80)
         (gimp-image-raise-layer-to-top img purplelayer)
         )
       )
    
    ; tidy up
    (gimp-selection-none img)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-technicolor-3-color"
                    _"_Technicolor 3 Color"
                    "Simulating Technicolor Film.
                     Newest version can be downloaded from http://registry.gimp.org"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "13/09/08"
                    "*"
                    SF-IMAGE       "Input image"      0
                    SF-DRAWABLE    "Input drawable"   0
                    SF-ADJUSTMENT _"Red Part of Red Filter"     '(1.2 0 2 0.1 0.2 1 0)
                    ;SF-ADJUSTMENT _"Red Multiply Opacity"     '(0 0 100 1 5 1 0)
                    
                    SF-ADJUSTMENT _"Green Part of Green Filter" '(1.2 0 2 0.1 0.2 1 0)
                    ;SF-ADJUSTMENT _"Green Multiply Opacity"   '(0 0 100 1 5 1 0)
                    
                    SF-ADJUSTMENT _"Blue Part of Blue Filter"   '(1.2 0 2 0.1 0.2 1 0)
                    ;SF-ADJUSTMENT _"Blue Multiply Opacity"    '(0 0 100 1 5 1 0)
                    
                    SF-COLOR      _"Recomposing Cyan"     '(0   255 255)
                    SF-COLOR      _"Recomposing Magenta"  '(255   0 255)
                    SF-COLOR      _"Recomposing Yellow"   '(255 255   0)
                    
                    SF-ADJUSTMENT _"Sharpen Opacity"      '(60 0 100 1 5 1 0)
                    SF-TOGGLE     _"Stretch Filters"       FALSE
                    SF-TOGGLE     _"Retro Colors"          TRUE
                    SF-TOGGLE     _"Extra Intensity"       TRUE
                    )

(script-fu-menu-register "elsamuko-technicolor-3-color" _"<Image>/Colors")
