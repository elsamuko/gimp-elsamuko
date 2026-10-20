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

(define (elsamuko-rainy-landscape aimg adraw
                                  cast preserve
                                  yellow-hues red-hues)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         
         (hue-layer     (car (gimp-layer-copy adraw)))
         (bw-layer      (car (gimp-layer-copy adraw)))
         (extract-layer (car (gimp-layer-copy adraw)))
         
         (cast-layer (car (gimp-layer-new img
                                          "Blue Cast"
                                          owidth 
                                          oheight
                                          1
                                          40 
                                          LAYER-MODE-MULTIPLY-LEGACY)))
         (cast-layer-mask (car (gimp-layer-create-mask cast-layer ADD-MASK-WHITE)))
         (preserve-layer 0)
         (preserve-layer-mask 0)
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )

    ;add hue layer
    (gimp-image-insert-layer img hue-layer -1 -1)
    (gimp-item-set-name hue-layer "Hue: Y->G, R->Y")
    
    ;create layer mask for the cast layer
    (gimp-image-insert-layer img bw-layer -1 -1)
    (gimp-item-set-name bw-layer "B/W Filter")
    (gimp-drawable-merge-new-filter bw-layer "gegl:mono-mixer" "" LAYER-MODE-REPLACE 1.0
                                    "red" -0.466 "green" 0.133 "blue" 1.333  ;R
                                    )
    (gimp-drawable-invert bw-layer FALSE)
    (gimp-item-set-visible bw-layer FALSE)
    
    ;preserve yellow
    (gimp-image-insert-layer img extract-layer -1 -1)
    (gimp-item-set-name extract-layer "Extract")
    (gimp-layer-set-mode extract-layer LAYER-MODE-GRAIN-EXTRACT-LEGACY)
    (gimp-layer-add-alpha extract-layer)
    (gimp-drawable-merge-new-filter extract-layer "gegl:color-to-alpha" "" LAYER-MODE-REPLACE 1.0 "color" preserve)
    (gimp-edit-copy-visible img)
    (set! preserve-layer (car (gimp-layer-new-from-visible img img "Preserve Y")))
    (gimp-image-insert-layer img preserve-layer -1 0)
    ;brightness -90, contrast 90 as perceptual levels (GIMP 3 brightness-contrast works in linear light)
    (gimp-drawable-merge-new-filter preserve-layer "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" 0.594 "high-input" 0.955)


    
    (set! preserve-layer-mask (car (gimp-layer-create-mask preserve-layer ADD-MASK-COPY)))
    (gimp-layer-add-mask preserve-layer preserve-layer-mask)
    (gimp-item-set-visible extract-layer FALSE)
    
    ;add cast layer
    (gimp-image-insert-layer img cast-layer -1 -1)
    (gimp-image-raise-item-to-top img preserve-layer)
    (gimp-context-set-foreground cast)
    (gimp-selection-all img)
    (gimp-drawable-edit-fill cast-layer FILL-FOREGROUND)
    
    (gimp-edit-copy (vector bw-layer))
    (gimp-layer-add-mask cast-layer cast-layer-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste cast-layer-mask TRUE)) 0))
    (gimp-selection-none img)
    
    ;colorize hue layer
    (gimp-drawable-hue-saturation hue-layer HUE-RANGE-YELLOW yellow-hues 0 0 0)
    (gimp-drawable-hue-saturation hue-layer HUE-RANGE-RED red-hues 0 0 0)

    ;remove unneccessary layers
    (gimp-image-remove-layer img extract-layer)
    (gimp-image-remove-layer img bw-layer)
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-rainy-landscape"
                    "_Rainy Landscape"
                    "After rain effect."
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "12/03/10"
                    "RGB*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-COLOR       "Blue Cast"            '( 0   0  255)
                    SF-COLOR      _"Preserve Color"       '(255 255  0 )
                    SF-ADJUSTMENT _"Yellow Hues"          '(20 0 50 1 5 0 0)                    
                    SF-ADJUSTMENT _"Red Hues"             '(30 0 50 1 5 0 0)                    
                    )

(script-fu-menu-register "elsamuko-rainy-landscape" _"<Image>/Filters/Light and Shadow")
