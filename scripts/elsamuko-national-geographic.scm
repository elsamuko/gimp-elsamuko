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
; Version 0.1 - Simulate a high quality photo like these from the National Geographic
;               Thanks to Martin Egger <martin.egger@gmx.net> for the shadow revovery and the sharpen script
;

(define (elsamuko-national-geographic aimg adraw shadowopacity
                                      sharpness screenopacity
                                      overlayopacity localcontrast
                                      screenmask tint)
  (let* ((img (car (gimp-drawable-get-image adraw)))
         (owidth (car (gimp-image-width img)))
         (oheight (car (gimp-image-height img)))
         (overlaylayer 0)
         (overlaylayer2 0)
         (screenlayer 0)
         (contrastlayer 0)         
         (tmplayer1 0)         
         (tmplayer2 0)         
         (floatingsel 0)
         
         (CopyLayer (car (gimp-layer-copy adraw TRUE)))
         (ShadowLayer (car (gimp-layer-copy adraw TRUE)))         
         
         (MaskImage (car (gimp-image-duplicate aimg)))
         (MaskLayer (cadr (gimp-image-get-layers MaskImage)))
         (OrigLayer (cadr (gimp-image-get-layers aimg)))
         (HSVImage (car (plug-in-decompose TRUE aimg adraw "Value" TRUE)))
         (HSVLayer (cadr (gimp-image-get-layers HSVImage)))
         (SharpenLayer (car (gimp-layer-copy adraw TRUE)))
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
         (gimp-image-add-layer img CopyLayer -1)
         (gimp-layer-set-mode CopyLayer ADDITION-MODE)
         (gimp-layer-set-opacity CopyLayer shadowopacity)
         (gimp-image-add-layer img ShadowLayer -1)
         (gimp-desaturate ShadowLayer)
         (gimp-invert ShadowLayer)
         (let* ((CopyMask (car (gimp-layer-create-mask CopyLayer ADD-WHITE-MASK)))
                (ShadowMask (car (gimp-layer-create-mask ShadowLayer ADD-WHITE-MASK)))
                )
           (gimp-layer-add-mask CopyLayer CopyMask)
           (gimp-layer-add-mask ShadowLayer ShadowMask)
           (gimp-selection-all img)
           (gimp-edit-copy ShadowLayer)
           (gimp-floating-sel-anchor (car (gimp-edit-paste CopyMask TRUE)))
           (gimp-floating-sel-anchor (car (gimp-edit-paste ShadowMask TRUE)))
           )
         (gimp-layer-set-mode ShadowLayer OVERLAY-MODE)
         (gimp-layer-set-opacity ShadowLayer shadowopacity)
         (gimp-image-remove-layer img CopyLayer)
         (gimp-drawable-set-name ShadowLayer "Shadow Recovery")
         )
       )
    
    ;smart sharpen from here: http://registry.gimp.org/node/108
    (if(> sharpness 0)
       (begin
         (gimp-image-add-layer img SharpenLayer -1)
         (gimp-selection-all HSVImage)
         (gimp-edit-copy (aref HSVLayer 0))
         (gimp-image-delete HSVImage)
         (gimp-floating-sel-anchor (car (gimp-edit-paste SharpenLayer FALSE)))
         (gimp-layer-set-mode SharpenLayer VALUE-MODE)
         (plug-in-edge TRUE MaskImage (aref MaskLayer 0) 6 1 0)
         (gimp-levels-stretch (aref MaskLayer 0))
         (gimp-image-convert-grayscale MaskImage)
         (plug-in-gauss TRUE MaskImage (aref MaskLayer 0) 6 6 TRUE)
         (let* ((SharpenChannel (car (gimp-layer-create-mask SharpenLayer ADD-WHITE-MASK)))
                )
           (gimp-layer-add-mask SharpenLayer SharpenChannel)
           (gimp-selection-all MaskImage)
           (gimp-edit-copy (aref MaskLayer 0))
           (gimp-floating-sel-anchor (car (gimp-edit-paste SharpenChannel FALSE)))
           (gimp-image-delete MaskImage)
           (plug-in-unsharp-mask TRUE img SharpenLayer 1 sharpness 0)
           (gimp-layer-set-opacity SharpenLayer 80)
           (gimp-layer-set-edit-mask SharpenLayer FALSE)
           )
         (gimp-drawable-set-name SharpenLayer "Sharpen")
         )
       )
    
    ;enhance local contrast
    (if(> localcontrast 0)
       (begin
         (gimp-edit-copy-visible img)
         (set! tmplayer1 (car (gimp-layer-new-from-visible img img "Temp 1")))
         (set! tmplayer2 (car (gimp-layer-new-from-visible img img "Temp 2")))
         (gimp-image-add-layer img tmplayer1 -1)
         (gimp-image-add-layer img tmplayer2 -1)
         (plug-in-unsharp-mask 1 img tmplayer1 60 localcontrast 0)
         (gimp-layer-set-mode tmplayer2 GRAIN-EXTRACT-MODE)
         (gimp-edit-copy-visible img)
         (set! contrastlayer (car (gimp-layer-new-from-visible img img "Local Contrast")))
         (gimp-image-add-layer img contrastlayer -1)
         (gimp-layer-set-mode contrastlayer GRAIN-MERGE-MODE)
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
    (gimp-image-add-layer img screenlayer -1)
    (gimp-image-add-layer img overlaylayer -1)
    (gimp-image-add-layer img overlaylayer2 -1)
    
    ;desaturate layers
    (gimp-desaturate screenlayer)
    (gimp-desaturate overlaylayer)  
    (gimp-desaturate overlaylayer2)  
    
    ;set modes 
    (gimp-layer-set-mode screenlayer SCREEN-MODE)
    (gimp-layer-set-mode overlaylayer OVERLAY-MODE)
    (gimp-layer-set-mode overlaylayer2 OVERLAY-MODE)
    (gimp-layer-set-opacity screenlayer screenopacity)
    (gimp-layer-set-opacity overlaylayer overlayopacity)
    (gimp-layer-set-opacity overlaylayer2 overlayopacity)
    
    ;layermask for the screen layer
    (if(= screenmask TRUE)
       (begin
         (set! floatingsel (car (gimp-layer-create-mask screenlayer 5)))
         (gimp-layer-add-mask screenlayer floatingsel)
         (gimp-invert floatingsel)
         )
       )
    
    ;overlay tint
    ;red
    (if(= tint 1)
       (begin
         (gimp-colorize screenlayer   0 25 0)
         (gimp-colorize overlaylayer  0 25 0)
         (gimp-colorize overlaylayer2 0 25 0)
         )
       )
    ;blue
    (if(= tint 2)
       (begin
         (gimp-colorize screenlayer   225 25 0)
         (gimp-colorize overlaylayer  225 25 0)
         (gimp-colorize overlaylayer2 225 25 0)
         )
       )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
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
