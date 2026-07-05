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
; Ported to the GIMP 3.0 PDB API in 2026 by Claude Opus (Anthropic).
;
; Version 0.1 - Simulate a high quality photo like these from the National Geographic
;               Thanks to Martin Egger <martin.egger@gmx.net> for the shadow revovery and the sharpen script
;
; This is the batch version of the NG script, run it with
; gimp -i -b '(elsamuko-national-geographic-batch "picture.jpg" 60 1 60 25 0.4 1 0)' -b '(gimp-quit 0)'
; or for more than one picture
; gimp -i -b '(elsamuko-national-geographic-batch "*.jpg" 60 1 60 25 0.4 1 0)' -b '(gimp-quit 0)'

(define (elsamuko-national-geographic aimg adraw shadowopacity
                                      sharpness screenopacity
                                      overlayopacity localcontrast
                                      screenmask tint)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (overlaylayer 0)
         (overlaylayer2 0)
         (screenlayer 0)
         (contrastlayer 0)         
         (tmplayer1 0)         
         (tmplayer2 0)         
         (floatingsel 0)
         
         (ShadowLayer (car (gimp-layer-copy adraw)))

         (MaskImage (car (gimp-image-duplicate aimg)))
         (MaskLayer (car (gimp-image-get-layers MaskImage)))
         (OrigLayer (car (gimp-image-get-layers aimg)))
         (SharpenLayer (car (gimp-layer-copy adraw)))
         )
    
    ;init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    ;(gimp-context-set-foreground '(0 0 0))
    ;(gimp-context-set-background '(255 255 255))
    
    ;shadow recovery from here: http://registry.gimp.org/node/112
    (if(> shadowopacity 0)
       (begin
         (gimp-image-insert-layer img ShadowLayer 0 -1)
         (gimp-drawable-desaturate ShadowLayer DESATURATE-LUMA)
         (gimp-drawable-invert ShadowLayer FALSE)
         (let* ((ShadowMask (car (gimp-layer-create-mask ShadowLayer ADD-MASK-WHITE))))
           (gimp-layer-add-mask ShadowLayer ShadowMask)
           (gimp-selection-all img)
           (gimp-edit-copy (vector ShadowLayer))
           (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste ShadowMask TRUE)) 0))
           )
         (gimp-layer-set-mode ShadowLayer LAYER-MODE-OVERLAY-LEGACY)
         (gimp-layer-set-opacity ShadowLayer shadowopacity)
         (gimp-item-set-name ShadowLayer "Shadow Recovery")
         )
       )
    
    ;smart sharpen from here: http://registry.gimp.org/node/108
    (if(> sharpness 0)
       (begin
         (gimp-image-insert-layer img SharpenLayer 0 -1)
         ; GIMP 3.0: plug-in-decompose's "Value" extraction is replaced by desaturating
         ; the SharpenLayer (a copy of the drawable) by VALUE — same grayscale Value channel.
         (gimp-drawable-desaturate SharpenLayer DESATURATE-VALUE)
         (gimp-layer-set-mode SharpenLayer LAYER-MODE-HSV-VALUE-LEGACY)
         (gimp-drawable-merge-new-filter (vector-ref MaskLayer 0) "gegl:edge" "Edge" LAYER-MODE-REPLACE 1.0 "amount" 6.0)
         (gimp-drawable-levels-stretch (vector-ref MaskLayer 0))
         (gimp-image-convert-grayscale MaskImage)
         (gimp-drawable-merge-new-filter (vector-ref MaskLayer 0) "gegl:gaussian-blur" "Gaussian Blur" LAYER-MODE-REPLACE 1.0
                                         "std-dev-x" (/ 6 3.0) "std-dev-y" (/ 6 3.0))
         (let* ((SharpenChannel (car (gimp-layer-create-mask SharpenLayer ADD-MASK-WHITE)))
                )
           (gimp-layer-add-mask SharpenLayer SharpenChannel)
           (gimp-selection-all MaskImage)
           (gimp-edit-copy (vector (vector-ref MaskLayer 0)))
           (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste SharpenChannel FALSE)) 0))
           (gimp-image-delete MaskImage)
           (gimp-drawable-merge-new-filter SharpenLayer "gegl:unsharp-mask" "Unsharp Mask" LAYER-MODE-REPLACE 1.0
                                           "std-dev" (/ 1 3.0) "scale" sharpness)
           (gimp-layer-set-opacity SharpenLayer 80)
           (gimp-layer-set-edit-mask SharpenLayer FALSE)
           )
         (gimp-item-set-name SharpenLayer "Sharpen")
         )
       )
    
    ;enhance local contrast
    (if(> localcontrast 0)
       (begin
         (gimp-edit-copy-visible img)
         (set! tmplayer1 (car (gimp-layer-new-from-visible img img "Temp 1")))
         (set! tmplayer2 (car (gimp-layer-new-from-visible img img "Temp 2")))
         (gimp-image-insert-layer img tmplayer1 0 -1)
         (gimp-image-insert-layer img tmplayer2 0 -1)
         (gimp-drawable-merge-new-filter tmplayer1 "gegl:unsharp-mask" "Unsharp Mask" LAYER-MODE-REPLACE 1.0
                                         "std-dev" (/ 60 3.0) "scale" localcontrast)
         (gimp-layer-set-mode tmplayer2 LAYER-MODE-GRAIN-EXTRACT-LEGACY)
         (gimp-edit-copy-visible img)
         (set! contrastlayer (car (gimp-layer-new-from-visible img img "Local Contrast")))
         (gimp-image-insert-layer img contrastlayer 0 -1)
         (gimp-layer-set-mode contrastlayer LAYER-MODE-GRAIN-MERGE-LEGACY)
         (gimp-image-remove-layer img tmplayer1)
         (gimp-image-remove-layer img tmplayer2)
         )
       )
    
    ;copy visible three times
    (gimp-edit-copy-visible img)
    (set! overlaylayer (car (gimp-layer-new-from-visible img img "Overlay")))
    (set! overlaylayer2 (car (gimp-layer-new-from-visible img img "Overlay2")))
    (set! screenlayer (car (gimp-layer-new-from-visible img img "Screen")))
    
    ;add screen- and overlay- layers
    (gimp-image-insert-layer img screenlayer 0 -1)
    (gimp-image-insert-layer img overlaylayer 0 -1)
    (gimp-image-insert-layer img overlaylayer2 0 -1)
    
    ;desaturate layers
    (gimp-drawable-desaturate screenlayer DESATURATE-LUMA)
    (gimp-drawable-desaturate overlaylayer DESATURATE-LUMA)
    (gimp-drawable-desaturate overlaylayer2 DESATURATE-LUMA)

    ;set modes
    (gimp-layer-set-mode screenlayer LAYER-MODE-SCREEN-LEGACY)
    (gimp-layer-set-mode overlaylayer LAYER-MODE-OVERLAY-LEGACY)
    (gimp-layer-set-mode overlaylayer2 LAYER-MODE-OVERLAY-LEGACY)
    (gimp-layer-set-opacity screenlayer screenopacity)
    (gimp-layer-set-opacity overlaylayer overlayopacity)
    (gimp-layer-set-opacity overlaylayer2 overlayopacity)
    
    ;layermask for the screen layer
    (if(= screenmask TRUE)
       (begin
         (set! floatingsel (car (gimp-layer-create-mask screenlayer ADD-MASK-COPY)))
         (gimp-layer-add-mask screenlayer floatingsel)
         (gimp-drawable-invert floatingsel FALSE)
         )
       )
    
    ;overlay tint
    ;red
    (if(= tint 1)
       (begin
         (gimp-drawable-colorize-hsl screenlayer   0 25 0)
         (gimp-drawable-colorize-hsl overlaylayer  0 25 0)
         (gimp-drawable-colorize-hsl overlaylayer2 0 25 0)
         )
       )
    ;blue
    (if(= tint 2)
       (begin
         (gimp-drawable-colorize-hsl screenlayer   225 25 0)
         (gimp-drawable-colorize-hsl overlaylayer  225 25 0)
         (gimp-drawable-colorize-hsl overlaylayer2 225 25 0)
         )
       )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(define (elsamuko-national-geographic-batch pattern shadowopacity
                                            sharpness screenopacity
                                            overlayopacity localcontrast
                                            screenmask tint)
  (gimp-message (string-append "Pattern: " pattern))
  (let* ((filelist (car (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
                  (fileparts (strbreakup filename "."))
                  (img (car (gimp-file-load RUN-NONINTERACTIVE filename)))
                  (adraw (vector-ref (car (gimp-image-get-layers img)) 0))
                  )
             (gimp-message (string-append "Filename: " filename))

             (gimp-message "Calling elsamuko-national-geographic")
             (elsamuko-national-geographic img adraw shadowopacity
                                           sharpness screenopacity
                                           overlayopacity localcontrast
                                           screenmask tint)

             (gimp-image-merge-visible-layers img EXPAND-AS-NECESSARY)
             (set! adraw (vector-ref (car (gimp-image-get-layers img)) 0))

             (gimp-message "Saving")
             (gimp-file-save RUN-NONINTERACTIVE img filename)
             (gimp-image-delete img)
             (set! filelist (cdr filelist))
             )
           )
    )
  )

(script-fu-register "elsamuko-national-geographic"
                    _"_National Geographic"
                    "Simulating high quality photos.
Latest version can be downloaded from http://registry.gimp.org/node/9592"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "22/09/08"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    SF-ADJUSTMENT _"Shadow Recover Opacity"   '(60  0  100  1   5 0 0)
                    SF-ADJUSTMENT _"Sharpness"                '(0.5 0    2  0.1 1 1 0)
                    SF-ADJUSTMENT _"Screen Layer Opacity"     '(50  0  100  1   5 0 0)                    
                    SF-ADJUSTMENT _"Overlay Layer Opacity"    '(50  0  100  1   5 0 0)
                    SF-ADJUSTMENT _"Local Contrast"           '(0.4 0    2  0.1 1 1 0)
                    SF-TOGGLE     _"Layer Mask for the Screen Layer" TRUE
                    SF-OPTION     _"Overlay Tint"           '("Neutral"
                                                              "Red"
                                                              "Blue")
                    )

(script-fu-menu-register "elsamuko-national-geographic" _"<Image>/Filters/Generic")
