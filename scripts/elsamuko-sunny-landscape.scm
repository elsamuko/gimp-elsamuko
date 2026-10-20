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
; Copyright (C) 2010 elsamuko <elsamuko@web.de>
;

(define (elsamuko-sunny-landscape aimg adraw
                                  brightnessIn
                                  ylight glight
                                  desat
                                  sharpen
                                  sunshine sky
                                  num1 num2
                                  wb)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         
         (working-layer (car (gimp-layer-copy adraw)))
         (extract-layer (car (gimp-layer-copy adraw)))
         (wb-layer 0)
         (desat-layer 0)
         (tmplayer1 0)         
         (tmplayer2 0)         
         (color-layer 0)
         (brightness (- 60 brightnessIn))
         (extra 0) ;(not yet used)
         (offset1 (* oheight (/ num1 100)))
         (offset2 (* oheight (/ num2 100)))
         
         (overlay-layer (car (gimp-layer-new img
                                             "Yellow Cast"
                                             owidth 
                                             oheight
                                             1
                                             60 
                                             LAYER-MODE-OVERLAY-LEGACY)))
         (overlay-layer-mask (car (gimp-layer-create-mask overlay-layer ADD-MASK-WHITE)))
         
         
         (sub-blue-layer (car (gimp-layer-new img
                                              "Sub Blue"
                                              owidth 
                                              oheight
                                              1
                                              100 
                                              LAYER-MODE-NORMAL)))
         (sub-blue-layer-mask (car (gimp-layer-create-mask sub-blue-layer ADD-MASK-WHITE)))
         
         (top-blue-layer (car (gimp-layer-new img
                                              "Top Blue"
                                              owidth 
                                              oheight
                                              1
                                              65 
                                              LAYER-MODE-NORMAL)))
         (top-blue-layer-mask (car (gimp-layer-create-mask top-blue-layer ADD-MASK-WHITE)))
         
         (cloud-layer (car (gimp-layer-new img
                                           "Clouds"
                                           owidth 
                                           oheight
                                           1
                                           60 
                                           LAYER-MODE-SCREEN-LEGACY)))
         (cloud-layer-mask (car (gimp-layer-create-mask cloud-layer ADD-MASK-WHITE)))
         )
    
    ; init
    (define (set-pt a index x y)
      (begin
        (vector-set! a (* index 2) (/ x 255.0))
        (vector-set! a (+ (* index 2) 1) (/ y 255.0))
        )
      )
    (define (spline-brightness)
      (let* ((a (make-vector 8 0.0)))
        (set-pt a 0 0 0)
        (set-pt a 1 brightness 33)
        (set-pt a 2 127 199)
        (set-pt a 3 255 255)
        a
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    ;extra color layer (not yet used)
    (if(= extra 1)
       (begin
         (gimp-image-insert-layer img extract-layer -1 0)
         (gimp-drawable-desaturate extract-layer DESATURATE-LIGHTNESS)
         (gimp-layer-set-mode extract-layer LAYER-MODE-GRAIN-EXTRACT-LEGACY)
         (gimp-edit-copy-visible img)
         (set! color-layer (car (gimp-layer-new-from-visible img img "Color") ))
         (gimp-image-insert-layer img color-layer -1 0)
         (gimp-layer-set-mode color-layer LAYER-MODE-GRAIN-MERGE-LEGACY)
         (gimp-item-set-visible color-layer FALSE)
         (gimp-image-remove-layer img extract-layer)
         )
       )
    
    ;sharpen + adjust contrast
    (gimp-image-insert-layer img working-layer -1 -1)
    (if(> sharpen 0) (gimp-drawable-merge-new-filter working-layer "gegl:unsharp-mask" "" LAYER-MODE-REPLACE 1.0 "std-dev" 1 "scale" sharpen "threshold" (/ 5 255.0)))
    (gimp-item-set-name working-layer "Process Copy")
    (gimp-drawable-curves-spline working-layer HISTOGRAM-VALUE (spline-brightness))
    
    ;hues
    (if(> ylight 0) (gimp-drawable-hue-saturation working-layer HUE-RANGE-YELLOW 0 ylight 0 0))
    (if(> glight 0) (gimp-drawable-hue-saturation working-layer HUE-RANGE-GREEN 0 glight 0 0))
    
    ;desaturate a bit
    (set! desat-layer (car (gimp-layer-copy working-layer)))
    (gimp-image-insert-layer img desat-layer -1 -1)
    (gimp-item-set-name desat-layer "Desaturate")
    (gimp-drawable-desaturate desat-layer DESATURATE-LIGHTNESS)
    (gimp-layer-set-opacity desat-layer desat)
    
    ;add some sunshine
    (gimp-image-insert-layer img overlay-layer -1 -1)
    (gimp-context-set-foreground sunshine)
    (gimp-selection-all img)
    (gimp-drawable-edit-fill overlay-layer FILL-FOREGROUND)
    (gimp-edit-copy (vector working-layer))
    (gimp-layer-add-mask overlay-layer overlay-layer-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste overlay-layer-mask TRUE)) 0))
    (gimp-drawable-invert overlay-layer-mask FALSE)
    (gimp-drawable-levels-stretch overlay-layer-mask)
    (gimp-selection-none img)
    
    ;add 1st artificial sky
    (gimp-image-insert-layer img sub-blue-layer -1 -1)
    (gimp-selection-all aimg)
    (gimp-context-set-foreground sky)
    (begin (gimp-context-set-gradient-fg-transparent) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse TRUE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill sub-blue-layer GRADIENT-LINEAR 0 FALSE 1 0 TRUE 0 offset2 0 offset1))
    (gimp-edit-copy (vector working-layer))
    (gimp-layer-add-mask sub-blue-layer sub-blue-layer-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste sub-blue-layer-mask TRUE)) 0))
    (gimp-drawable-levels-stretch sub-blue-layer-mask)
    (gimp-selection-none img)
    
    ;add clouds
    (gimp-image-insert-layer img cloud-layer -1 -1)
    (gimp-edit-copy (vector working-layer))
    (gimp-layer-add-mask cloud-layer cloud-layer-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste cloud-layer-mask TRUE)) 0))
    (gimp-drawable-levels-stretch cloud-layer-mask)
    (gimp-selection-none img)
    (gimp-drawable-merge-new-filter cloud-layer "gegl:noise-solid" "" LAYER-MODE-REPLACE 1.0 "tileable" FALSE "turbulent" FALSE "seed" (random 100) "detail" 4 "x-size" 3.5 "y-size" 7.0 "width" owidth "height" oheight)
    (gimp-context-set-foreground sky)
    (gimp-selection-all img)
    (gimp-context-set-paint-mode LAYER-MODE-OVERLAY-LEGACY)
    (gimp-drawable-edit-fill cloud-layer FILL-FOREGROUND)
    (gimp-selection-none img)
    
    (gimp-context-set-foreground '(255 255 255))
    (gimp-context-set-background '(0 0 0))
    (begin (gimp-context-set-gradient-fg-bg-rgb) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-MULTIPLY-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse FALSE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill cloud-layer GRADIENT-LINEAR 0 FALSE 1 0 TRUE 0 offset1 0 offset2))

    
    ;add 2nd artificial sky
    (gimp-image-insert-layer img top-blue-layer -1 -1)
    (gimp-edit-copy (vector sub-blue-layer))
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste top-blue-layer TRUE)) 0))
    (gimp-layer-add-mask top-blue-layer top-blue-layer-mask)
    (gimp-edit-copy (vector sub-blue-layer-mask))
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste top-blue-layer-mask TRUE)) 0))
    
    ;more color (not yet used)
    (if(= extra 1)
       (begin
         (gimp-image-raise-item-to-top img color-layer)
         (gimp-item-set-visible color-layer TRUE)
         )
       )
    
    ;white balance result
    (if(= wb 1)
       (begin
         (gimp-edit-copy-visible img)
         (set! tmplayer1 (car (gimp-layer-new-from-visible img img "Temp 1")))
         (set! tmplayer2 (car (gimp-layer-new-from-visible img img "Temp 2")))
         (gimp-image-insert-layer img tmplayer1 -1 -1)
         (gimp-image-insert-layer img tmplayer2 -1 -1)
         (gimp-drawable-levels-stretch tmplayer1)
         (gimp-layer-set-mode tmplayer2 LAYER-MODE-GRAIN-EXTRACT-LEGACY)
         (gimp-edit-copy-visible img)
         (set! wb-layer (car (gimp-layer-new-from-visible img img "White Balance")))
         (gimp-image-insert-layer img wb-layer -1 -1)
         (gimp-layer-set-mode wb-layer LAYER-MODE-GRAIN-MERGE-LEGACY)
         (gimp-image-remove-layer img tmplayer1)
         (gimp-image-remove-layer img tmplayer2)
         (gimp-layer-set-opacity wb-layer 60)
         )
       )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-sunny-landscape"
                    "_Sunny Landscape"
                    "Artificial sunshine effect."
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "30/03/10"
                    "RGB*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-ADJUSTMENT  "Brightness"           '(10 0 30 1 5 0 0)
                    SF-ADJUSTMENT  "Yellow Lightness"     '(5 0 30 1 5 0 0)
                    SF-ADJUSTMENT  "Green Lightness"      '(5 0 30 1 5 0 0)
                    SF-ADJUSTMENT  "Desaturate"           '(30 0 100 5 10 0 0)
                    SF-ADJUSTMENT  "Sharpen"              '(0.5 0 1 0.1 0.2 1 0)
                    SF-COLOR       "Sunshine Color"       '(255 255 0)
                    SF-COLOR      _"Sky Color"            '(85 125 204)
                    SF-ADJUSTMENT  "Sky Gradient Begin"   '(20 -100 200 1 10 0 0)
                    SF-ADJUSTMENT  "Sky Gradient End"     '(60 -100 200 1 10 0 0)
                    SF-TOGGLE     _"White Balance Result"  TRUE
                    ;SF-COLOR      _"Cloud Color"          '(0 0 255)
                    ;SF-ADJUSTMENT _"Yellow Hues"          '(20 0 50 1 5 0 0)                    
                    ;SF-ADJUSTMENT _"Red Hues"             '(30 0 50 1 5 0 0)                    
                    )

(script-fu-menu-register "elsamuko-sunny-landscape" _"<Image>/Filters/Light and Shadow")
