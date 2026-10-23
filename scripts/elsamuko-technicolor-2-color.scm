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
; Version 0.1 - Simulating the 2 color technicolor
; Version 0.2 - Some decomposing options
;
; To run the batch version of this script, run it with
; gimp -i -b '(elsamuko-technicolor-2-color-batch "picture.jpg" 0.97 FALSE 1 0.5 0 255 255 255 0 0 255 255 0 TRUE)' -b '(gimp-quit 0)'
; or for more than one picture
; gimp -i -b '(elsamuko-technicolor-2-color-batch "*.jpg" 0.97 FALSE 1 0.5 0 255 255 255 0 0 255 255 0 TRUE)' -b '(gimp-quit 0)'


(define (elsamuko-technicolor-2-color aimg adraw redpart greenpart cyanfill redfill yellowfill sharpen)
  (let* ((img          (car (gimp-item-get-image adraw)))
         (owidth       (car (gimp-image-get-width img)))
         (oheight      (car (gimp-image-get-height img)))
         (sharpenlayer (car (gimp-layer-copy adraw)))
         (redlayer     (car (gimp-layer-copy adraw)))
         (cyanlayer    (car (gimp-layer-copy adraw)))
         (yellowlayer  (car (gimp-layer-new img
                                            "Yellow"
                                            owidth 
                                            oheight
                                            1
                                            30 ;opacity
                                            LAYER-MODE-OVERLAY-LEGACY)))
         ;decomposing filter colors, you may change these
         (red-R redpart)
         (red-G (/ (- 1 redpart) 2) )
         (red-B (/ (- 1 redpart) 2) )
         (cyan-R 0)
         (cyan-G greenpart)
         (cyan-B (- 1 greenpart) )
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    (gimp-context-set-foreground '(0 0 0))
    (gimp-context-set-background '(255 255 255))
    (gimp-item-set-visible adraw FALSE)
    
    ;red and cyan filter
    (gimp-item-set-name cyanlayer "Cyan")
    (gimp-item-set-name redlayer "Red")
    
    (gimp-image-insert-layer img redlayer -1 -1)
    (gimp-image-insert-layer img cyanlayer -1 -1)
    
    (gimp-drawable-merge-new-filter redlayer "gegl:mono-mixer" "" LAYER-MODE-REPLACE 1.0
                                    "red" red-R "green" red-G "blue" red-B ;R
                                    )
    (gimp-drawable-merge-new-filter cyanlayer "gegl:mono-mixer" "" LAYER-MODE-REPLACE 1.0
                                    "red" cyan-R "green" cyan-G "blue" cyan-B ;R
                                    )
    
    ;colorize filter layers back
    (gimp-context-set-foreground cyanfill)
    (gimp-context-set-background redfill)
    
    (gimp-selection-all img)
    (gimp-context-set-paint-mode LAYER-MODE-SCREEN-LEGACY)
    (gimp-drawable-edit-fill redlayer FILL-FOREGROUND)
    (gimp-drawable-edit-fill cyanlayer FILL-BACKGROUND)
    (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY)
    
    (gimp-layer-set-mode cyanlayer LAYER-MODE-MULTIPLY-LEGACY)
    
    ;add yellow layer
    (gimp-image-insert-layer img yellowlayer -1 -1)
    (gimp-context-set-foreground yellowfill)
    (gimp-drawable-edit-fill yellowlayer FILL-FOREGROUND)
    
    ;sharpness + contrast layer
    (if(= sharpen TRUE)
       (begin
         (gimp-image-insert-layer img sharpenlayer -1 -1)
         (gimp-drawable-desaturate sharpenlayer DESATURATE-LIGHTNESS)
         (gimp-drawable-merge-new-filter sharpenlayer "gegl:unsharp-mask" "" LAYER-MODE-REPLACE 1.0 "std-dev" 5 "scale" 1 "threshold" 0)
         (gimp-layer-set-mode sharpenlayer LAYER-MODE-OVERLAY-LEGACY)
         (gimp-layer-set-opacity sharpenlayer 40)
         )
       )
    
    ; tidy up
    (gimp-selection-none img)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(define (elsamuko-technicolor-2-color-batch pattern quality overwrite
                                            redpart greenpart
                                            cyanfill_R cyanfill_G cyanfill_B
                                            redfill_R redfill_G redfill_B
                                            yellowfill_R yellowfill_G yellowfill_B
                                            sharpen)
  (gimp-message (string-append "Pattern: " pattern))
  (let* ((filelist (car (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
                  (fileparts (strbreakup filename "."))
                  (img (car (gimp-file-load RUN-NONINTERACTIVE filename)))
                  (adraw (vector-ref (car (gimp-image-get-selected-drawables img)) 0))
                  )
             (gimp-message (string-append "Filename: " filename))

             (gimp-message "Calling elsamuko-technicolor-2-color")
             (elsamuko-technicolor-2-color img adraw redpart greenpart
                                           (list cyanfill_R cyanfill_G cyanfill_B)
                                           (list redfill_R redfill_G redfill_B)
                                           (list yellowfill_R yellowfill_G yellowfill_B)
                                           sharpen)

             (gimp-image-merge-visible-layers img EXPAND-AS-NECESSARY)
             (set! adraw (vector-ref (car (gimp-image-get-selected-drawables img)) 0))

             (gimp-message "Saving")
             (if (= overwrite TRUE)
                 (file-jpeg-export #:run-mode RUN-NONINTERACTIVE #:image img #:file filename #:quality quality #:optimize TRUE)
                 (file-jpeg-export #:run-mode RUN-NONINTERACTIVE #:image img #:file (string-append (car fileparts) "-Technicolor2.jpg") #:quality quality #:optimize TRUE))

             (gimp-image-delete img)
             (set! filelist (cdr filelist))
             )
           )
    )
  )

(script-fu-register "elsamuko-technicolor-2-color"
                    _"_Technicolor 2 Color"
                    "Simulating Technicolor Film.
Newest version can be downloaded from http://registry.gimp.org/node/9129"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "09/09/08"
                    "*"
                    SF-IMAGE       "Input image"      0
                    SF-DRAWABLE    "Input drawable"   0
                    SF-ADJUSTMENT _"Red Part of Red Filter"    '(1.0 0 1 0.1 0.2 1 0)
                    SF-ADJUSTMENT _"Green Part of Cyan Filter" '(0.5 0 1 0.1 0.2 1 0)
                    SF-COLOR      _"Recomposing Cyan" '(0 255 255)
                    SF-COLOR      _"Recomposing Red"  '(255 0 0)
                    SF-COLOR      _"Additive Yellow"  '(255 255 0)
                    SF-TOGGLE     _"Sharpen"  TRUE
                    )

(script-fu-menu-register "elsamuko-technicolor-2-color" _"<Image>/Colors")
