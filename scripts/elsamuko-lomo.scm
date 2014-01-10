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


(define (elsamuko-lomo aimg adraw avig asat acon
                       sharp wide_angle gauss_blur
                       motion_blur grain c41 
                       invertA invertB
                       adv is_black
                       centerx centery aradius)
  (let* ( (img (car (gimp-drawable-get-image adraw)))
          (draw (car (gimp-layer-copy adraw FALSE))) 
          (owidth (car (gimp-image-width img)))
          (oheight (car (gimp-image-height img)))
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
                                         owidth 
                                         oheight
                                         1
                                         "Vignette" 
                                         100 
                                         OVERLAY-MODE)))
          (hvignette (car (gimp-layer-new img
                                          owidth 
                                          oheight
                                          1
                                          "Vignette" 
                                          100 
                                          OVERLAY-MODE)))
          (overexpo (car (gimp-layer-new img
                                         owidth 
                                         oheight
                                         1
                                         "Over Exposure" 
                                         80 
                                         OVERLAY-MODE)))
          (black_vignette (car (gimp-layer-new img
                                               owidth 
                                               oheight
                                               1
                                               "Black Vignette" 
                                               100 
                                               NORMAL-MODE)))
          (grain-layer (car (gimp-layer-new img
                                            owidth 
                                            oheight
                                            1
                                            "Grain" 
                                            100 
                                            OVERLAY-MODE)))
          (grain-layer-mask (car (gimp-layer-create-mask grain-layer ADD-WHITE-MASK)))
          )
    
    ; init
    (set! blend_x (+ halfwidth  (* owidth  (/ centerx 100))))
    (set! blend_y (- halfheight (* oheight (/ centery 100))))
    
    (define (set-pt a index x y)
      (begin
        (aset a (* index 2) x)
        (aset a (+ (* index 2) 1) y)
        )
      )
    (define (splineValue)
      (let* ((a (cons-array 6 'byte)))
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
    (gimp-image-add-layer img draw -1)
    (gimp-drawable-set-name draw "Process Copy")
    
    ; adjust contrast, saturation 
    (gimp-brightness-contrast draw 0 acon)
    (gimp-hue-saturation draw ALL-HUES 0 0 asat)
    
    ;wide angle lens distortion
    (if (> wide_angle 0) 
        (plug-in-lens-distortion 1 img draw 0 0 wide_angle 0 9 0)
        )
    
    ;gauss blur as general focusing error
    (if (> gauss_blur 0)
        (plug-in-gauss TRUE aimg draw gauss_blur gauss_blur TRUE)
        )
    
    ;motion blur as corner fuzziness
    (if (> motion_blur 0)
        (plug-in-mblur 1 img draw 2 motion_blur 0 blend_x blend_y)
        )
    
    ;add c41-effect
    ;old red from djinn (http://registry.gimp.org/node/4683)
    (if(= c41 1)(begin
                  (gimp-curves-spline draw  HISTOGRAM-VALUE 8 #(0 0 68 64 190 219 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-RED   8 #(0 0 39 93 193 147 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 6 #(0 0 68 70 255 207))
                  (gimp-curves-spline draw  HISTOGRAM-BLUE  6 #(0 0 94 94 255 199))
                  )
       )
    
    ;xpro green from lilahpops (http://www.lilahpops.com/cross-processing-with-the-gimp/)
    (if(= c41 2)(begin
                  (gimp-curves-spline draw  HISTOGRAM-RED  10 #(0 0 80 84 149 192 191 248 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 8 #(0 0 70 81 159 220 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-BLUE  4 #(0 27 255 213))
                  )
       )
    
    ;blue
    (if(= c41 3)(begin
                  (gimp-curves-spline draw  HISTOGRAM-RED   4 #(0 62 255 229))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 8 #(0 0 69 29 193 240 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-BLUE  8 #(0 27 82 44 202 241 255 255))
                  )
       )
    
    ;intense red
    (if(= c41 4)(begin
                  (gimp-curves-spline draw  HISTOGRAM-RED   6 #(0 0 90 150 240 255))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 6 #(0 0 136 107 240 255))
                  (gimp-curves-spline draw  HISTOGRAM-BLUE  6 #(0 0 136 107 255 246))
                  )
       )
    
    ;movie (from http://tutorials.lombergar.com/achieve_the_indie_movie_look.html)
    (if(= c41 5)(begin
                  (gimp-curves-spline draw  HISTOGRAM-VALUE 4 #(40 0 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-RED   6 #(0  0 127 157 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 4 #(0  8 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-BLUE  6 #(0  0 127 106 255 245))
                  )
       )
    
    ;vintage-look script from mm1 (http://registry.gimp.org/node/1348)
    (if(= c41 6)(begin
                  ;Yellow Layer
                  (set! yellow-layer (car (gimp-layer-new img owidth oheight RGB "Yellow" 100  MULTIPLY-MODE)))	
                  (gimp-image-add-layer img yellow-layer -1)
                  (gimp-context-set-background '(251 242 163))
                  (gimp-drawable-fill yellow-layer BACKGROUND-FILL)
                  (gimp-layer-set-opacity yellow-layer 59)
                  
                  ;Magenta Layer
                  (set! magenta-layer (car (gimp-layer-new img owidth oheight RGB "Magenta" 100  SCREEN-MODE)))	
                  (gimp-image-add-layer img magenta-layer -1)
                  (gimp-context-set-background '(232 101 179))
                  (gimp-drawable-fill magenta-layer BACKGROUND-FILL)
                  (gimp-layer-set-opacity magenta-layer 20)
                  
                  ;Cyan Layer 
                  (set! cyan-layer (car (gimp-layer-new img owidth oheight RGB "Cyan" 100  SCREEN-MODE)))	
                  (gimp-image-add-layer img cyan-layer -1)
                  (gimp-context-set-background '(9 73 233))
                  (gimp-drawable-fill cyan-layer BACKGROUND-FILL)
                  (gimp-layer-set-opacity cyan-layer 17)
                  )
       )
    
    ;LAB from Martin Evening (http://www.photoshopforphotographers.com/pscs2/download/movie-06.pdf)
    (if(= c41 7)(begin
                  (set! drawA  (car (gimp-layer-copy draw FALSE)))
                  (set! drawB (car (gimp-layer-copy draw FALSE)))
                  (gimp-image-add-layer img drawA -1)
                  (gimp-image-add-layer img drawB -1)
                  
                  (gimp-drawable-set-name drawA "LAB-A")
                  (gimp-drawable-set-name drawB "LAB-B")
                  
                  ;decompose image to LAB and stretch A and B
                  (set! imgLAB (car (plug-in-decompose 1 img drawA "LAB" TRUE)))
                  (set! layersLAB (gimp-image-get-layers imgLAB))
                  (set! layerA (aref (cadr layersLAB) 1))
                  (gimp-levels-stretch layerA)
                  (plug-in-recompose 1 imgLAB layerA)
                  
                  (set! imgLAB (car (plug-in-decompose 1 img drawB "LAB" TRUE)))
                  (set! layersLAB (gimp-image-get-layers imgLAB))
                  (set! layerB (aref (cadr layersLAB) 2))
                  (gimp-levels-stretch layerB)
                  (plug-in-recompose 1 imgLAB layerB)
                  
                  (gimp-image-delete imgLAB)
                  
                  ;set mode to color mode
                  (gimp-layer-set-mode drawA COLOR-MODE)
                  (gimp-layer-set-mode drawB COLOR-MODE)
                  (gimp-layer-set-opacity drawA 40)
                  (gimp-layer-set-opacity drawB 40)
                  
                  ;blur
                  (plug-in-gauss 1 img drawA 2.5 2.5 1)
                  (plug-in-gauss 1 img drawB 2.5 2.5 1)
                  )
       )
    
    ;light blue
    (if(= c41 8)(begin
                  (gimp-curves-spline draw  HISTOGRAM-RED   6 #(0 0 154 141 232 255))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 8 #(0 0 65 48 202 215 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-GREEN 4 #(0 21 255 255))
                  (gimp-curves-spline draw  HISTOGRAM-BLUE  8 #(0 0 68 89 162 206 234 255))
                  (gimp-levels draw HISTOGRAM-VALUE
                               25 255 ;input
                               1.25   ;gamma
                               0 255) ;output
                  )
       )
    
    ;redscale
    (if(= c41 9)(begin
                  ;Blue Layer
                  (set! blue-layer (car (gimp-layer-copy draw TRUE)))
                  (gimp-image-add-layer img blue-layer -1)
                  (gimp-drawable-set-name blue-layer "Blue Filter")
                  (gimp-layer-set-opacity blue-layer 40)
                  (gimp-layer-set-mode blue-layer SCREEN-MODE)
                  (plug-in-colors-channel-mixer 1 img blue-layer TRUE
                                                0 0 1 ;R
                                                0 0 0 ;G
                                                0 0 0 ;B
                                                )
                  (set! blue-layer-mask (car (gimp-layer-create-mask blue-layer ADD-COPY-MASK)))
                  (gimp-layer-add-mask blue-layer blue-layer-mask)
                  
                  (gimp-context-set-background '(0 0 255))
                  (gimp-drawable-fill blue-layer BACKGROUND-FILL)
                  
                  (gimp-curves-spline draw HISTOGRAM-RED   6 #(0 0 127 190 255 255))
                  (gimp-curves-spline draw HISTOGRAM-GREEN 6 #(0 0 127  62 240 255))
                  (gimp-curves-spline draw HISTOGRAM-BLUE  4 #(0 0 255 0))
                  )
       )
    
    ;retro bw
    (if(= c41 10)(begin
                  (gimp-desaturate-full draw DESATURATE-LUMINOSITY)
                  ;(gimp-curves-spline draw HISTOGRAM-RED   4 #(0 15 255 255))
                  (gimp-curves-spline draw HISTOGRAM-BLUE  4 #(0 0 255 230))
                  (gimp-curves-spline draw HISTOGRAM-VALUE 8 #(0 0 63 52 191 202 255 255))
                  )
       )
    
    ;paynes bw
    (if(= c41 11)(begin
                  (gimp-desaturate-full draw DESATURATE-LUMINOSITY)
                  (gimp-colorize draw 215 11 0)
                  )
       )
    
    ;sepia
    (if(= c41 12)(begin
                  (gimp-desaturate-full draw DESATURATE-LUMINOSITY)
                  (gimp-colorize draw 30 25 0)
                  )
       )
    
    ;set some funky colors
    (if( = invertA TRUE)(begin
                          (set! imgLAB (car (plug-in-decompose 1 img draw "LAB" TRUE)))
                          (set! layersLAB (gimp-image-get-layers imgLAB))
                          (set! layerA (aref (cadr layersLAB) 1))
                          (gimp-invert layerA)
                          (plug-in-recompose 1 imgLAB layerA)
                          )
       )
    (if( = invertB TRUE)(begin
                          (set! imgLAB (car (plug-in-decompose 1 img draw "LAB" TRUE)))
                          (set! layersLAB (gimp-image-get-layers imgLAB))
                          (set! layerB (aref (cadr layersLAB) 2))
                          (gimp-invert layerB)
                          (plug-in-recompose 1 imgLAB layerB)
                          )
       )
    
    ;add two blending layers
    (gimp-context-set-foreground '(0 0 0)) ;black
    (gimp-context-set-background '(255 255 255)) ;white
    (gimp-image-add-layer img overexpo -1)
    (gimp-image-add-layer img vignette -1)
    (gimp-drawable-fill vignette TRANSPARENT-FILL)
    (gimp-drawable-fill overexpo TRANSPARENT-FILL)
    
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
    (gimp-edit-blend vignette 2 0 2 100 0 REPEAT-NONE TRUE FALSE 0 0 TRUE blend_x blend_y endingx endingy)
    (gimp-layer-scale vignette (* owidth avig) (* oheight avig) 1)
    (plug-in-spread 1 img vignette 50 50)
    (if (= adv TRUE) 
        ( begin 
           (set! hvignette (car (gimp-layer-copy vignette 0)))
           (gimp-layer-set-opacity hvignette 80)
           (gimp-image-add-layer img hvignette -1)
           (gimp-layer-resize-to-image-size hvignette)
           )
        )
    (gimp-layer-resize-to-image-size vignette)
    
    ;let's do the over-exposure effect
    ;swap foreground and background colors then
    ;apply a radial blend from center to farthest side of layer
    (gimp-context-swap-colors)
    (gimp-edit-blend overexpo 2 0 2 100 0 REPEAT-NONE FALSE FALSE 0 0 TRUE blend_x blend_y endingx endingy)
    (plug-in-spread 1 img overexpo 50 50)
    
    ;adding the black vignette
    ;selecting a feathered circle, invert selection and fill up with black
    (if (= is_black TRUE) 
        ( begin 
           (gimp-image-add-layer img black_vignette -1)
           (gimp-drawable-fill black_vignette TRANSPARENT-FILL)
           (gimp-ellipse-select img x_black y_black radius radius ADD TRUE TRUE (* radius 0.2)) ;last term is feather strength
           (gimp-selection-invert img)
           (gimp-context-set-foreground '(0 0 0))
           (gimp-edit-bucket-fill black_vignette FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
           (gimp-selection-none img)
           )
        )
    
    ;add grain
    (if (> grain 0) 
        ( begin 
           ;fill new layer with neutral gray
           (gimp-image-add-layer img grain-layer -1)
           (gimp-drawable-fill grain-layer TRANSPARENT-FILL)
           (gimp-context-set-foreground '(128 128 128))
           (gimp-selection-all img)
           (gimp-edit-bucket-fill grain-layer FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
           (gimp-selection-none img)
           
           ;add grain and blur it
           (plug-in-scatter-hsv 1 img grain-layer 2 0 0 100)
           (plug-in-gauss 1 img grain-layer 0.5 0.5 1)
           (gimp-layer-add-mask grain-layer grain-layer-mask)
           
           ;select the original image, copy and paste it as a layer mask into the grain layer
           (gimp-selection-all img)
           (gimp-edit-copy-visible img)
           (gimp-floating-sel-anchor (car (gimp-edit-paste grain-layer-mask TRUE)))
           
           ;set color curves of layer mask, so that only gray areas become grainy
           (gimp-curves-spline grain-layer-mask  HISTOGRAM-VALUE  6 (splineValue))
           )
        )
    
    ;sharpness layer
    (if(> sharp 0)
       (begin
         (if (> grain 0)(gimp-drawable-set-visible grain-layer FALSE))
         
         (gimp-edit-copy-visible aimg)
         (set! Visible (car (gimp-layer-new-from-visible aimg aimg "Visible")))
         (gimp-image-add-layer aimg Visible -1)
         
         (set! MaskImage (car (gimp-image-duplicate aimg)))
         (set! MaskLayer (cadr (gimp-image-get-layers MaskImage)))
         (set! OrigLayer (cadr (gimp-image-get-layers aimg)))
         (set! HSVImage (car (plug-in-decompose TRUE aimg Visible "Value" TRUE)))
         (set! HSVLayer (cadr (gimp-image-get-layers HSVImage)))
         (set! SharpenLayer (car (gimp-layer-copy Visible TRUE)))
         
         ;smart sharpen from here: http://registry.gimp.org/node/108
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
           (plug-in-unsharp-mask TRUE img SharpenLayer 1 sharp 0)
           (gimp-layer-set-opacity SharpenLayer 80)
           (gimp-layer-set-edit-mask SharpenLayer FALSE)
           )
         (gimp-drawable-set-name SharpenLayer "Sharpen")
         (gimp-image-remove-layer aimg Visible)
         (if (> grain 0)
             (begin
               (gimp-drawable-set-visible grain-layer TRUE)
               (gimp-image-lower-layer aimg SharpenLayer)
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
