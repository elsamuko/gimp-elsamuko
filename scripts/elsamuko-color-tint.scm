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


(define (elsamuko-color-tint aimg adraw color opacity saturation blackwhite)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (tint-layer 0)
         (tint-layer-mask 0)
         
         (imgTMP 0)
         (copy-layer 0) ;first layer of imgTMP
         (tmp-layer 0)  ;tint layer of imgTMP
         (tmp-layer-mask 0)
         
         (imgHSV 0)
         (layersHSV 0)
         (layerS 0)
         
         (red   (/ (car   color) 255))
         (blue  (/ (cadr  color) 255))
         (green (/ (caddr color) 255))
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    ;filter ops on new image
    (gimp-edit-copy-visible img)
    (set! imgTMP (car (gimp-edit-paste-as-new-image)))
    
    ;rise saturation
    (set! copy-layer (vector-ref (car (gimp-image-get-selected-layers imgTMP)) 0))
    (gimp-drawable-hue-saturation copy-layer HUE-RANGE-ALL 0 0 saturation 0)
    
    ;add tint layer and filter color
    (set! tmp-layer (car (gimp-layer-copy copy-layer)))
    (gimp-item-set-name tmp-layer "Temp")
    (gimp-image-insert-layer imgTMP tmp-layer -1 -1)
    (gimp-drawable-merge-new-filter tmp-layer "gegl:mono-mixer" "" LAYER-MODE-REPLACE 1.0
                                    "red" red "green" blue "blue" green ;R
                                    )
    
    ;add filter mask
    (set! tmp-layer-mask (car (gimp-layer-create-mask tmp-layer ADD-MASK-COPY)))
    (gimp-layer-add-mask tmp-layer tmp-layer-mask)
    
    ;colorize tint layer
    (gimp-context-set-foreground color)
    (gimp-selection-all imgTMP)
    (gimp-drawable-edit-fill tmp-layer FILL-FOREGROUND)
    
    ;get visible and add to original
    (gimp-item-set-visible copy-layer FALSE)
    (gimp-edit-copy-visible imgTMP)
    (set! tint-layer (car (gimp-layer-new-from-visible imgTMP img "Tint") ))
    (gimp-image-insert-layer img tint-layer -1 0)
    
    ;set modes
    (gimp-layer-set-mode tint-layer LAYER-MODE-SCREEN-LEGACY)
    (gimp-layer-set-opacity tint-layer opacity)
    
    ;get saturation layer
    (set! imgHSV (car (plug-in-decompose RUN-NONINTERACTIVE imgTMP (vector copy-layer) "hsv" TRUE FALSE)))
    (set! layersHSV (gimp-image-get-layers imgHSV))
    (set! layerS (vector-ref (car layersHSV) 1))

    (gimp-edit-copy (vector layerS))
    
    ;add saturation mask
    (set! tint-layer-mask (car (gimp-layer-create-mask tint-layer ADD-MASK-WHITE )))
    (gimp-layer-add-mask tint-layer tint-layer-mask)
    (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste tint-layer-mask TRUE)) 0))
    
    ;desaturate original
    (if (= blackwhite TRUE) 
        ( begin 
           (gimp-drawable-desaturate adraw DESATURATE-LUMA)
           )
        )
    
    ; tidy up
    (gimp-image-delete imgTMP)
    (gimp-image-delete imgHSV)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-color-tint"
                    _"_Color Tint"
                    "Add color tint layer.
Latest version can be downloaded from http://registry.gimp.org/"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "16/04/10"
                    "*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-COLOR       "Color"              '(0   0  255)
                    SF-ADJUSTMENT _"Opacity"            '(100 0 100 5 10 0 0)
                    SF-ADJUSTMENT _"Saturation"         '(100 0 100 5 10 0 0)
                    SF-TOGGLE     _"Desaturate Image"    FALSE
                    )

(script-fu-menu-register "elsamuko-color-tint" _"<Image>/Colors")
