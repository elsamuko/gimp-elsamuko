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


(define (elsamuko-cyanotype aimg adraw
                            color1 color2
                            localcontrast 
                            overlay
                            blackwhite)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (tmplayer1 0)         
         (tmplayer2 0)         
         (contrastlayer 0)
         (bw-layer 0)
         (overlay-layer (car (gimp-layer-copy adraw)))
         (blue-layer (car (gimp-layer-new img
                                          "Prussian Blue"
                                          owidth 
                                          oheight
                                          RGBA-IMAGE
                                          100 
                                          LAYER-MODE-NORMAL)))
         (blue-mask (car (gimp-layer-create-mask blue-layer ADD-MASK-WHITE)))
         (white-layer (car (gimp-layer-new img
                                           "Aged White"
                                           owidth 
                                           oheight
                                           RGBA-IMAGE
                                           100 
                                           LAYER-MODE-NORMAL)))
         (white-mask (car (gimp-layer-create-mask white-layer ADD-MASK-WHITE)))
         (blue-overlay-layer (car (gimp-layer-new img
                                                  "Blue Overlay"
                                                  owidth 
                                                  oheight
                                                  RGBA-IMAGE
                                                  80 
                                                  LAYER-MODE-OVERLAY-LEGACY)))
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    ;desaturate original
    (if(= blackwhite TRUE)
       (begin
         (gimp-edit-copy-visible img)
         (set! bw-layer (car (gimp-layer-new-from-visible img img "B/W")))
         (gimp-image-insert-layer img bw-layer -1 -1)
         (gimp-drawable-desaturate bw-layer DESATURATE-LIGHTNESS)
         )
       )
    
    ;enhance local contrast
    (if(> localcontrast 0)
       (begin
         (gimp-edit-copy-visible img)
         (set! tmplayer1 (car (gimp-layer-new-from-visible img img "Temp 1")))
         (set! tmplayer2 (car (gimp-layer-new-from-visible img img "Temp 2")))
         (gimp-image-insert-layer img tmplayer1 -1 -1)
         (gimp-image-insert-layer img tmplayer2 -1 -1)
         (gimp-drawable-merge-new-filter tmplayer1 "gegl:unsharp-mask" "" LAYER-MODE-REPLACE 1.0 "std-dev" 60 "scale" localcontrast "threshold" 0)

         (gimp-layer-set-mode tmplayer2 LAYER-MODE-GRAIN-EXTRACT-LEGACY)
         (gimp-edit-copy-visible img)
         (set! contrastlayer (car (gimp-layer-new-from-visible img img "Local Contrast")))
         (gimp-image-insert-layer img contrastlayer -1 -1)
         (gimp-layer-set-mode contrastlayer LAYER-MODE-GRAIN-MERGE-LEGACY)
         (gimp-image-remove-layer img tmplayer1)
         (gimp-image-remove-layer img tmplayer2)
         )
       )
    
    ;set blue and white layers
    (gimp-image-insert-layer img blue-layer -1 -1)
    (gimp-image-insert-layer img white-layer -1 -1)
    (gimp-selection-all aimg)
    (gimp-context-set-foreground color1)
    (gimp-drawable-edit-fill blue-layer FILL-FOREGROUND)
    (gimp-context-set-foreground color2)
    (gimp-drawable-edit-fill white-layer FILL-FOREGROUND)
    
    ;add layer masks
    (gimp-edit-copy (vector adraw))
    (gimp-layer-add-mask blue-layer blue-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste blue-mask TRUE)) 0))
    (gimp-drawable-invert blue-mask FALSE)
    (gimp-layer-add-mask white-layer white-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste white-mask TRUE)) 0))
    
    ;set overlay layer
    (if(> overlay 0)
       (begin
         (gimp-image-insert-layer img overlay-layer -1 -1)
         (gimp-item-set-name overlay-layer "Overlay")
         (gimp-layer-set-mode overlay-layer LAYER-MODE-OVERLAY-LEGACY)
         (gimp-layer-set-opacity overlay-layer overlay)
         (gimp-drawable-desaturate overlay-layer DESATURATE-LIGHTNESS)
         )
       )
    
    ;set blue overlay layer
    (gimp-image-insert-layer img blue-overlay-layer -1 -1)
    (gimp-selection-all aimg)
    (gimp-context-set-foreground color1)
    (gimp-drawable-edit-fill blue-overlay-layer FILL-FOREGROUND)
    (gimp-selection-none img)
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-cyanotype"
                    "_Cyanotype"
                    "Cyanotype effect from 1842."
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "14/03/10"
                    "RGB*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-COLOR      _"Prussian Blue"       '( 61  87 136)
                    SF-COLOR      _"Aged White"          '(251 253 240)
                    SF-ADJUSTMENT _"Local Contrast"      '(0.4 0   2 0.1 0.2 1 0)
                    SF-ADJUSTMENT _"B/W Overlay"         '(50  0  100  1   5 0 0)                    
                    SF-TOGGLE     _"Desaturate Image"     TRUE
                    )

(script-fu-menu-register "elsamuko-cyanotype" _"<Image>/Filters/Artistic")
