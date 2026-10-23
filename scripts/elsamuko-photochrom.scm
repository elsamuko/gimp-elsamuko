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
; This is the batch version of the photochrom script, run it with
; gimp -i -b '(elsamuko-photochrom-batch "picture.jpg" (list 255 128 0) (list 255 68 112) 60 60 0 100 FALSE FALSE)' -b '(gimp-quit 0)'
; or for more than one picture
; gimp -i -b '(elsamuko-photochrom-batch "*.jpg" (list 255 128 0) (list 255 68 112) 60 60 0 100 FALSE FALSE)' -b '(gimp-quit 0)'


(define (elsamuko-photochrom aimg adraw
                             color1 color2
                             contrast bw-merge
                             num1 num2
                             dodge retro)
  (let* ((img (car (gimp-item-get-image adraw)))
         (owidth (car (gimp-image-get-width img)))
         (oheight (car (gimp-image-get-height img)))
         (offset1 (* oheight (/ num1 100)))
         (offset2 (* oheight (/ num2 100)))
         (dodge-layer (car (gimp-layer-copy adraw)))
         (contrast-layer1 (car (gimp-layer-copy adraw)))
         (contrast-layer2 (car (gimp-layer-copy adraw)))
         (bw-screen-layer (car (gimp-layer-copy adraw)))         
         (bw-merge-layer (car (gimp-layer-copy adraw)))         
         (lum-layer     (car (gimp-layer-copy adraw)))
         (extra-layer  0)
         (merge-layer (car (gimp-layer-new img
                                           "Grain Merge"
                                           owidth 
                                           oheight
                                           RGBA-IMAGE
                                           50 
                                           LAYER-MODE-GRAIN-MERGE-LEGACY)))
         (merge-mask (car (gimp-layer-create-mask merge-layer ADD-MASK-WHITE)))
         (screen-layer (car (gimp-layer-new img
                                            "Screen"
                                            owidth 
                                            oheight
                                            RGBA-IMAGE
                                            10 
                                            LAYER-MODE-SCREEN-LEGACY)))
         (screen-mask (car (gimp-layer-create-mask screen-layer ADD-MASK-WHITE)))
         (multiply-layer (car (gimp-layer-new img
                                              "Multiply"
                                              owidth 
                                              oheight
                                              RGBA-IMAGE
                                              10 
                                              LAYER-MODE-MULTIPLY-LEGACY)))
         (multiply-mask (car (gimp-layer-create-mask multiply-layer ADD-MASK-WHITE)))
         (retro-layer (car (gimp-layer-new img
                                           "Retro 1"
                                           owidth 
                                           oheight
                                           RGBA-IMAGE
                                           60 
                                           LAYER-MODE-MULTIPLY-LEGACY)))
         (floatingsel 0)
         (retro-mask (car (gimp-layer-create-mask retro-layer ADD-MASK-WHITE)))
         (retro-layer2 (car (gimp-layer-new img
                                            "Retro 2"
                                            owidth 
                                            oheight
                                            RGBA-IMAGE
                                            20 
                                            LAYER-MODE-SCREEN-LEGACY)))
         (gradient-layer (car (gimp-layer-new img
                                              "Gradient Overlay"
                                              owidth 
                                              oheight
                                              RGBA-IMAGE
                                              100 
                                              LAYER-MODE-OVERLAY-LEGACY)))
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    ;set extra color layer
    (gimp-image-insert-layer img lum-layer -1 0)
    (gimp-item-set-name lum-layer "Luminosity")
    (gimp-drawable-desaturate lum-layer DESATURATE-LIGHTNESS)
    (gimp-layer-set-mode lum-layer LAYER-MODE-GRAIN-EXTRACT-LEGACY)
    (gimp-edit-copy-visible img)
    (set! extra-layer (car (gimp-layer-new-from-visible img img "Extra Color")))
    (gimp-image-insert-layer img extra-layer -1 0)
    (gimp-layer-set-mode extra-layer LAYER-MODE-GRAIN-MERGE-LEGACY)
    (gimp-layer-set-opacity extra-layer 50)
    (gimp-item-set-visible lum-layer FALSE)
    
    ;set BW screen layer
    (gimp-image-insert-layer img bw-screen-layer -1 -1)
    (gimp-item-set-name bw-screen-layer "BW Screen")
    (gimp-layer-set-mode bw-screen-layer LAYER-MODE-SCREEN-LEGACY)
    (gimp-layer-set-opacity bw-screen-layer 50)
    (gimp-drawable-desaturate bw-screen-layer DESATURATE-LUMA)
    
    ;set BW merge layer
    (gimp-image-insert-layer img bw-merge-layer -1 -1)
    (gimp-item-set-name bw-merge-layer "BW Merge")
    (gimp-layer-set-mode bw-merge-layer LAYER-MODE-GRAIN-MERGE-LEGACY)
    (gimp-layer-set-opacity bw-merge-layer bw-merge)
    (gimp-drawable-desaturate bw-merge-layer DESATURATE-LUMA)
    (gimp-drawable-curves-spline bw-merge-layer HISTOGRAM-VALUE #(0 0.5647058823529412 0.34509803921568627 0.16470588235294117 1 1))
    
    ;set contrast layers
    (gimp-image-insert-layer img contrast-layer1 -1 -1)
    (gimp-item-set-name contrast-layer1 "Contrast1")
    (gimp-layer-set-mode contrast-layer1 LAYER-MODE-OVERLAY-LEGACY)
    (gimp-layer-set-opacity contrast-layer1 contrast)
    (gimp-drawable-desaturate contrast-layer1 DESATURATE-LUMA)
    
    (gimp-image-insert-layer img contrast-layer2 -1 -1)
    (gimp-item-set-name contrast-layer2 "Contrast2")
    (gimp-layer-set-mode contrast-layer2 LAYER-MODE-OVERLAY-LEGACY)
    (gimp-layer-set-opacity contrast-layer2 contrast)
    (gimp-drawable-desaturate contrast-layer2 DESATURATE-LUMA)
    
    ;set dodge layer
    (gimp-image-insert-layer img dodge-layer -1 -1)
    (gimp-item-set-name dodge-layer "Dodge")
    (gimp-layer-set-mode dodge-layer LAYER-MODE-DODGE-LEGACY)
    (gimp-layer-set-opacity dodge-layer 50)
    
    ;set merge layer
    (gimp-image-insert-layer img merge-layer -1 -1)
    (gimp-selection-all aimg)
    (gimp-context-set-foreground color1)
    (gimp-drawable-edit-fill merge-layer FILL-FOREGROUND)
    (gimp-layer-add-mask merge-layer merge-mask)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-context-set-background '(0 0 0))
    (begin (gimp-context-set-gradient-fg-bg-rgb) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse TRUE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill merge-mask GRADIENT-LINEAR 0 FALSE 1 0 TRUE 0 offset1 0 offset2))
    
    ;set screen layer
    (gimp-image-insert-layer img screen-layer -1 -1)
    (gimp-selection-all aimg)
    (gimp-context-set-foreground color1)
    (gimp-drawable-edit-fill screen-layer FILL-FOREGROUND)
    (gimp-layer-add-mask screen-layer screen-mask)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-context-set-background '(0 0 0))
    (begin (gimp-context-set-gradient-fg-bg-rgb) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse TRUE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill screen-mask GRADIENT-LINEAR 0 FALSE 1 0 TRUE 0 offset1 0 offset2))
    
    ;set multiply layer
    (gimp-image-insert-layer img multiply-layer -1 -1)
    (gimp-selection-all aimg)
    (gimp-context-set-foreground color2)
    (gimp-drawable-edit-fill multiply-layer FILL-FOREGROUND)
    (gimp-layer-add-mask multiply-layer multiply-mask)
    (gimp-context-set-foreground '(255 255 255))
    (gimp-context-set-background '(0 0 0))
    (begin (gimp-context-set-gradient-fg-bg-rgb) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse TRUE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill multiply-mask GRADIENT-LINEAR 0 FALSE 1 0 TRUE 0 offset1 0 offset2))
    
    ;optional retro colors
    (if(= retro TRUE)(begin
                       ;yellow with mask
                       (gimp-image-insert-layer img retro-layer -1 -1)
                       (gimp-selection-all aimg)
                       (gimp-context-set-foreground '(251 242 163))
                       (gimp-drawable-edit-fill retro-layer FILL-FOREGROUND)
                       (gimp-layer-add-mask retro-layer retro-mask)
                       (gimp-edit-copy (vector contrast-layer1))
                       (set! floatingsel (vector-ref (car (gimp-edit-paste retro-mask TRUE)) 0))
                       (gimp-floating-sel-anchor floatingsel)
                       
                       ;rose
                       (gimp-image-insert-layer img retro-layer2 -1 -1)
                       (gimp-selection-all aimg)
                       (gimp-context-set-foreground '(232 101 179))
                       (gimp-drawable-edit-fill retro-layer2 FILL-FOREGROUND)
                       
                       ;gradient overlay
                       (gimp-image-insert-layer img gradient-layer -1 -1)
                       (gimp-context-set-foreground '(255 255 255))
                       (gimp-context-set-background '(0 0 0))
                       (begin (gimp-context-set-gradient-fg-bg-rgb) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse FALSE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill gradient-layer GRADIENT-LINEAR 0 FALSE 1 0 TRUE 0 offset1 0 offset2))
                       
                       ;deactivate orange layers
                       (gimp-item-set-visible merge-layer FALSE)
                       (gimp-item-set-visible screen-layer FALSE)
                       (gimp-item-set-visible multiply-layer FALSE)
                       )
       )
    
    ;dodge b/w
    (if(= dodge TRUE)(begin
                       (gimp-drawable-desaturate dodge-layer DESATURATE-LUMA)
                       (gimp-item-set-visible extra-layer FALSE)
                       )
       )
    
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(define (elsamuko-photochrom-batch pattern
                                   color1 color2
                                   contrast bw-merge
                                   num1 num2
                                   dodge retro)
  (gimp-message (string-append "Pattern: " pattern))
  (let* ((filelist (car (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
                  (fileparts (strbreakup filename "."))
                  (img (car (gimp-file-load RUN-NONINTERACTIVE filename)))
                  (adraw (vector-ref (car (gimp-image-get-selected-drawables img)) 0))
                  )
             (gimp-message (string-append "Filename: " filename))

             (gimp-message "Calling elsamuko-photochrom")
             (elsamuko-photochrom img adraw
                                  color1 color2
                                  contrast bw-merge
                                  num1 num2
                                  dodge retro)

             (gimp-image-merge-visible-layers img EXPAND-AS-NECESSARY)
             (set! adraw (vector-ref (car (gimp-image-get-selected-drawables img)) 0))

             (gimp-message "Saving")
             (gimp-file-save RUN-NONINTERACTIVE img filename -1)
             (gimp-image-delete img)
             (set! filelist (cdr filelist))
             )
           )
    )
  )

(script-fu-register "elsamuko-photochrom"
                    "_Photochrom"
                    "Photochrom effect from 1890."
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "26/02/10"
                    "RGB*"
                    SF-IMAGE       "Input image"          0
                    SF-DRAWABLE    "Input drawable"       0
                    SF-COLOR       "Screen & Grain Merge"  '(255 128 0)
                    SF-COLOR       "Multiply"              '(255 68 112)
                    SF-ADJUSTMENT  "Contrast"              '(60  0 100 1 10 0 0)
                    SF-ADJUSTMENT  "B/W Merging"           '(60  0 100 1 10 0 0)
                    SF-ADJUSTMENT  "Gradient Begin Offset" '(0 -100 200 1 10 0 0)
                    SF-ADJUSTMENT  "Gradient End Offset"   '(100 -100 200 1 10 0 0)
                    SF-TOGGLE      "B/W Dodging"            FALSE
                    SF-TOGGLE      "Retro"                  FALSE
                    )

(script-fu-menu-register "elsamuko-photochrom" _"<Image>/Filters/Artistic")
