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
  (let* ((img (car (gimp-drawable-get-image adraw)))
         (owidth (car (gimp-image-width img)))
         (oheight (car (gimp-image-height img)))
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
    (set! imgTMP (car (gimp-edit-paste-as-new)))
    
    ;rise saturation
    (set! copy-layer (car (gimp-image-get-active-layer imgTMP)))
    (gimp-hue-saturation copy-layer ALL-HUES 0 0 saturation)
    
    ;add tint layer and filter color
    (set! tmp-layer (car (gimp-layer-copy copy-layer FALSE)))
    (gimp-drawable-set-name tmp-layer "Temp")
    (gimp-image-add-layer imgTMP tmp-layer -1)
    (plug-in-colors-channel-mixer 1 img tmp-layer TRUE
                                  red blue green ;R
                                  0 0 0 ;G
                                  0 0 0 ;B
                                  )
    
    ;add filter mask
    (set! tmp-layer-mask (car (gimp-layer-create-mask tmp-layer ADD-COPY-MASK)))
    (gimp-layer-add-mask tmp-layer tmp-layer-mask)
    
    ;colorize tint layer
    (gimp-context-set-foreground color)
    (gimp-selection-all imgTMP)
    (gimp-edit-bucket-fill tmp-layer FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
    
    ;get visible and add to original
    (gimp-drawable-set-visible copy-layer FALSE)
    (gimp-edit-copy-visible imgTMP)
    (set! tint-layer (car (gimp-layer-new-from-visible imgTMP img "Tint") ))
    (gimp-image-add-layer img tint-layer 0)
    
    ;set modes
    (gimp-layer-set-mode tint-layer SCREEN-MODE)
    (gimp-layer-set-opacity tint-layer opacity)
    
    ;get saturation layer
    (set! imgHSV (car (plug-in-decompose 1 imgTMP copy-layer "HSV" TRUE)))
    (set! layersHSV (gimp-image-get-layers imgHSV))
    (set! layerS (aref (cadr layersHSV) 1))
    (gimp-edit-copy layerS)
    
    ;add saturation mask
    (set! tint-layer-mask (car (gimp-layer-create-mask tint-layer ADD-WHITE-MASK )))
    (gimp-layer-add-mask tint-layer tint-layer-mask)
    (gimp-floating-sel-anchor (car (gimp-edit-paste tint-layer-mask TRUE)))
    
    ;desaturate original
    (if (= blackwhite TRUE) 
        ( begin 
           (gimp-desaturate-full adraw DESATURATE-LUMINOSITY)
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
