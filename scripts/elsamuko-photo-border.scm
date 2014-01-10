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
; Version 0.1 - Simulated Border after: http://flickr.com/photos/conwayl/531028738/
;


(define (elsamuko-photo-border aimg adraw aplace ashift aradius aborder_distance)
  (let*  ((img (car (gimp-drawable-get-image adraw)))
          (draw (car (gimp-layer-copy adraw FALSE)))
          (border_distance (/ aborder_distance 100))
          )
    
    ; init
    (define (script-fu-photo-border-helper aimg adraw ashift aradius border_distance)
      (let*  ((img (car (gimp-drawable-get-image adraw)))
              (owidth (car (gimp-image-width img)))
              (oheight (car (gimp-image-height img)))
              (arith_med (/ (+ owidth oheight) 2))
              (xcoord 0)
              (ycoord 0)
              (radius 0)
              (thickness 0)
              (soft_margin (car (gimp-layer-new img
                                                owidth 
                                                oheight
                                                1
                                                "Soft Margin"
                                                100 
                                                ADDITION-MODE)))
              (soft_margin_2 (car (gimp-layer-new img
                                                  owidth 
                                                  oheight
                                                  1
                                                  "Soft Margin 2"
                                                  100 
                                                  OVERLAY-MODE)))
              (hard_margin (car (gimp-layer-new img
                                                owidth 
                                                oheight
                                                1
                                                "Hard Margin"
                                                100 
                                                NORMAL-MODE)))
              )
        
        ;one layer with soft, red ending
        (gimp-image-add-layer img soft_margin -1)
        (gimp-drawable-fill soft_margin TRANSPARENT-FILL)
        
        (set! radius (* aradius oheight)) ;radius is diameter...
        (set! ycoord (* border_distance oheight))
        (set! xcoord (- (+ (* 0.5 owidth) (* (/ ashift 100) owidth)) (/ radius 2)))
        (set! thickness (* (/ (+ oheight owidth) 2) 0.04))
        
        (gimp-ellipse-select img xcoord ycoord radius radius ADD TRUE TRUE thickness) ;last term is feather strength
        (gimp-selection-invert img)
        (gimp-context-set-foreground '(174 28 14))
        (gimp-edit-bucket-fill soft_margin FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
        (gimp-selection-none img)
        
        ;one layer with hard, white (overexposed) ending
        (gimp-image-add-layer img hard_margin -1)
        (gimp-drawable-fill hard_margin TRANSPARENT-FILL)
        
        (set! ycoord (- ycoord (* thickness 0.65)))
        (gimp-ellipse-select img xcoord ycoord radius radius ADD TRUE FALSE 0) ;last term is feather strength
        (gimp-selection-invert img)
        ;(script-fu-distress-selection img hard_margin 127 8 3 2 FALSE TRUE)
        (script-fu-distress-selection img hard_margin 127 12 2 2 FALSE TRUE)
        (script-fu-distress-selection img hard_margin 127 12 1 2 FALSE TRUE)
        (gimp-context-set-foreground '(255 255 255))
        (gimp-edit-bucket-fill hard_margin FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
        (gimp-selection-none img)
        (plug-in-mblur 1 img hard_margin 0 (* thickness 0.4) 90 0 0)
        (plug-in-unsharp-mask 1 img hard_margin 5 2 0)
        (plug-in-unsharp-mask 1 img hard_margin 2 1 0)
        (plug-in-gauss 1 img hard_margin 1 1 1)
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-context-set-background '(255 255 255))
    
    ;rotating image
    (if (> aplace 0)
        (gimp-image-rotate img (- aplace 1))
        )
    (set! draw (car (gimp-image-get-active-drawable img)))
    
    ;calling border helper function
    (script-fu-photo-border-helper img draw ashift aradius border_distance)
    
    ;rotating image back
    (if (> aplace 0)
        (gimp-image-rotate img (- 3 aplace))
        )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-photo-border"
                    _"_Photo Border"
                    "Simulating the border of the first overexposed picture of a film.
	Newest version can be downloaded from http://registry.gimp.org/"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "17/08/08"
                    "*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-OPTION     _"Place" '("Top" "Left" "Down" "Right")
                    SF-ADJUSTMENT _"Shift (%)" '(0 -50 50 1 10 0 0)
                    SF-ADJUSTMENT _"Radius" '(7 1 20 1 2 0 0)
                    SF-ADJUSTMENT _"Border Distance (%)" '(12 -5 100 1 10 0 0)
                    )
(script-fu-menu-register "elsamuko-photo-border" _"<Image>/Filters/Generic")
