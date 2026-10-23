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
; Version 0.1 - Adding Film Grain after: http://www.gimpguru.org/Tutorials/FilmGrain/
;


(define (elsamuko-grain aimg adraw holdness value strength grainblur blackwhite)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (bw-layer (car (gimp-layer-copy adraw)))
         (grainlayer (car (gimp-layer-new img
                                          "Grain"
                                          owidth 
                                          oheight
                                          1
                                          100 
                                          LAYER-MODE-OVERLAY-LEGACY)))
         (grainlayermask (car (gimp-layer-create-mask grainlayer ADD-MASK-WHITE)))
         (floatingsel 0)
         )
    
    ; init
    (define (set-pt a index x y)
      (begin
        (vector-set! a (* index 2) (/ x 255.0))
        (vector-set! a (+ (* index 2) 1) (/ y 255.0))
        )
      )
    (define (splineValue)
      (let* ((a (make-vector 6 0.0)))
        (set-pt a 0 0 0)
        (set-pt a 1 128 strength)
        (set-pt a 2 255 0)
        a
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    (gimp-context-set-foreground '(0 0 0))
    (gimp-context-set-background '(255 255 255))
    
    ;optional b/w
    (if(= blackwhite TRUE)
       (begin
         (gimp-image-insert-layer img bw-layer -1 -1)
         (gimp-item-set-name bw-layer "B/W")
         (gimp-drawable-desaturate bw-layer DESATURATE-LIGHTNESS)
         )
       )
    
    ;fill new layer with neutral gray
    (gimp-image-insert-layer img grainlayer -1 -1)
    (gimp-drawable-fill grainlayer FILL-TRANSPARENT)
    (gimp-context-set-foreground '(128 128 128))
    (gimp-selection-all img)
    (gimp-drawable-edit-fill grainlayer FILL-FOREGROUND)
    (gimp-selection-none img)
    
    ;add grain and blur it
    (gimp-drawable-merge-new-filter grainlayer "gegl:noise-hsv" "" LAYER-MODE-REPLACE 1.0 "holdness" holdness "hue-distance" 0 "saturation-distance" 0 "value-distance" (/ value 255.0))
    (if(> grainblur 0)
       (begin
         (gimp-drawable-merge-new-filter grainlayer "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* grainblur 0.32) "std-dev-y" (* grainblur 0.32) "abyss-policy" "clamp")

         )
       )
    (gimp-layer-add-mask grainlayer grainlayermask)
    
    ;select the original image, copy and paste it as a layer mask into the grain layer
    (gimp-selection-all img)
    (gimp-edit-copy (vector adraw))
    (set! floatingsel (vector-ref (car (gimp-edit-paste grainlayermask TRUE)) 0))
    (gimp-floating-sel-anchor floatingsel)
    
    ;set color curves of layer mask, so that only gray areas become grainy
    (gimp-drawable-curves-spline grainlayermask  HISTOGRAM-VALUE  (splineValue))
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-grain"
                    _"_Film Grain"
                    "Simulating Film Grain.
Newest version can be downloaded from http://registry.gimp.org/node/8108"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "13/08/08"
                    "*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-ADJUSTMENT _"Holdness"      '(2 1 8 1 2 0 0)
                    SF-ADJUSTMENT _"Value"         '(100 0 255 1 10 0 0)
                    SF-ADJUSTMENT _"Strength"      '(128 0 255 1 10 0 0)
                    SF-ADJUSTMENT _"Grain Blur"    '(1 0 3 0.1 0.2  1 0)
                    SF-TOGGLE     _"Desaturate Image" FALSE
                    )
(script-fu-menu-register "elsamuko-grain" _"<Image>/Filters/Generic")
