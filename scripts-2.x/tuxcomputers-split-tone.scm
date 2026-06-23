; Split Tone is a script for The GIMP
;
; This script converts an image to one that has one colour for highlights
; and one for shadows.
;
; The script is located in "<Image> / Script-Fu / Colours / Split Tone..."
;
; Last changed: 13th October 2008
;
; Copyright (C) 2007 Harry Phillips <script-fu@tux.com.au>
;
; --------------------------------------------------------------------
; 
; Changelog:
;  Version 1.10 (13th October 2008)
;    - Some fixes by elsamuko <elsamuko@web.de>
;
;  Version 1.9 (12th September 2008)
;    - Optional edge detection by elsamuko <elsamuko@web.de>
;
;  Version 1.8 (8th August 2007)
;    - Removed redundant code by designing a single function that does all
;      the actions
;
;  Version 1.7 (5th August 2007)
;    - Added GPLv3 licence 
;    - Menu location at the top of the script
;    - Removed the "script-fu-menu-register" section
;
;  Version 1.6
;    - Made the script compatible with GIMP 2.3
;
; --------------------------------------------------------------------
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
; along with this program; if not, you can view the GNU General Public
; License version 3 at the web site http://www.gnu.org/licenses/gpl-3.0.html
; Alternatively you can write to the Free Software Foundation, Inc., 675 Mass
; Ave, Cambridge, MA 02139, USA.
;
;
;

(define (tuxcomputers-split-tone theImage theLayer
                                 highColour highOpacity
                                 shadColour shadOpacity
                                 edgeDetection)
  (let*( (layerEdgeDetect (car (gimp-layer-copy theLayer FALSE)))
         ;Read the current colours
         (myBackground (car (gimp-context-get-background)))
         ;Read the image width and height
         (imageWidth (car (gimp-image-width theImage)))
         (imageHeight (car (gimp-image-height theImage)))
         )
    
    ;define helper function    
    (define (layer-colour-add image layer layermask
                              name width height
                              colour opacity
                              invertMask)
      (let* ((layerCopy (car (gimp-layer-copy layer 1)))
             (newLayer (car (gimp-layer-new image width height 1 "Overlay" 100 5)))
             (mergedLayer 0)
             (mask 0)
             )
        ;main layer
        (gimp-context-set-background colour)
        (gimp-image-insert-layer image layerCopy 0 0)
        (gimp-item-set-name layerCopy name)
        
        ;overlay layer
        (gimp-image-insert-layer image newLayer 0 0)
        (gimp-layer-set-mode newLayer 5)
        (gimp-edit-fill newLayer 1)
        (set! mergedLayer (car (gimp-image-merge-down image newLayer 0)))
        
        ;Add a layer mask
        (set! mask (car (gimp-layer-create-mask layermask 5)))
        (gimp-layer-add-mask mergedLayer mask)
        (if (= invertMask TRUE) (gimp-invert mask))
        
        ;Change the merged layers opacity
        (gimp-layer-set-opacity mergedLayer opacity)
        )
      ) ;end of layer-colour-add 
    
    ;init
    (gimp-image-undo-group-start theImage)
    (gimp-selection-none theImage)
    (if (= (car (gimp-drawable-is-gray theLayer )) TRUE)
        (gimp-image-convert-rgb theImage)
        )
    
    ;Edge Detection
    (if (= edgeDetection TRUE)
        (begin
          (gimp-image-insert-layer theImage layerEdgeDetect 0 1)
          (plug-in-edge 1 theImage layerEdgeDetect 2.0 1 0)
          )
        )
    
    ;Desaturate the layer
    (gimp-desaturate theLayer)
    
    ;Add the shadows layer
    (layer-colour-add theImage theLayer layerEdgeDetect
                      "Shadows"
                      imageWidth imageHeight
                      shadColour shadOpacity
                      TRUE)
    
    ;Add the highlights layer
    (layer-colour-add theImage theLayer layerEdgeDetect
                      "Highlights"
                      imageWidth imageHeight
                      highColour highOpacity
                      FALSE)
    
    ;tidy up
    (gimp-image-undo-group-end theImage)
    (gimp-context-set-background myBackground)
    (gimp-displays-flush)
    )
  )

(script-fu-register "tuxcomputers-split-tone"
                    _"_Split Tone with ED"
                    "Turns a B&W image into a split tone image"
                    "Harry Phillips"
                    "Harry Phillips"
                    "Feb. 03 2006"
                    "*"
                    SF-IMAGE        "Image"     0
                    SF-DRAWABLE     "Drawable"  0
                    SF-COLOR        _"Highlight colour"  '(255 144 0)
                    SF-ADJUSTMENT   _"Highlight opacity" '(100 0 100 1 1 0 0)
                    SF-COLOR        _"Shadows colour"    '(0 204 255)
                    SF-ADJUSTMENT   _"Shadow opacity"    '(100 0 100 1 1 0 0)
                    SF-TOGGLE       _"Edge Detection"     FALSE
                    )

(script-fu-menu-register "tuxcomputers-split-tone" _"<Image>/Script-Fu/Color")
