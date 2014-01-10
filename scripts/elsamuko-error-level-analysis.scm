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
; Explanation from http://errorlevelanalysis.com/:
; Error level analysis shows differing error levels throughout this image, strongly suggesting some form of digital manipulation.
;
; "Error level analysis (ELA) works by intentionally resaving the image at a known error rate,
; such as 95%, and then computing the difference between the images.
; If there is virtually no change, then the cell has reached its local minima for error at that quality level.
; However, if there is a large amount of change, then the pixels are not at their local minima and are effectively original." 
; -Neal Krawetz, Ph.D. http://www.hackerfactor.com 
;


(define (elsamuko-error-level-analysis img draw quality filename)
  (let* ((img-tmp 0)
         (img-tmp-2 0)
         (draw-tmp 0)
         (error-layer 0)
         )
    
    ;init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    
    ;save image as 70% jpeg
    (set! img-tmp (car (gimp-image-duplicate img)))
    (gimp-image-merge-visible-layers img-tmp EXPAND-AS-NECESSARY)
    (set! draw-tmp (car (gimp-image-get-active-drawable img-tmp)))
    (file-jpeg-save RUN-NONINTERACTIVE img-tmp draw-tmp filename filename quality 0 0 0 "GIMP ELA Temporary Image" 0 0 0 0)
    
    ;open 70% jpeg, set as diff layer
    (set! draw-tmp (car(gimp-file-load-layer RUN-NONINTERACTIVE img-tmp filename)))
    (gimp-image-add-layer img-tmp draw-tmp -1)
    (gimp-layer-set-mode draw-tmp DIFFERENCE-MODE)
    (file-delete filename)
    
    ;error layer on top
    (gimp-edit-copy-visible img-tmp)
    (set! error-layer (car (gimp-layer-new-from-visible img-tmp img-tmp "Error Levels") ))
    (gimp-image-add-layer img-tmp error-layer -1)    
    (gimp-levels-stretch error-layer)
    ;(gimp-display-new img-tmp)
    
    ;add error levels as layer on orig image
    (gimp-edit-copy-visible img-tmp)
    (set! error-layer (car (gimp-layer-new-from-visible img-tmp img "Error Levels") ))
    (gimp-image-add-layer img error-layer -1)
    (gimp-drawable-set-name error-layer "Error Levels")
    
    ; tidy up
    (gimp-image-delete img-tmp)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-error-level-analysis"
                    _"_Error Level Analysis"
                    "Error level analysis shows differing error levels throughout this image,
 strongly suggesting some form of digital manipulation. More info here:
http://errorlevelanalysis.com/"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "2010-10-02"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    SF-ADJUSTMENT _"Quality"               '(0.7 0 1 0.1 1 1 0)
                    SF-STRING      "Temporary File Name"   "error-level-analysis-tmp.jpg" 
                    )

(script-fu-menu-register "elsamuko-error-level-analysis" _"<Image>/Image")
