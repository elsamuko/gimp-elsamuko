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
; Version 0.1 - Adding Film Grain after: http://www.gimpguru.org/Tutorials/FilmGrain/
;

(define (elsamuko-antique-border aimg adraw thicknesspercent radiuspercent color granularity smooth motion resize)
  (let* ((img (car (gimp-drawable-get-image adraw)))
         (owidth (car (gimp-image-width img)))
         (oheight (car (gimp-image-height img)))
         ;the border has to reach a little bit into the image, if it's resized:
         (thickness (- (* owidth (/ thicknesspercent 100)) granularity))
         )
    
    ; init
    (define (script-fu-antique-border-helper aimg adraw thicknesspercent radiuspercent color granularity smooth motion)
      (let* ((img (car (gimp-drawable-get-image adraw)))
             (owidth (car (gimp-image-width img)))
             (thickness (* owidth (/ thicknesspercent 100)))
             (radius (* owidth (/ radiuspercent 100))) 
             (oheight (car (gimp-image-height img)))
             (borderlayer (car (gimp-layer-new img
                                               owidth 
                                               oheight
                                               1
                                               "Border" 
                                               100 
                                               NORMAL-MODE)))
             )
        
        ;add new layer
        (gimp-image-add-layer img borderlayer -1)
        (gimp-drawable-fill borderlayer TRANSPARENT-FILL)
        
        ;select rounded rectangle, distress and invert it
        (gimp-round-rect-select img thickness thickness 
                                (- owidth (* 2 thickness)) (- oheight (* 2 thickness))
                                radius radius
                                CHANNEL-OP-REPLACE TRUE FALSE 0 0)
        (if (> granularity 0)
            (script-fu-distress-selection img borderlayer 127 12 granularity smooth TRUE TRUE)
            )
        (gimp-selection-invert img)
        
        ;fill up with border color
        (gimp-context-set-foreground color)
        (gimp-edit-bucket-fill borderlayer FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
        (gimp-selection-none img)
        
        ;blur border
        (if (> motion 0)
            (plug-in-mblur 1 img borderlayer 2 motion 0 (/ owidth 2) (/ oheight 2))
            )
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    ;resize image
    (if (= resize TRUE)
        (gimp-image-resize img (+ owidth (* 2 thickness)) (+ oheight (* 2 thickness)) thickness thickness)
        )
    
    ;call border function
    (script-fu-antique-border-helper img adraw thicknesspercent radiuspercent color granularity smooth motion)
    
    ;tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-antique-border"
                    _"_Antique Photo Border..."
                    "Adding an Antique Photo Border
Newest version can be downloaded from http://registry.gimp.org"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "15/09/08"
                    "*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-ADJUSTMENT _"Border Thickness (% of Width)" '(1 0 35 0.1 5 1 1)
                    SF-ADJUSTMENT _"Edge Radius (% of Width)"      '(10 0 50 0.1 5 1 1)
                    SF-COLOR      _"Border Color"         '(246 249 240)      
                    SF-ADJUSTMENT _"Distress Granularity" '(1 0 25 1 5 0 1)
                    SF-ADJUSTMENT _"Smooth Value"         '(3 1 25 1 5 0 1)
                    SF-ADJUSTMENT _"Motion Blur"          '(1 0  5 1 5 0 1)
                    SF-TOGGLE     _"Resize"               FALSE
                    )

(script-fu-menu-register "elsamuko-antique-border" _"<Image>/Filters/Decor")
