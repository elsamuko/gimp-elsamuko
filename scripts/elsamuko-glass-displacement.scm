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
  (if (< 1 (vector-length (car (gimp-image-get-layers img))))
      (let*
          ((layer-list (car (gimp-image-get-layers img)))
           (gravure-layer (vector-ref layer-list
 0))
           (image-layer (vector-ref layer-list
 1))
           (x-layer 0)
           (y-layer 0)
           )
        
        ;init
        (gimp-context-push)
        (gimp-image-undo-group-start img)
        
        ;duplicate x-layer
        (set! x-layer (car(gimp-layer-copy gravure-layer)))
        (set! y-layer (car(gimp-layer-copy gravure-layer)))
        (gimp-image-insert-layer img x-layer -1 0)
        (gimp-image-insert-layer img y-layer -1 0)
        
        ;bumpmap x and y layers
        (let* ((filter (car (gimp-drawable-filter-new x-layer "gegl:bump-map" ""))))
          (gimp-drawable-filter-configure filter LAYER-MODE-REPLACE 1.0 "azimuth" 180 "elevation" 45 "depth" 2 "compensate" TRUE "invert" FALSE "type" "linear")
          (gimp-drawable-filter-set-aux-input filter "aux" x-layer)
          (gimp-drawable-merge-filter x-layer filter))
        (let* ((filter (car (gimp-drawable-filter-new y-layer "gegl:bump-map" ""))))
          (gimp-drawable-filter-configure filter LAYER-MODE-REPLACE 1.0 "azimuth" 90 "elevation" 45 "depth" 2 "compensate" TRUE "invert" FALSE "type" "linear")
          (gimp-drawable-filter-set-aux-input filter "aux" y-layer)
          (gimp-drawable-merge-filter y-layer filter))
        
        ;displacement
        (let* ((filter (car (gimp-drawable-filter-new image-layer "gegl:displace" ""))))
          (gimp-drawable-filter-configure filter LAYER-MODE-REPLACE 1.0 "amount-x" strength "amount-y" strength "abyss-policy" "clamp")
          (gimp-drawable-filter-set-aux-input filter "aux" x-layer)
          (gimp-drawable-filter-set-aux-input filter "aux2" y-layer)
          (gimp-drawable-merge-filter image-layer filter))

        
        ;hide top layers
        (gimp-item-set-visible x-layer FALSE)
        (gimp-item-set-visible y-layer FALSE)
        
        ;blend x-layer slightly
        (gimp-layer-set-mode gravure-layer LAYER-MODE-OVERLAY-LEGACY)
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
