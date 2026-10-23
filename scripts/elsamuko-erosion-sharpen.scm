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
; Copyright (C) 2011 elsamuko <elsamuko@web.de>
;


(define (elsamuko-erosion-sharpen img draw op gauss_blur)
  (let*
      ((owidth (car (gimp-image-get-width img)))
       (oheight (car (gimp-image-get-height img)))
       (blurred-layer (car (gimp-layer-copy draw)))
       (erode-layer (car (gimp-layer-copy draw)))
       (dilate-layer (car (gimp-layer-copy draw)))
       (erode-layermask (car (gimp-layer-create-mask erode-layer ADD-MASK-WHITE)))
       (dilate-layermask (car (gimp-layer-create-mask dilate-layer ADD-MASK-WHITE)))
       (additive-layer 0)
       (subtractive-layer 0)
       )
    
    ;init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    
    ; add and blur copy
    (gimp-image-insert-layer img blurred-layer -1 -1)
    (gimp-item-set-name blurred-layer "Blurred")
    (gimp-drawable-merge-new-filter blurred-layer "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* gauss_blur 0.32) "std-dev-y" (* gauss_blur 0.32) "abyss-policy" "clamp")
    
    ; subtract first from second
    (gimp-layer-set-mode blurred-layer LAYER-MODE-SUBTRACT-LEGACY)
    (gimp-edit-copy-visible img)
    (set! subtractive-layer (car (gimp-layer-new-from-visible img img "Subtractive") ))
    (gimp-image-insert-layer img subtractive-layer -1 0)
    (gimp-item-set-visible subtractive-layer FALSE)
    
    ; subtract second from first
    (gimp-image-lower-item img blurred-layer)
    (gimp-layer-set-mode blurred-layer LAYER-MODE-NORMAL)
    (gimp-layer-set-mode draw LAYER-MODE-SUBTRACT-LEGACY)
    (gimp-edit-copy-visible img)
    (set! additive-layer (car (gimp-layer-new-from-visible img img "Additive") ))
    (gimp-image-insert-layer img additive-layer -1 0)
    
    ; set modes back to normal
    (gimp-item-set-visible subtractive-layer TRUE)
    (gimp-layer-set-mode draw LAYER-MODE-NORMAL)
    
    ; add and erode copy
    (gimp-image-insert-layer img erode-layer -1 -1)
    (gimp-item-set-name erode-layer "Erode")
    (gimp-drawable-merge-new-filter erode-layer "gegl:value-propagate" "" LAYER-MODE-REPLACE 1.0 "mode" "black" "lower-threshold" 0 "upper-threshold" 1.0 "rate" 0.7 "top" TRUE "left" TRUE "right" TRUE "bottom" TRUE "value" TRUE "alpha" FALSE)
    
    ; add and dilate copy
    (gimp-image-insert-layer img dilate-layer -1 -1)
    (gimp-item-set-name dilate-layer "Dilate")
    (gimp-drawable-merge-new-filter dilate-layer "gegl:value-propagate" "" LAYER-MODE-REPLACE 1.0 "mode" "white" "lower-threshold" 0 "upper-threshold" 1.0 "rate" 0.7 "top" TRUE "left" TRUE "right" TRUE "bottom" TRUE "value" TRUE "alpha" FALSE)
    
    ; add layer masks
    (gimp-layer-add-mask erode-layer erode-layermask)
    (gimp-selection-all img)
    (gimp-edit-copy (vector additive-layer))
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste erode-layermask TRUE)) 0))
    
    (gimp-layer-add-mask dilate-layer dilate-layermask)
    (gimp-selection-all img)
    (gimp-edit-copy (vector subtractive-layer))
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste dilate-layermask TRUE)) 0))
    
    ; adjust levels
    (gimp-drawable-merge-new-filter erode-layermask "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" 0 "high-input" (/ 30 255.0) "gamma" 2)
    (gimp-drawable-merge-new-filter dilate-layermask "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" 0 "high-input" (/ 30 255.0) "gamma" 2)
    
    ; anti aliasing of layer masks
    (gimp-drawable-merge-new-filter erode-layermask "gegl:antialias" "" LAYER-MODE-REPLACE 1.0)
    (gimp-drawable-merge-new-filter dilate-layermask "gegl:antialias" "" LAYER-MODE-REPLACE 1.0)

    
    ; adjust levels 2nd
    (gimp-drawable-merge-new-filter erode-layermask "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" 0 "high-input" (/ 128 255.0) "gamma" 2)
    (gimp-drawable-merge-new-filter dilate-layermask "gimp:levels" "" LAYER-MODE-REPLACE 1.0 "trc" TRC-NON-LINEAR "low-input" 0 "high-input" (/ 128 255.0) "gamma" 2)
    
    ; anti aliasing of layer masks 2nd
    (gimp-drawable-merge-new-filter erode-layermask "gegl:antialias" "" LAYER-MODE-REPLACE 1.0)
    (gimp-drawable-merge-new-filter dilate-layermask "gegl:antialias" "" LAYER-MODE-REPLACE 1.0)

    
    ; remove unnecessary layers
    (gimp-image-remove-layer img subtractive-layer)
    (gimp-image-remove-layer img additive-layer)
    (gimp-image-remove-layer img blurred-layer)
    
    ; set opacities
    (gimp-layer-set-opacity erode-layer op)
    (gimp-layer-set-opacity dilate-layer op)
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-erosion-sharpen"
                    _"_Erosion Sharpen"
                    "Sharpens the image with erosion and dilation"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "10/10/11"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    SF-ADJUSTMENT _"Strength"             '(60 0 100 1 20 0 0)
                    SF-ADJUSTMENT _"Radius"               '(2 1 20 1 5 0 0)
                    )

(script-fu-menu-register "elsamuko-erosion-sharpen" _"<Image>/Filters/Enhance")
