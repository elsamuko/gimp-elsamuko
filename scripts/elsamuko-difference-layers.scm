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
; Copyright (C) 2009 elsamuko <elsamuko@web.de>
;
; Version 0.1 - Creates two difference layers as a basis for further editing.
;               A-B = C
;               B-A = D
;               A-C+D = B


(define (elsamuko-difference-layers img draw)
  (if (< 1 (car (gimp-image-get-layers img)))
      (let*
          ((layer-list (cadr (gimp-image-get-layers img)))
           (top-layer (aref layer-list 0))
           (bottom-layer (aref layer-list 1))
           (additive-layer 0)
           (subtractive-layer 0)
           )
        
        ;init
        (gimp-context-push)
        (gimp-image-undo-group-start img)
        
        ;subtract first from second
        (gimp-layer-set-mode top-layer SUBTRACT-MODE)
        (gimp-edit-copy-visible img)
        (set! subtractive-layer (car (gimp-layer-new-from-visible img img "Subtractive") ))
        (gimp-image-add-layer img subtractive-layer 0)
        (gimp-drawable-set-visible subtractive-layer FALSE)
        
        ;subtract second from first
        (gimp-image-lower-layer img top-layer)
        (gimp-layer-set-mode top-layer NORMAL-MODE)
        (gimp-layer-set-mode bottom-layer SUBTRACT-MODE)
        (gimp-edit-copy-visible img)
        (set! additive-layer (car (gimp-layer-new-from-visible img img "Additive") ))
        (gimp-image-add-layer img additive-layer 0)    
        
        (gimp-drawable-set-visible subtractive-layer TRUE)
        (gimp-layer-set-mode additive-layer ADDITION-MODE)
        (gimp-layer-set-mode subtractive-layer SUBTRACT-MODE)
        
        (gimp-layer-set-mode bottom-layer NORMAL-MODE)
        
        ; tidy up
        (gimp-image-undo-group-end img)
        (gimp-displays-flush)
        (gimp-context-pop)
        )
      ;number of layers is less than 2
      (gimp-message "Number of layers is less than 2")
      )
  )

(script-fu-register "elsamuko-difference-layers"
                    _"_Difference Layers"
                    "Creates difference layers from first two layers.
Latest version can be downloaded from http://registry.gimp.org/node/20340"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "22/04/09"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    )

(script-fu-menu-register "elsamuko-difference-layers" _"<Image>/Layer")
