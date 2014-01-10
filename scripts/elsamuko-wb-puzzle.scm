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
; Version 0.1 - Creating a Puzzle of white balanced pieces.
;


(define (elsamuko-wb-puzzle aimg adraw puzzlewidth puzzleheight feathervalue)
  (let* ((img (car (gimp-drawable-get-image adraw)))
         (wblayer (car (gimp-layer-copy adraw FALSE)))
         (owidth (car (gimp-image-width img)))
         (oheight (car (gimp-image-height img)))
         (itermaxX (/ owidth puzzlewidth))
         (itermaxY (/ oheight puzzleheight))
         (iterwidth 0) ;iterators
         (iterheight 0)
         )
    
    ; init
    (define (block-select aimg x0 y0 blockwidth blockheight x y);x=0..itermaxX-1 y=0..itermaxY-1
      (let*	((startx (+ x0 (* x blockwidth))) 
                 (starty (+ y0 (* y blockheight)))
                 )
        (gimp-rect-select aimg startx starty (+ blockwidth 0) (+ blockheight 0) CHANNEL-OP-REPLACE FALSE 0)
        )
      )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    ;(gimp-context-set-foreground '(0 0 0))
    ;(gimp-context-set-background '(255 255 255))
    
    ;select rectangular blocks and auto white balance them
    (gimp-image-add-layer img wblayer -1)
    
    (while (< iterwidth itermaxX)
           (while (< iterheight itermaxY)
                  (block-select img 0 0 puzzlewidth puzzleheight iterwidth iterheight)
                  (if (> feathervalue 0)
                      (gimp-selection-feather img feathervalue)
                      )
                  (gimp-levels-stretch wblayer)
                  (set! iterheight (+ iterheight 1))
                  )
           (set! iterheight 0)
           (set! iterwidth (+ iterwidth 1))
           )
    
    ; tidy up
    (gimp-selection-none img)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-wb-puzzle"
                    _"_White Balance Puzzle"
                    "Creating a Puzzle of white balanced pieces.
 Newest version can be downloaded from http://registry.gimp.org/"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "02/09/08"
                    "*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-ADJUSTMENT _"Block Width" '(40 1 2000 1 10 0 1)
                    SF-ADJUSTMENT _"Block Height" '(40 1 2000 1 10 0 1)
                    SF-ADJUSTMENT _"Feather" '(0 0 1000 1 10 0 1)
                    )
(script-fu-menu-register "elsamuko-wb-puzzle" _"<Image>/Filters/Light and Shadow")
