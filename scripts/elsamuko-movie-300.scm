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

(define (elsamuko-movie-300 aimg adraw
                            color1 color2
                            desaturation overlay
                            gamma multiply
                            redtint grain
                            edge extra-dark)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (desat-layer (car (gimp-layer-copy adraw)))
         (multiply-layer (car (gimp-layer-copy adraw)))
         (multiply-layer2 (car (gimp-layer-copy adraw)))
         (multiply-layer2-mask (car (gimp-layer-create-mask multiply-layer2 ADD-MASK-WHITE)))
         (edge-layer (car (gimp-layer-copy adraw)))
         (red-layer  0)
         (overlay-layer1 (car (gimp-layer-copy adraw)))         
         (overlay-layer2 (car (gimp-layer-copy adraw)))         
         (yellow-layer (car (gimp-layer-new img
                                            "Yellow Multiply"
                                            owidth 
                                            oheight
                                            RGBA-IMAGE
                                            10 
                                            LAYER-MODE-MULTIPLY-LEGACY)))
         (sepia-layer (car (gimp-layer-new img
                                           "Sepia"
                                           owidth 
                                           oheight
                                           RGBA-IMAGE
                                           50 
                                           LAYER-MODE-GRAIN-MERGE-LEGACY)))
         (grain-layer (car (gimp-layer-new img
                                           "Grain"
                                           owidth 
                                           oheight
                                           1
                                           100 
                                           LAYER-MODE-OVERLAY-LEGACY)))
         (grain-layer-mask (car (gimp-layer-create-mask grain-layer ADD-MASK-WHITE)))
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
        (set-pt a 1 128 grain)
        (set-pt a 2 255 0)
        a
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    ;some more red
    (gimp-image-insert-layer img edge-layer -1 0)
    (gimp-item-set-name edge-layer "Edge Amp")
    (gimp-drawable-color-balance edge-layer TRANSFER-MIDTONES TRUE 20 0 0)
    (gimp-drawable-color-balance edge-layer TRANSFER-HIGHLIGHTS TRUE 20 0 0)
    
    (gimp-layer-set-mode edge-layer LAYER-MODE-GRAIN-EXTRACT-LEGACY)
    (gimp-edit-copy-visible img)
    (set! red-layer (car (gimp-layer-new-from-visible img img "Red")))
    (gimp-image-insert-layer img red-layer -1 0)
    (gimp-layer-set-mode red-layer LAYER-MODE-GRAIN-MERGE-LEGACY)
    (gimp-layer-set-opacity red-layer redtint)
    (gimp-drawable-invert red-layer FALSE)
    (gimp-item-set-visible edge-layer FALSE)
    
    ;set desaturated and multiply layer
    (gimp-image-insert-layer img desat-layer -1 -1)
    (gimp-item-set-name desat-layer "Desaturated")
    (gimp-layer-set-mode desat-layer LAYER-MODE-NORMAL)
    (gimp-layer-set-opacity desat-layer 100)
    (gimp-drawable-hue-saturation desat-layer HUE-RANGE-ALL 0 0 desaturation 0)
    
    (gimp-image-insert-layer img multiply-layer -1 -1)
    (gimp-item-set-name multiply-layer "Multiply 1")
    (gimp-layer-set-mode multiply-layer LAYER-MODE-MULTIPLY-LEGACY)
    (gimp-layer-set-opacity multiply-layer multiply)
    (gimp-drawable-hue-saturation multiply-layer HUE-RANGE-ALL 0 0 desaturation 0)
    
    (if(= extra-dark TRUE)
       (begin
         (gimp-image-insert-layer img multiply-layer2 -1 -1)
         (gimp-item-set-name multiply-layer2 "Multiply 2")
         (gimp-layer-set-mode multiply-layer2 LAYER-MODE-MULTIPLY-LEGACY)
         (gimp-layer-set-opacity multiply-layer2 100)
         (gimp-drawable-desaturate multiply-layer2 DESATURATE-LUMA)
         (gimp-layer-add-mask multiply-layer2 multiply-layer2-mask)
         
         (gimp-selection-all img)
         (gimp-edit-copy (vector multiply-layer2))
         (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste multiply-layer2-mask TRUE)) 0))
         )
       )
    
    ;set overlay layers
    (gimp-image-insert-layer img overlay-layer1 -1 -1)
    (gimp-item-set-name overlay-layer1 "Overlay 1")
    (gimp-layer-set-mode overlay-layer1 LAYER-MODE-OVERLAY-LEGACY)
    (gimp-layer-set-opacity overlay-layer1 overlay)
    (gimp-drawable-desaturate overlay-layer1 DESATURATE-LUMA)
    (gimp-drawable-merge-new-filter overlay-layer1 "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" (/ 70 255.0) "high-input" (/ 150 255.0) "gamma" gamma)
    
    (gimp-image-insert-layer img overlay-layer2 -1 -1)
    (gimp-item-set-name overlay-layer2 "Overlay 2")
    (gimp-layer-set-mode overlay-layer2 LAYER-MODE-OVERLAY-LEGACY)
    (gimp-layer-set-opacity overlay-layer2 overlay)
    (gimp-drawable-desaturate overlay-layer2 DESATURATE-LUMA)
    (gimp-drawable-merge-new-filter overlay-layer2 "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" (/ 70 255.0) "high-input" (/ 150 255.0) "gamma" gamma)
    
    ;set yellow multiply layer
    (gimp-image-insert-layer img yellow-layer -1 -1)
    (gimp-selection-all img)
    (gimp-context-set-foreground color2)
    (gimp-drawable-edit-fill yellow-layer FILL-FOREGROUND)
    
    ;set sepia grain merge layer
    (gimp-image-insert-layer img sepia-layer -1 -1)
    (gimp-selection-all img)
    (gimp-context-set-foreground color1)
    (gimp-drawable-edit-fill sepia-layer FILL-FOREGROUND)
    
    ;move red tint layer to top
    (gimp-image-raise-item-to-top img red-layer)
    
    ;add grain
    (if(> grain 0)
       (begin
         ;fill new layer with neutral gray
         (gimp-image-insert-layer img grain-layer -1 -1)
         (gimp-drawable-fill grain-layer FILL-TRANSPARENT)
         (gimp-context-set-foreground '(128 128 128))
         (gimp-selection-all img)
         (gimp-drawable-edit-fill grain-layer FILL-FOREGROUND)
         (gimp-selection-none img)
         
         ;add grain and blur it
         (gimp-drawable-merge-new-filter grain-layer "gegl:noise-hsv" "" LAYER-MODE-REPLACE 1.0 "holdness" 2 "hue-distance" 0 "saturation-distance" 0 "value-distance" (/ 100 255.0))
         (gimp-drawable-merge-new-filter grain-layer "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* 0.5 0.32) "std-dev-y" (* 0.5 0.32) "abyss-policy" "clamp")
         (gimp-layer-add-mask grain-layer grain-layer-mask)
         
         ;select the original image, copy and paste it as a layer mask into the grain layer
         (gimp-selection-all img)
         (gimp-edit-copy (vector adraw))
         (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste grain-layer-mask TRUE)) 0))
         
         ;set color curves of layer mask, so that only gray areas become grainy
         (gimp-drawable-curves-spline grain-layer-mask  HISTOGRAM-VALUE  (splineValue))
         )
       )
    
    
    ;edge detection
    (if(= edge TRUE)
       (begin
         (gimp-image-raise-item-to-top img edge-layer)
         (gimp-item-set-visible edge-layer TRUE)
         (gimp-drawable-merge-new-filter edge-layer "gegl:edge-sobel" "" LAYER-MODE-REPLACE 1.0 "horizontal" TRUE "vertical" TRUE "keep-sign" TRUE)

         (gimp-drawable-levels-stretch edge-layer)
         (gimp-drawable-desaturate edge-layer DESATURATE-LUMA)
         (gimp-drawable-invert edge-layer FALSE)
         (gimp-layer-set-mode edge-layer LAYER-MODE-MULTIPLY-LEGACY)
         (gimp-layer-set-opacity edge-layer 50)
         )
       )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-movie-300"
                    "_Movie 300"
                    "Color effect from the movie 300."
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "04/03/10"
                    "RGB*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-COLOR       "Grain Merge"           '(160 141 105)
                    SF-COLOR       "Multiply"              '(241 229  31)
                    SF-ADJUSTMENT  "Desaturation"          '(-60 -100 0  1 10 0 0)
                    SF-ADJUSTMENT  "Overlay Opacity"       '( 60   0 100 1 10 0 0)
                    SF-ADJUSTMENT  "Overlay Gamma"         '(  2  1 3 0.1 0.2 1 0)
                    SF-ADJUSTMENT  "Multiply Opacity"      '( 50   0 100 1 10 0 0)
                    SF-ADJUSTMENT  "Red Tint Opacity"      '( 80   0 100 1 10 0 0)
                    SF-ADJUSTMENT  "Grain Strength"        '(128   0 255 1 10 0 0)
                    SF-TOGGLE      "Edge Amplification"     TRUE
                    SF-TOGGLE      "Extra Darkening"        FALSE
                    )

(script-fu-menu-register "elsamuko-movie-300" _"<Image>/Filters/Artistic")
