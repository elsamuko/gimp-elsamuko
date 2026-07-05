; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
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
;
;
; Copyright (C) 2008 Michael Maier info[at]mmip.net
;
; Ported to the GIMP 3.0 PDB API in 2026 by Claude Opus (Anthropic).
;
; Version 0.1 - Simulating a vintage photo based on this tutorial:
;               http://crazymurdock1.deviantart.com/art/Vintage-look-in-Gimp-61841683
; Version 0.2 - Optional sharpness and contrast layer
;               by elsamuko (http://sites.google.com/site/elsamuko/gimp)
;
;

(define (mm1-vintage-look img
                          drw
                          VarCyan
                          VarMagenta
                          VarYellow
                          Overlay
                          )
  
  (let* ((drawable-width (car (gimp-drawable-get-width drw)))
         (drawable-height (car (gimp-drawable-get-height drw)))
         (cyan-layer 0)
         (magenta-layer 0)
         (yellow-layer 0)
         (overlay-layer (car (gimp-layer-copy drw)))
         )
    
    ;Begin
    (if (= (car (gimp-drawable-is-gray drw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    
    ;Bleach Bypass
    (if(= Overlay TRUE)
       (begin
         (gimp-image-insert-layer img overlay-layer 0 -1)
         (gimp-drawable-desaturate overlay-layer DESATURATE-LUMA)
         (gimp-drawable-merge-new-filter overlay-layer "gegl:gaussian-blur" "Gaussian Blur" LAYER-MODE-REPLACE 1.0
                                         "std-dev-x" (/ 1 3.0) "std-dev-y" (/ 1 3.0))
         (gimp-drawable-merge-new-filter overlay-layer "gegl:unsharp-mask" "Unsharp Mask" LAYER-MODE-REPLACE 1.0
                                         "std-dev" (/ 1 3.0) "scale" 1.0)
         (gimp-layer-set-mode overlay-layer LAYER-MODE-OVERLAY-LEGACY)
         (gimp-item-set-name overlay-layer "Bleach Bypass")
         )
       )
    
    ;Yellow Layer
    (set! yellow-layer (car (gimp-layer-new img "Yellow" drawable-width drawable-height RGB-IMAGE 100  LAYER-MODE-MULTIPLY-LEGACY)))
    (gimp-image-insert-layer img yellow-layer 0 -1)
    (gimp-context-set-background '(251 242 163) )
    (gimp-drawable-fill yellow-layer FILL-BACKGROUND)
    (gimp-layer-set-opacity yellow-layer VarYellow)
    
    ;Magenta Layer
    (set! magenta-layer (car (gimp-layer-new img "Magenta" drawable-width drawable-height RGB-IMAGE 100  LAYER-MODE-SCREEN-LEGACY)))
    (gimp-image-insert-layer img magenta-layer 0 -1)
    (gimp-context-set-background '(232 101 179) )
    (gimp-drawable-fill magenta-layer FILL-BACKGROUND)
    (gimp-layer-set-opacity magenta-layer VarMagenta)
    
    ;Cyan Layer 
    (set! cyan-layer (car (gimp-layer-new img "Cyan" drawable-width drawable-height RGB-IMAGE 100  LAYER-MODE-SCREEN-LEGACY)))
    (gimp-image-insert-layer img cyan-layer 0 -1)
    (gimp-context-set-background '(9 73 233) )
    (gimp-drawable-fill cyan-layer FILL-BACKGROUND)
    (gimp-layer-set-opacity cyan-layer VarCyan)
    
    ;End
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "mm1-vintage-look"
                    _"_Vintage Look"
                    "Simulation of a 70s vintage look.
Last version can be found at:
http://registry.gimp.org/node/1348"
                    "Michael Maier info[at]mmip.net >" 
                    "(c) Michael Maier. This is GPL Free Software." 	
                    "March 3, 2008" 
                    "*"
                    SF-IMAGE      "Image"    0
                    SF-DRAWABLE   "Drawable" 0
                    SF-ADJUSTMENT _"Cyan"    '(17 0 100 1 1 0 0)
                    SF-ADJUSTMENT _"Magenta" '(20 0 100 1 1 0 0)
                    SF-ADJUSTMENT _"Yellow"  '(59 0 100 1 1 0 0)
                    SF-TOGGLE     _"Bleach Bypass" TRUE
                    )

(script-fu-menu-register "mm1-vintage-look" _"<Image>/Filters/Artistic")
