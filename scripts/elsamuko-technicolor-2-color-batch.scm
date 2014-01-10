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
;
; This is the batch version of the elsamuko-technicolor-2-color-batch script, run it with
; gimp -i -b '(elsamuko-technicolor-2-color-batch "picture.jpg" 0.97 FALSE 1 0.5 0 255 255 255 0 0 255 255 0 TRUE)' -b '(gimp-quit 0)'
; or for more than one picture
; gimp -i -b '(elsamuko-technicolor-2-color-batch "*.jpg" 0.97 FALSE 1 0.5 0 255 255 255 0 0 255 255 0 TRUE)' -b '(gimp-quit 0)'


(define (elsamuko-technicolor-2-color-batch pattern quality overwrite
                                            redpart greenpart
                                            cyanfill_R cyanfill_G cyanfill_B
                                            redfill_R redfill_G redfill_B
                                            yellowfill_R yellowfill_G yellowfill_B
                                            sharpen)
   	(let* ((filelist (cadr (file-glob pattern 1))))
          (while (not (null? filelist))
                 (let* ((filename (car filelist))
                        (fileparts (strbreakup filename "."))
                        (img (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
                        (adraw (car (gimp-image-get-active-drawable img)))
                        (cyanfill (list cyanfill_R cyanfill_G cyanfill_B))
                        (redfill (list redfill_R redfill_G redfill_B))
                        (yellowfill (list yellowfill_R yellowfill_G yellowfill_B))
                        
                        ;--------------------------------------------------------
                        ;--------------------------------------------------------
                        ;--------------------------------------------------------
                        
                        (owidth       (car (gimp-image-width img)))
                        (oheight      (car (gimp-image-height img)))
                        (sharpenlayer (car (gimp-layer-copy adraw FALSE)))
                        (redlayer     (car (gimp-layer-copy adraw FALSE)))
                        (cyanlayer    (car (gimp-layer-copy adraw FALSE)))
                        (yellowlayer  (car (gimp-layer-new img
                                                           owidth 
                                                           oheight
                                                           1
                                                           "Yellow" 
                                                           30 ;opacity
                                                           OVERLAY-MODE)))
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
                   (gimp-drawable-set-visible adraw FALSE)
                   
                   ;red and cyan filter
                   (gimp-drawable-set-name cyanlayer "Cyan")
                   (gimp-drawable-set-name redlayer "Red")
                   
                   (gimp-image-add-layer img redlayer -1)
                   (gimp-image-add-layer img cyanlayer -1)
                   
                   (plug-in-colors-channel-mixer 1 img redlayer TRUE
                                                 red-R red-G red-B ;R
                                                 0 0 0 ;G
                                                 0 0 0 ;B
                                                 )
                   (plug-in-colors-channel-mixer 1 img cyanlayer TRUE
                                                 cyan-R cyan-G cyan-B ;R
                                                 0 0 0 ;G
                                                 0 0 0 ;B
                                                 )
                   
                   ;colorize filter layers back
                   (gimp-context-set-foreground cyanfill)
                   (gimp-context-set-background redfill)
                   
                   (gimp-selection-all img)
                   (gimp-edit-bucket-fill redlayer FG-BUCKET-FILL SCREEN-MODE 100 0 FALSE 0 0)
                   (gimp-edit-bucket-fill cyanlayer BG-BUCKET-FILL SCREEN-MODE 100 0 FALSE 0 0)
                   
                   (gimp-layer-set-mode cyanlayer MULTIPLY-MODE)
                   
                   ;add yellow layer
                   (gimp-image-add-layer img yellowlayer -1)
                   (gimp-context-set-foreground yellowfill)
                   (gimp-edit-bucket-fill yellowlayer FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
                   
                   ;sharpness + contrast layer
                   (if(= sharpen TRUE)
                      (begin
                        (gimp-image-add-layer img sharpenlayer -1)
                        (gimp-desaturate-full sharpenlayer DESATURATE-LIGHTNESS)
                        (plug-in-unsharp-mask 1 img sharpenlayer 5 1 0)
                        (gimp-layer-set-mode sharpenlayer OVERLAY-MODE)
                        (gimp-layer-set-opacity sharpenlayer 40)
                        )
                      )
                   
                   ; tidy up
                   (gimp-selection-none img)
                   (gimp-image-undo-group-end img)
                   (gimp-displays-flush)
                   (gimp-context-pop)
                   
                   
                   ;--------------------------------------------------------
                   ;--------------------------------------------------------
                   ;--------------------------------------------------------
                   ; Ending
                   (gimp-image-merge-visible-layers img EXPAND-AS-NECESSARY)
                   (set! adraw (car (gimp-image-get-active-drawable img)))
                   (if (= overwrite TRUE)  
                       (file-jpeg-save RUN-NONINTERACTIVE img adraw filename filename quality 0 1 0 "" 0 1 0 1)
                       (file-jpeg-save RUN-NONINTERACTIVE img adraw (string-append (car fileparts) "-Technicolor2.jpg") (string-append (car fileparts) "-Technicolor2.jpg") quality 0 1 0 "" 0 1 0 1))
                   (gimp-image-delete img))
                 (set! filelist (cdr filelist))
                 )
          )
  )
