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
; Version 0.1 - Creates a gravure in the second layer
;


(define (elsamuko-glass-displacement img draw strength)
  (if (< 1 (car (gimp-image-get-layers img)))
      (let*
          ((layer-list (cadr (gimp-image-get-layers img)))
           (gravure-layer (aref layer-list 0))
           (image-layer (aref layer-list 1))
           (x-layer 0)
           (y-layer 0)
           )
        
        ;init
        (gimp-context-push)
        (gimp-image-undo-group-start img)
        
        ;duplicate x-layer
        (set! x-layer (car(gimp-layer-copy gravure-layer FALSE)))
        (set! y-layer (car(gimp-layer-copy gravure-layer FALSE)))
        (gimp-image-add-layer img x-layer 0)
        (gimp-image-add-layer img y-layer 0)
        
        ;bumpmap x and y layers
        (plug-in-bump-map 1 img x-layer x-layer 180 45 2 0 0 0 0 TRUE FALSE LINEAR)
        (plug-in-bump-map 1 img y-layer y-layer  90 45 2 0 0 0 0 TRUE FALSE LINEAR)
        
        ;displacement
        (plug-in-displace 1 img image-layer strength strength TRUE TRUE x-layer y-layer 0)
        
        ;hide top layers
        (gimp-drawable-set-visible x-layer FALSE)
        (gimp-drawable-set-visible y-layer FALSE)
        
        ;blend x-layer slightly
        (gimp-layer-set-mode gravure-layer OVERLAY-MODE)
        (gimp-layer-set-opacity gravure-layer 80)
        
        ; tidy up
        (gimp-image-undo-group-end img)
        (gimp-displays-flush)
        (gimp-context-pop)
        )
      ;number of layers is less than 2
      (gimp-message "Number of layers is less than 2")
      )
  )

(script-fu-register "elsamuko-glass-displacement"
                    _"_Glass Displacement"
                    "Create a glass gravure from first two layers.
Latest version can be downloaded from http://registry.gimp.org"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "22/09/10"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    SF-ADJUSTMENT _"Strength"            '(10 1 20 1 10 0 0)
                    )

(script-fu-menu-register "elsamuko-glass-displacement" _"<Image>/Filters/Distorts")
