#!/usr/bin/env gimp-script-fu-interpreter-3.0

; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
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
;
; Copyright (C) 2005 Francois Le Lay <mfworx@gmail.com>
;
; Version 0.3 - Changed terminology, settings made more user-friendly
; Version 0.2 - Now using radial blending all-way
; Version 0.1 - Rectangular Selection Feathering doesn't look too good
; 
;
; Usage: 
;
; - Vignetting softness: The vignette layer is scaled with a 
;   default size equal to 1.5 the image size. Setting it to 2
;   will make the vignetting softer and going to 1 will make
;   the vignette layer the same size as the image, providing
;   for darker blending in the corners.
;
; - Saturation and contrast have default values set to 20 and act 
;   on the base layer.
;
; - Double vignetting: when checked this will duplicate the Vignette 
;   layer providing for a stronger vignetting effect.
;
;
; October 23, 2007
; Script made GIMP 2.4 compatible by Donncha O Caoimh, donncha@inphotos.org
; Download at http://inphotos.org/gimp-lomo-plugin/
;
; Updated by elsamuko <elsamuko@web.de>
; http://registry.gimp.org/node/7870
;
; The batch call is included, run it with
; gimp -i -b '(elsamuko-lomo-batch "picture.jpg" 1.5 10 10 0.8 5 1 3 128 COLOR FALSE FALSE TRUE FALSE 0 0 115)' -b '(gimp-quit 0)'
; or for more than one picture
; gimp -i -b '(elsamuko-lomo-batch "*.jpg" 1.5 10 10 0.8 5 1 3 128 COLOR FALSE FALSE TRUE FALSE 0 0 115)' -b '(gimp-quit 0)'
;
; set as COLOR:
; 0 - neutral
; 1 - old red
; 2 - xpro green
; 3 - blue
; 4 - intense red
; 5 - movie
; 6 - vintage-look
; 7 - LAB
; 8 - light blue
; 9 - pink shadow
; 10 - redscale
; 11 - retro bw
; 12 - paynes
; 13 - sepia
;

(define (elsamuko-lomo aimg adraw avig asat acon
                       sharp wide_angle gauss_blur
                       motion_blur grain c41 
                       invertA invertB
                       adv is_black
                       centerx centery aradius)
  (let* ( (img (car (gimp-item-get-image adraw)))
          (draw (car (gimp-layer-copy adraw)))
          (owidth (car (gimp-image-get-width img)))
          (oheight (car (gimp-image-get-height img)))
          (halfwidth (/ owidth 2))
          (halfheight (/ oheight 2))
          (endingx 0)
          (endingy 0)
          (blend_x 0)
          (blend_y 0)
          
          (imgLAB 0)
          (layersLAB 0)
          (layerA 0)
          (layerB 0)
          (drawA 0)
          (drawB 0)
          
          (MaskImage 0)
          (MaskLayer 0)
          (OrigLayer 0)
          (HSVImage 0)
          (HSVLayer 0)
          (SharpenLayer 0)
          (Visible 0)
          
          (cyan-layer 0)
          (magenta-layer 0)
          (yellow-layer 0)
          (blue-layer 0)
          (blue-layer-mask 0)
          
          (amiddle (/ (+ owidth oheight) 2))
          (multi (/ aradius 100))
          (radius (* multi amiddle))
          (x_black (+ (- halfwidth  (* multi (/ amiddle 2))) (* owidth (/ centerx 100))))
          (y_black (- (- halfheight (* multi (/ amiddle 2))) (* oheight (/ centery 100))))
          (vignette (car (gimp-layer-new img
                                         "Vignette"
                                         owidth
                                         oheight
                                         1
                                         100 
                                         LAYER-MODE-OVERLAY-LEGACY)))
          (hvignette (car (gimp-layer-new img
                                          "Vignette"
                                          owidth
                                          oheight
                                          1
                                          100
                                          LAYER-MODE-OVERLAY-LEGACY)))
          (overexpo (car (gimp-layer-new img
                                         "Over Exposure" 
                                         owidth
                                         oheight
                                         1
                                         80 
                                         LAYER-MODE-OVERLAY-LEGACY)))
          (black_vignette (car (gimp-layer-new img
                                               "Black Vignette" 
                                               owidth
                                               oheight
                                               1
                                               100 
                                               LAYER-MODE-NORMAL-LEGACY)))
          (grain-layer (car (gimp-layer-new img
                                            "Grain" 
                                            owidth
                                            oheight
                                            1
                                            100 
                                            LAYER-MODE-OVERLAY-LEGACY)))
          (grain-layer-mask (car (gimp-layer-create-mask grain-layer ADD-MASK-WHITE)))
          )
    
    ; init
    (set! blend_x (+ halfwidth  (* owidth  (/ centerx 100))))
    (set! blend_y (- halfheight (* oheight (/ centery 100))))
    
    (define (set-pt a index x y)
      (begin
        (vector-set! a (* index 2) (/ x 255.0))
        (vector-set! a (+ (* index 2) 1) (/ y 255.0))
        )
      )
    (define (splineValue)
      (let* ((a (make-vector 6 0.0)))
        (set-pt a 0 0 0)
        (set-pt a 1 128 grain)
        (set-pt a 2 255 0)
        a
        )
      )
    
    ;(gimp-message (number->string (car (gimp-drawable-is-gray adraw ))))
    (if (= (car (gimp-drawable-is-gray adraw )) TRUE)
        (gimp-image-convert-rgb img)
        )
    
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (gimp-context-set-foreground '(0 0 0))
    (gimp-context-set-background '(255 255 255))
    (gimp-image-insert-layer img draw -1 -1)
    (gimp-item-set-name draw "Process Copy")
    
    ; adjust contrast, saturation 
    (gimp-drawable-brightness-contrast draw 0 (/ acon 127.0))
    (gimp-drawable-hue-saturation draw HUE-RANGE-ALL 0 0 asat 0)
    
    ;wide angle lens distortion
    (if (> wide_angle 0) 
        (gimp-drawable-merge-new-filter draw "gegl:lens-distortion" "" LAYER-MODE-REPLACE 1.0 "x-shift" 0 "y-shift" 0 "main" wide_angle "edge" 0 "zoom" 9 "brighten" 0 "background" (car (gimp-context-get-background)))
        )
    
    ;gauss blur as general focusing error
    (if (> gauss_blur 0)
        (gimp-drawable-merge-new-filter draw "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* gauss_blur 0.32) "std-dev-y" (* gauss_blur 0.32) "abyss-policy" "clamp")
        )
    
    ;motion blur as corner fuzziness
    (if (> motion_blur 0)
        (gimp-drawable-merge-new-filter draw "gegl:motion-blur-zoom" "" LAYER-MODE-REPLACE 1.0 "factor" (/ motion_blur 256.0) "center-x" (/ blend_x owidth) "center-y" (/ blend_y oheight))
        )
    
    ;add c41-effect
    ;old red from djinn (http://registry.gimp.org/node/4683)
    (if(= c41 1)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-VALUE  #(0 0 0.26666666666666666 0.25098039215686274 0.74509803921568629 0.85882352941176465 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-RED    #(0 0 0.15294117647058825 0.36470588235294116 0.75686274509803919 0.57647058823529407 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0 0 0.26666666666666666 0.27450980392156865 1 0.81176470588235294))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-BLUE   #(0 0 0.36862745098039218 0.36862745098039218 1 0.7803921568627451))
                  )
       )
    
    ;xpro green from lilahpops (http://www.lilahpops.com/cross-processing-with-the-gimp/)
    (if(= c41 2)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-RED   #(0 0 0.31372549019607843 0.32941176470588235 0.58431372549019611 0.75294117647058822 0.74901960784313726 0.97254901960784312 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0 0 0.27450980392156865 0.31764705882352939 0.62352941176470589 0.86274509803921573 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-BLUE   #(0 0.10588235294117647 1 0.83529411764705885))
                  )
       )
    
    ;blue
    (if(= c41 3)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-RED    #(0 0.24313725490196078 1 0.89803921568627454))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0 0 0.27058823529411763 0.11372549019607843 0.75686274509803919 0.94117647058823528 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-BLUE   #(0 0.10588235294117647 0.32156862745098042 0.17254901960784313 0.792156862745098 0.94509803921568625 1 1))
                  )
       )
    
    ;intense red
    (if(= c41 4)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-RED    #(0 0 0.35294117647058826 0.58823529411764708 0.94117647058823528 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0 0 0.53333333333333333 0.41960784313725491 0.94117647058823528 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-BLUE   #(0 0 0.53333333333333333 0.41960784313725491 1 0.96470588235294119))
                  )
       )
    
    ;movie (from http://tutorials.lombergar.com/achieve_the_indie_movie_look.html)
    (if(= c41 5)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-VALUE  #(0.15686274509803921 0 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-RED    #(0  0 0.49803921568627452 0.61568627450980395 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0  0.031372549019607843 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-BLUE   #(0  0 0.49803921568627452 0.41568627450980394 1 0.96078431372549022))
                  )
       )
    
    ;vintage-look script from mm1 (http://registry.gimp.org/node/1348)
    (if(= c41 6)(begin
                  ;Yellow Layer
                  (set! yellow-layer (car (gimp-layer-new img "Yellow" owidth oheight RGB-IMAGE 100  LAYER-MODE-MULTIPLY-LEGACY)))
                  (gimp-image-insert-layer img yellow-layer -1 -1)
                  (gimp-context-set-background '(251 242 163))
                  (gimp-drawable-fill yellow-layer FILL-BACKGROUND)
                  (gimp-layer-set-opacity yellow-layer 59)
                  
                  ;Magenta Layer
                  (set! magenta-layer (car (gimp-layer-new img "Magenta" owidth oheight RGB-IMAGE 100  LAYER-MODE-SCREEN-LEGACY)))
                  (gimp-image-insert-layer img magenta-layer -1 -1)
                  (gimp-context-set-background '(232 101 179))
                  (gimp-drawable-fill magenta-layer FILL-BACKGROUND)
                  (gimp-layer-set-opacity magenta-layer 20)
                  
                  ;Cyan Layer 
                  (set! cyan-layer (car (gimp-layer-new img "Cyan" owidth oheight RGB-IMAGE 100  LAYER-MODE-SCREEN-LEGACY)))
                  (gimp-image-insert-layer img cyan-layer -1 -1)
                  (gimp-context-set-background '(9 73 233))
                  (gimp-drawable-fill cyan-layer FILL-BACKGROUND)
                  (gimp-layer-set-opacity cyan-layer 17)
                  )
       )
    
    ;LAB from Martin Evening (http://www.photoshopforphotographers.com/pscs2/download/movie-06.pdf)
    (if(= c41 7)(begin
                  (set! drawA  (car (gimp-layer-copy draw)))
                  (set! drawB (car (gimp-layer-copy draw)))
                  (gimp-image-insert-layer img drawA -1 -1)
                  (gimp-image-insert-layer img drawB -1 -1)
                  
                  (gimp-item-set-name drawA "LAB-A")
                  (gimp-item-set-name drawB "LAB-B")
                  
                  ;decompose image to LAB and stretch A and B
                  (set! imgLAB (car (plug-in-decompose RUN-NONINTERACTIVE img (vector drawA) "lab" TRUE FALSE)))
                  (set! layersLAB (gimp-image-get-layers imgLAB))
                  (set! layerA (vector-ref (car layersLAB) 1))
                  (gimp-drawable-levels-stretch layerA)
                  (plug-in-recompose RUN-NONINTERACTIVE imgLAB (vector layerA))
                  
                  (set! imgLAB (car (plug-in-decompose RUN-NONINTERACTIVE img (vector drawB) "lab" TRUE FALSE)))
                  (set! layersLAB (gimp-image-get-layers imgLAB))
                  (set! layerB (vector-ref (car layersLAB) 2))
                  (gimp-drawable-levels-stretch layerB)
                  (plug-in-recompose RUN-NONINTERACTIVE imgLAB (vector layerB))
                  
                  (gimp-image-delete imgLAB)
                  
                  ;set mode to color mode
                  (gimp-layer-set-mode drawA LAYER-MODE-HSL-COLOR-LEGACY)
                  (gimp-layer-set-mode drawB LAYER-MODE-HSL-COLOR-LEGACY)
                  (gimp-layer-set-opacity drawA 40)
                  (gimp-layer-set-opacity drawB 40)
                  
                  ;blur
                  (gimp-drawable-merge-new-filter drawA "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* 2.5 0.32) "std-dev-y" (* 2.5 0.32) "abyss-policy" "clamp")
                  (gimp-drawable-merge-new-filter drawB "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* 2.5 0.32) "std-dev-y" (* 2.5 0.32) "abyss-policy" "clamp")
                  )
       )
    
    ;light blue
    (if(= c41 8)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-RED    #(0 0 0.60392156862745094 0.55294117647058827 0.90980392156862744 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0 0 0.25490196078431371 0.18823529411764706 0.792156862745098 0.84313725490196079 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0 0.082352941176470587 1 1))
                  (gimp-drawable-curves-spline draw  HISTOGRAM-BLUE   #(0 0 0.26666666666666666 0.34901960784313724 0.63529411764705879 0.80784313725490198 0.91764705882352937 1))
                  (gimp-drawable-levels draw HISTOGRAM-VALUE
                                        (/ 25 255.0) 1.0 TRUE ;input
                                        1.25   ;gamma
                                        0.0 1.0 TRUE) ;output
                  )
       )
    
    ;pink shadow
    (if(= c41 9)(begin
                  (gimp-drawable-curves-spline draw  HISTOGRAM-GREEN  #(0.11764705882352941 0 1 1))
                  )
       )
    
    ;redscale
    (if(= c41 10)(begin
                   ;Blue Layer
                   (set! blue-layer (car (gimp-layer-copy draw))) (gimp-layer-add-alpha blue-layer)
                   (gimp-image-insert-layer img blue-layer -1 -1)
                   (gimp-item-set-name blue-layer "Blue Filter")
                   (gimp-layer-set-opacity blue-layer 40)
                   (gimp-layer-set-mode blue-layer LAYER-MODE-SCREEN-LEGACY)
                   (gimp-drawable-merge-new-filter blue-layer "gegl:mono-mixer" "" LAYER-MODE-REPLACE 1.0
                                                   "red" 0 ;R
                                                   "green" 0 ;G
                                                   "blue" 1 ;B
                                                   )
                   (set! blue-layer-mask (car (gimp-layer-create-mask blue-layer ADD-MASK-COPY)))
                   (gimp-layer-add-mask blue-layer blue-layer-mask)
                   
                   (gimp-context-set-background '(0 0 255))
                   (gimp-drawable-fill blue-layer FILL-BACKGROUND)
                   
                   (gimp-drawable-curves-spline draw HISTOGRAM-RED    #(0 0 0.49803921568627452 0.74509803921568629 1 1))
                   (gimp-drawable-curves-spline draw HISTOGRAM-GREEN  #(0 0 0.49803921568627452  0.24313725490196078 0.94117647058823528 1))
                   (gimp-drawable-curves-spline draw HISTOGRAM-BLUE   #(0 0 1 0))
                   )
       )
    
    ;retro bw
    (if(= c41 11)(begin
                   (gimp-drawable-desaturate draw DESATURATE-LUMA)
                   ;(gimp-curves-spline draw HISTOGRAM-RED   4 #(0 15 255 255))
                   (gimp-drawable-curves-spline draw HISTOGRAM-BLUE   #(0 0 1 0.90196078431372551))
                   (gimp-drawable-curves-spline draw HISTOGRAM-VALUE  #(0 0 0.24705882352941178 0.20392156862745098 0.74901960784313726 0.792156862745098 1 1))
                   )
       )
    
    ;paynes bw
    (if(= c41 12)(begin
                   (gimp-drawable-desaturate draw DESATURATE-LUMA)
                   (gimp-drawable-colorize-hsl draw 215 11 0)
                   )
       )
    
    ;sepia
    (if(= c41 13)(begin
                   (gimp-drawable-desaturate draw DESATURATE-LUMA)
                   (gimp-drawable-colorize-hsl draw 30 25 0)
                   )
       )
    
    ;set some funky colors
    (if( = invertA TRUE)(begin
                          (set! imgLAB (car (plug-in-decompose RUN-NONINTERACTIVE img (vector draw) "lab" TRUE FALSE)))
                          (set! layersLAB (gimp-image-get-layers imgLAB))
                          (set! layerA (vector-ref (car layersLAB) 1))
                          (gimp-drawable-invert layerA FALSE)
                          (plug-in-recompose RUN-NONINTERACTIVE imgLAB (vector layerA))
                          )
       )
    (if( = invertB TRUE)(begin
                          (set! imgLAB (car (plug-in-decompose RUN-NONINTERACTIVE img (vector draw) "lab" TRUE FALSE)))
                          (set! layersLAB (gimp-image-get-layers imgLAB))
                          (set! layerB (vector-ref (car layersLAB) 2))
                          (gimp-drawable-invert layerB FALSE)
                          (plug-in-recompose RUN-NONINTERACTIVE imgLAB (vector layerB))
                          )
       )
    
    ;add two blending layers
    (gimp-context-set-foreground '(0 0 0)) ;black
    (gimp-context-set-background '(255 255 255)) ;white
    (gimp-image-insert-layer img overexpo -1 -1)
    (gimp-image-insert-layer img vignette -1 -1)
    (gimp-drawable-fill vignette FILL-TRANSPARENT)
    (gimp-drawable-fill overexpo FILL-TRANSPARENT)
    
    ;compute blend ending point depending on image orientation
    (if (> owidth oheight) 
        (begin
          (set! endingx owidth)
          (set! endingy halfheight))
        (begin
          (set! endingx halfwidth)
          (set! endingy oheight)
          )
        )
    
    ;let's do the vignetting effect
    ;apply a reverse radial blend on layer
    ;then scale layer by "avig" factor with a local origin
    ;if double vignetting is needed, duplicate layer and set duplicate opacity to 80%
    (begin (gimp-context-set-gradient-fg-transparent) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse TRUE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill vignette GRADIENT-RADIAL 0 FALSE 1 0 TRUE blend_x blend_y endingx endingy))
    (gimp-layer-scale vignette (* owidth avig) (* oheight avig) 1)
    (gimp-drawable-merge-new-filter vignette "gegl:noise-spread" "" LAYER-MODE-REPLACE 1.0 "amount-x" 50 "amount-y" 50)
    (if (= adv TRUE) 
        ( begin 
           (set! hvignette (car (gimp-layer-copy vignette)))
           (gimp-layer-set-opacity hvignette 80)
           (gimp-image-insert-layer img hvignette -1 -1)
           (gimp-layer-resize-to-image-size hvignette)
           )
        )
    (gimp-layer-resize-to-image-size vignette)
    
    ;let's do the over-exposure effect
    ;swap foreground and background colors then
    ;apply a radial blend from center to farthest side of layer
    (gimp-context-swap-colors)
    (begin (gimp-context-set-gradient-fg-transparent) (gimp-context-set-opacity 100) (gimp-context-set-paint-mode LAYER-MODE-NORMAL-LEGACY) (gimp-context-set-gradient-repeat-mode REPEAT-NONE) (gimp-context-set-gradient-reverse FALSE) (gimp-context-set-gradient-blend-color-space GRADIENT-BLEND-RGB-PERCEPTUAL) (gimp-drawable-edit-gradient-fill overexpo GRADIENT-RADIAL 0 FALSE 1 0 TRUE blend_x blend_y endingx endingy))
    (gimp-drawable-merge-new-filter overexpo "gegl:noise-spread" "" LAYER-MODE-REPLACE 1.0 "amount-x" 50 "amount-y" 50)
    
    ;adding the black vignette
    ;selecting a feathered circle, invert selection and fill up with black
    (if (= is_black TRUE) 
        ( begin 
           (gimp-image-insert-layer img black_vignette -1 -1)
           (gimp-drawable-fill black_vignette FILL-TRANSPARENT)
           (gimp-image-select-ellipse img CHANNEL-OP-REPLACE x_black y_black radius radius)
           (gimp-selection-feather img (* radius 0.2))
           (gimp-selection-invert img)
           (gimp-context-set-foreground '(0 0 0))
           (gimp-drawable-edit-fill black_vignette FILL-FOREGROUND)
           (gimp-selection-none img)
           )
        )
    
    ;add grain
    (if (> grain 0) 
        ( begin 
           ;fill new layer with neutral gray
           (gimp-image-insert-layer img grain-layer -1 -1)
           (gimp-drawable-fill grain-layer FILL-TRANSPARENT)
           (gimp-context-set-foreground '(128 128 128))
           (gimp-selection-all img)
           (gimp-drawable-edit-fill grain-layer FILL-FOREGROUND)
           (gimp-selection-none img)
           
           ;add grain and blur it
           (gimp-drawable-merge-new-filter grain-layer "gegl:noise-hsv" "" LAYER-MODE-REPLACE 1.0 "holdness" 2 "hue-distance" 0 "saturation-distance" 0 "value-distance" (/ 100 255.0))
           (gimp-drawable-merge-new-filter grain-layer "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* 0.5 0.32) "std-dev-y" (* 0.5 0.32) "abyss-policy" "clamp")
           (gimp-layer-add-mask grain-layer grain-layer-mask)
           
           ;select the original image, copy and paste it as a layer mask into the grain layer
           (gimp-selection-all img)
           (gimp-edit-copy-visible img)
           (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste grain-layer-mask TRUE)) 0))
           
           ;set color curves of layer mask, so that only gray areas become grainy
           (gimp-drawable-curves-spline grain-layer-mask  HISTOGRAM-VALUE   (splineValue))
           )
        )
    
    ;sharpness layer
    (if(> sharp 0)
       (begin
         (if (> grain 0)(gimp-item-set-visible grain-layer FALSE))
         
         (gimp-edit-copy-visible aimg)
         (set! Visible (car (gimp-layer-new-from-visible aimg aimg "Visible")))
         (gimp-image-insert-layer aimg Visible -1 -1)
         
         (set! MaskImage (car (gimp-image-duplicate aimg)))
         (set! MaskLayer (car (gimp-image-get-layers MaskImage)))
         (set! OrigLayer (car (gimp-image-get-layers aimg)))
         (set! HSVImage (car (plug-in-decompose RUN-NONINTERACTIVE aimg (vector Visible) "hsv" TRUE FALSE)))
         (set! HSVLayer (car (gimp-image-get-layers HSVImage)))
         (set! SharpenLayer (car (gimp-layer-copy Visible))) (gimp-layer-add-alpha SharpenLayer)
         
         ;smart sharpen from here: http://registry.gimp.org/node/108
         (gimp-image-insert-layer img SharpenLayer -1 -1)
         (gimp-selection-all HSVImage)
         (gimp-edit-copy (vector (vector-ref HSVLayer 2)))
         (gimp-image-delete HSVImage)
         (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste SharpenLayer FALSE)) 0))
         (gimp-layer-set-mode SharpenLayer LAYER-MODE-HSV-VALUE-LEGACY)
         (gimp-drawable-merge-new-filter (vector-ref MaskLayer 0) "gegl:edge" "" LAYER-MODE-REPLACE 1.0 "amount" 6 "border-behavior" "loop" "algorithm" "sobel")
         (gimp-drawable-levels-stretch (vector-ref MaskLayer 0))
         (gimp-image-convert-grayscale MaskImage)
         (gimp-drawable-merge-new-filter (vector-ref MaskLayer 0) "gegl:gaussian-blur" "" LAYER-MODE-REPLACE 1.0 "std-dev-x" (* 6 0.32) "std-dev-y" (* 6 0.32) "abyss-policy" "clamp")
         (let* ((SharpenChannel (car (gimp-layer-create-mask SharpenLayer ADD-MASK-WHITE)))
                )
           (gimp-layer-add-mask SharpenLayer SharpenChannel)
           (gimp-selection-all MaskImage)
           (gimp-edit-copy (vector (vector-ref MaskLayer 0)))
           (gimp-floating-sel-anchor (vector-ref (car (gimp-edit-paste SharpenChannel FALSE)) 0))
           (gimp-image-delete MaskImage)
           (gimp-drawable-merge-new-filter SharpenLayer "gegl:unsharp-mask" "" LAYER-MODE-REPLACE 1.0 "std-dev" 1 "scale" sharp "threshold" 0)
           (gimp-layer-set-opacity SharpenLayer 80)
           (gimp-layer-set-edit-mask SharpenLayer FALSE)
           )
         (gimp-item-set-name SharpenLayer "Sharpen")
         (gimp-image-remove-layer aimg Visible)
         (if (> grain 0)
             (begin
               (gimp-item-set-visible grain-layer TRUE)
               (gimp-image-lower-item aimg SharpenLayer)
               )
             )
         )
       )
    
    ;tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )
  
(define (elsamuko-lomo-batch pattern avig asat acon
                             sharp wide_angle gauss_blur
                             motion_blur grain c41 
                             invertA invertB
                             adv is_black
                             centerx centery aradius)
  (gimp-message (string-append "Pattern: " pattern))
  (let* ((filelist (car (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
                  (fileparts (strbreakup filename "."))
                  (img (car (gimp-file-load RUN-NONINTERACTIVE filename)))
                  (adraw (vector-ref (car (gimp-image-get-selected-drawables img)) 0))
                  )
             (gimp-message (string-append "Filename: " filename))

             (gimp-message "Calling elsamuko-lomo")
             (elsamuko-lomo img adraw avig asat acon
                            sharp wide_angle gauss_blur
                            motion_blur grain c41
                            invertA invertB
                            adv is_black
                            centerx centery aradius)

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

(script-fu-register "elsamuko-lomo"
                    _"_Lomo..."
                    "Do a lomo effect on image. 
Latest version can be downloaded from http://registry.gimp.org/node/7870"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "15/02/05"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    SF-ADJUSTMENT _"Vignetting Softness"   '(1.5 1 2 0.1 0.5 1 0)
                    SF-ADJUSTMENT _"Saturation"            '(10 -40  40  1 5 1 0)
                    SF-ADJUSTMENT _"Contrast"              '(10   0  40  1 5 1 0)
                    SF-ADJUSTMENT _"Sharpness"             '(0.8 0 2 0.1 0.2 1 0)
                    SF-ADJUSTMENT _"Wide Angle Distortion" '(5 0 13 0.1 0.5 1 0)
                    SF-ADJUSTMENT _"Gauss Blur"            '(1 0  5 0.1 0.5 1 0)
                    SF-ADJUSTMENT _"Motion Blur"           '(3 0  5 0.1 0.5 1 0)
                    SF-ADJUSTMENT _"Grain"                 '(128 0 255 1 20 0 0)
                    SF-OPTION     _"Colors"                '("Neutral"
                                                             "Old Red"
                                                             "XPro Green"
                                                             "Blue"
                                                             "XPro Autumn"
                                                             "Movie"
                                                             "Vintage"
                                                             "Xpro LAB"
                                                             "Light Blue"
                                                             "Pink Shadow"
                                                             "Redscale"
                                                             "Retro B/W"
                                                             "Paynes B/W"
                                                             "Sepia")
                    SF-TOGGLE     _"Invert LAB-A"          FALSE
                    SF-TOGGLE     _"Invert LAB-B"          FALSE
                    SF-TOGGLE     _"Double Vignetting"     TRUE
                    SF-TOGGLE     _"Black Vignetting"      FALSE
                    SF-ADJUSTMENT _"	X-Shift(%)"        '(0 -50  50 1 10 0 0)
                    SF-ADJUSTMENT _"	Y-Shift(%)"        '(0 -50  50 1 10 0 0)
                    SF-ADJUSTMENT _"	Radius(%)"         '(115 0 200 1 20 0 0)
                    )

(script-fu-menu-register "elsamuko-lomo" _"<Image>/Filters/Light and Shadow")
