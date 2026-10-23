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
; Copyright (C) 2009 elsamuko <elsamuko@web.de>
;
; Version 0.1 - first version
; Version 0.2 - added smoothness and contrast option
; version 0.3 - added lines smoothness and edge detection option


(define (elsamuko-che-guevara aimg adraw
                              ssmooth sthreshhold
                              lsmooth lthreshhold
                              contrast edge color)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (colorlayer (car (gimp-layer-new img
                                          "Color" 
                                          owidth 
                                          oheight
                                          1
                                          100 
                                          LAYER-MODE-NORMAL)))
         (shadowlayer 0)
         (lineslayer 0)
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    (gimp-context-set-foreground color)
    (gimp-context-set-background '(255 255 255))
    
    ;set smoothness
    (if (> ssmooth 0)
        (gimp-drawable-merge-new-filter adraw "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* ssmooth 0.32) "std-dev-y" (* ssmooth 0.32) "abyss-policy" "clamp")
        )
    
    ;add color layer
    (gimp-image-insert-layer img colorlayer -1 -1)
    (gimp-drawable-fill colorlayer FILL-TRANSPARENT)
    (gimp-selection-all img)
    (gimp-drawable-edit-fill colorlayer FILL-FOREGROUND)
    (gimp-selection-none img)
    
    ;copy and add original image two times
    (set! shadowlayer (car (gimp-layer-copy adraw)))
    (set! lineslayer (car (gimp-layer-copy adraw)))
    (gimp-image-insert-layer img shadowlayer -1 -1)
    (gimp-image-insert-layer img lineslayer -1 -1)
    (gimp-item-set-name shadowlayer "Shadow")
    (gimp-item-set-name lineslayer "Lines")
    
    ;threshhold on shadow layer
    (gimp-drawable-threshold shadowlayer HISTOGRAM-VALUE (/ sthreshhold 255.0) 1.0)
    (gimp-layer-set-mode shadowlayer LAYER-MODE-MULTIPLY-LEGACY)
    
    ;high contrast, edge detection and threshhold on lines layer
    (if (> contrast 0)
        (gimp-drawable-merge-new-filter lineslayer "gegl:unsharp-mask" "" LAYER-MODE-REPLACE 1.0 "std-dev" 60 "scale" contrast "threshold" 0)
        )
    
    ;edge detection
    (if (= edge 0) (gimp-drawable-merge-new-filter lineslayer "gegl:edge-neon" "" LAYER-MODE-REPLACE 1.0 "radius" 5 "amount" 0))
    (if (= edge 1) (gimp-drawable-merge-new-filter lineslayer "gegl:edge-sobel" "" LAYER-MODE-REPLACE 1.0 "horizontal" TRUE "vertical" TRUE "keep-sign" TRUE))

    (gimp-drawable-invert lineslayer FALSE)
    (gimp-drawable-levels-stretch lineslayer)
    
    (if (> lsmooth 0)
        (begin
          (gimp-drawable-merge-new-filter lineslayer "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* lsmooth 0.32) "std-dev-y" (* lsmooth 0.32) "abyss-policy" "clamp")

          )
        )
    (gimp-drawable-threshold lineslayer HISTOGRAM-VALUE (/ lthreshhold 255.0) 1.0)
    (gimp-layer-set-mode lineslayer LAYER-MODE-MULTIPLY-LEGACY)
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-che-guevara"
                    _"_Che Guevara"
                    "Shadow Style Portrait.
Latest version can be downloaded from http://registry.gimp.org"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "19/02/2009"
                    "*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-ADJUSTMENT _"Shadow Smoothness"  '(3 0 10 0.2 1 1 0)
                    SF-ADJUSTMENT _"Shadow Threshhold"  '(128 0 255 1 10 0 0)
                    SF-ADJUSTMENT _"Lines Smoothness"   '(5 0 10 0.2 1 1 0)
                    SF-ADJUSTMENT _"Lines Threshhold"   '(180 0 255 1 10 0 0)
                    SF-ADJUSTMENT _"Lines Contrast"     '(0 0 10 0.1 1 1 0)
                    SF-OPTION     _"Edge Detection"     '("Neon"
                                                          "Sobel")
                    SF-COLOR      _"Background Color"   '(255 0 0)
                    )

(script-fu-menu-register "elsamuko-che-guevara" _"<Image>/Filters/Artistic")
