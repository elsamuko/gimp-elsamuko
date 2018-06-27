/*
 * Copyright (C) 1999 Winston Chang
 *                    <winstonc@cs.wisc.edu>
 *                    <winston@stdout.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <cstdlib>
#include <cstdio>
#include <opencv2/opencv.hpp>
#include <opencv2/stereo.hpp>

// #include <sys/types.h>
// #include <sys/stat.h>
// #include <sys/dir.h>
// #include <sys/param.h>

#include <libgimp/gimp.h>
#include <libgimp/gimpui.h>

#define N_(x) (x)
#define _(x) (x)

#define PLUG_IN_PROC    "elsamuko-depthmap-cv"
#define PLUG_IN_BINARY  "elsamuko-depthmap-cv"

#define SCALE_WIDTH   120
#define ENTRY_WIDTH     5

/* Uncomment this line to get a rough estimate of how long the plug-in
 * takes to run.
 */

/*  #define TIMER  */

typedef struct {
    gint    iters;
    gint    parallax;
    gint    side;
    gint    change;
} DepthmapParams;

typedef struct {
    gboolean  run;
} DepthmapInterface;

/* local function prototypes */
static inline gint coord( gint i, gint j, gint k, gint channels, gint width ) {
    return channels * ( width * i + j ) + k;
};

/* local function prototypes */
static void query( void );
static void run( const gchar *name,
                 gint nparams,
                 const GimpParam  *param,
                 gint *nreturn_vals,
                 GimpParam **return_vals );

static void calcDepthmap( IplImage* cvImgLeft,
                          IplImage* cvImgRight,
                          CvMat* cvDepth,
                          int iters,
                          int parallax,
                          int side,
                          int change );

static gint write_matrix( CvMat* cvMatDepth,
                          char *filename );

static void depthmap_region( GimpPixelRgn *dstPTR,
                             gint iters,
                             gint parallax,
                             gint side,
                             gint change,
                             gint32 image,
                             gint x,
                             gint y,
                             gint width,
                             gint height,
                             gboolean show_progress );

static void depthmap( GimpDrawable *drawable,
                      gint iters,
                      gint parallax,
                      gint side,
                      gint change );

static gboolean depthmap_dialog( GimpDrawable *drawable );
static void preview_update( GimpPreview *preview );


/* create a few globals, set default values */
static DepthmapParams depthmap_params = {
    2,   /* default iters */
    16,  /* default parallax */
    0,   /* resulting depthmap: 0=left, 1=right*/
    0    /* switch? 0=false, 1=true*/
};

/* Setting PLUG_IN_INFO */
const GimpPlugInInfo PLUG_IN_INFO = {
    NULL,  /* init_proc  */
    NULL,  /* quit_proc  */
    query, /* query_proc */
    run,   /* run_proc   */
};


MAIN();

static void
query( void ) {
    static const GimpParamDef args[] = {
        { GIMP_PDB_INT32,    "run-mode",  "The run mode { RUN-INTERACTIVE (0), RUN-NONINTERACTIVE (1) }" },
        { GIMP_PDB_IMAGE,    "image",     "image" },
        { GIMP_PDB_DRAWABLE, "drawable",  "drawable" },
        { GIMP_PDB_INT32,    "iters",     "Iterations" },
        { GIMP_PDB_INT32,    "parallax",  "Horizontal parallax (px)" },
        { GIMP_PDB_INT32,    "result",    "Resulting depthmap: 0=left, 1=right" },
        { GIMP_PDB_INT32,    "switch",    "Switch left/right input: 0=false, 1=true" }
    };

    gimp_install_procedure( PLUG_IN_PROC,
                            "Render a depthmap out of two stereo layers",
                            "Render a depthmap out of two stereo layers",
                            "elsamuko <elsamuko@web.de>",
                            "elsamuko",
                            "2010",
                            "_Depthmap CV...",
                            "GRAY*, RGB*",
                            GIMP_PLUGIN,
                            G_N_ELEMENTS( args ), 0,
                            args, NULL );

    gimp_plugin_menu_register( PLUG_IN_PROC, "<Image>/Filters/Map" );
}

static void
run( const gchar      *name,
     gint              nparams,
     const GimpParam  *param,
     gint             *nreturn_vals,
     GimpParam       **return_vals ) {
    static GimpParam   values[1];
    GimpPDBStatusType  status = GIMP_PDB_SUCCESS;
    GimpDrawable      *drawable;
    GimpRunMode        run_mode;
#ifdef TIMER
    GTimer            *timer = g_timer_new();
#endif

    run_mode = ( GimpRunMode )param[0].data.d_int32;

    *return_vals  = values;
    *nreturn_vals = 1;

    values[0].type          = GIMP_PDB_STATUS;
    values[0].data.d_status = status;

    //INIT_I18N ();

    /*
     * Get drawable information...
     */
    drawable = gimp_drawable_get( param[2].data.d_drawable );
    gimp_tile_cache_ntiles( 2 * MAX( drawable->width  / gimp_tile_width() + 1 ,
                                     drawable->height / gimp_tile_height() + 1 ) );

    switch( run_mode ) {
    case GIMP_RUN_INTERACTIVE:
        gimp_get_data( PLUG_IN_PROC, &depthmap_params );

        /* initialize pixel regions and buffer */
        if( ! depthmap_dialog( drawable ) )
            return;

        break;

    case GIMP_RUN_NONINTERACTIVE:

        if( nparams != 7 ) {
            status = GIMP_PDB_CALLING_ERROR;
        } else {
            depthmap_params.iters = param[3].data.d_int32;
            depthmap_params.parallax = param[4].data.d_int32;
            depthmap_params.side = param[5].data.d_int32;
            depthmap_params.change = param[6].data.d_int32;

            /* make sure there are legal values */
            if( ( depthmap_params.iters < 1 ) ||
                    ( depthmap_params.parallax < 1 ) )
                status = GIMP_PDB_CALLING_ERROR;
        }

        break;

    case GIMP_RUN_WITH_LAST_VALS:
        gimp_get_data( PLUG_IN_PROC, &depthmap_params );
        break;

    default:
        break;
    }

    if( status == GIMP_PDB_SUCCESS ) {
        drawable = gimp_drawable_get( param[2].data.d_drawable );

        /* here we go */
        depthmap( drawable,
                  depthmap_params.iters,
                  depthmap_params.parallax,
                  depthmap_params.side,
                  depthmap_params.change );

        gimp_displays_flush();

        /* set data for next use of filter */
        if( run_mode == GIMP_RUN_INTERACTIVE )
            gimp_set_data( PLUG_IN_PROC,
                           &depthmap_params, sizeof( DepthmapParams ) );

        gimp_drawable_detach( drawable );
        values[0].data.d_status = status;
    }

#ifdef TIMER
    g_printerr( "%f seconds\n", g_timer_elapsed( timer, NULL ) );
    g_timer_destroy( timer );
#endif
}

static void
depthmap( GimpDrawable *drawable,
          gint          iters,
          gint          parallax,
          gint          side,
          gint          change ) {
    GimpPixelRgn destPR;
    gint32       image;
    gint         x1, y1, x2, y2;
    int          width, height;
    int          num_of_layers;

    image = gimp_drawable_get_image( drawable->drawable_id );
    printf( "L%i: Render: Image ID: %i\n", __LINE__, image );

    gint *layers = gimp_image_get_layers( image, &num_of_layers );
    gint leftlayer = layers[0];
    gint rightlayer = layers[1];

    gint32 depthmap = gimp_layer_copy( drawable->drawable_id );
    GimpDrawable *depthdrawable = gimp_drawable_get( depthmap );

    /* initialize pixel regions */
    gimp_pixel_rgn_init( &destPR, depthdrawable, 0, 0, depthdrawable->width, depthdrawable->height, TRUE, TRUE );

    /* Get the input */
    gimp_drawable_mask_bounds( drawable->drawable_id, &x1, &y1, &x2, &y2 );
    width = x2 - x1;
    height = y2 - y1;

    depthmap_region( &destPR,
                     iters, parallax,
                     side, change,
                     image,
                     x1, y1,
                     width, height,
                     TRUE );

    gimp_image_add_layer( image, depthmap, 0 );
    gimp_drawable_flush( depthdrawable );
    gimp_drawable_merge_shadow( depthdrawable->drawable_id, TRUE );
    gimp_drawable_update( depthdrawable->drawable_id, x1, y1, x2 - x1, y2 - y1 );
}

/* Copy the two GIMP layers to a CV stereo pair, perform the built-in
 * 3D reconstruction and copy the disparity as depthmap back to GIMP.
 */
static void
depthmap_region( GimpPixelRgn *prDepth,
                 gint          iters,
                 gint          parallax,
                 gint          side,
                 gint          change,
                 gint32        image,
                 gint          x,
                 gint          y,
                 gint          width,
                 gint          height,
                 gboolean      show_progress ) {
    printf( "L%i: **** Begin of depthmap ****\n", __LINE__ );
    gint        num_of_layers;
    gint        i = 0; //row
    gint        j = 0; //column
    gint        value;

    //define layers
    gint *layers = gimp_image_get_layers( image, &num_of_layers );
    gint leftlayer = layers[0];
    gint rightlayer = layers[1];
    gimp_layer_add_alpha( leftlayer );
    gimp_layer_add_alpha( rightlayer );

    //define drawables
    GimpDrawable *leftdrawable = gimp_drawable_get( leftlayer );
    GimpDrawable *rightdrawable = gimp_drawable_get( rightlayer );
    const gint channels = gimp_drawable_bpp( leftdrawable->drawable_id );

    printf( "L%i: Image ID: %i\n",           __LINE__, image );
    printf( "L%i: Number of Layers: %i\n",   __LINE__, num_of_layers );
    printf( "L%i: Leftlayer: %i\n",          __LINE__, leftlayer );
    printf( "L%i: Rightlayer: %i\n",         __LINE__, rightlayer );
    printf( "L%i: Channels: %i\n", __LINE__, channels );
    printf( "L%i: x:%i, y:%i\n", __LINE__, x, y );
    printf( "L%i: w:%i, h:%i\n", __LINE__, width, height );

    //select Regions
    GimpPixelRgn prLeft;
    GimpPixelRgn prRight;

    gimp_pixel_rgn_init( &prLeft,
                         leftdrawable,
                         x, y,
                         width, height,
                         FALSE, FALSE );
    gimp_pixel_rgn_init( &prRight,
                         rightdrawable,
                         x, y,
                         width, height,
                         FALSE, FALSE );
    printf( "L%i: Pixel regions initiated\n", __LINE__ );

    //Initialise memory
    guchar *rectLeft = g_new( guchar, channels * width * height );
    guchar *rectRight = g_new( guchar, channels * width * height );
    guchar *rectDepth = g_new( guchar, channels * width * height );

    //Save stereo images in arrays
    gimp_pixel_rgn_get_rect( &prLeft,
                             rectLeft,
                             x, y,
                             width, height );
    gimp_pixel_rgn_get_rect( &prRight,
                             rectRight,
                             x, y,
                             width, height );

    //cvimages
    IplImage* cvImgLeft  = cvCreateImage( cvSize( width, height ), IPL_DEPTH_8U, 1 );
    IplImage* cvImgRight = cvCreateImage( cvSize( width, height ), IPL_DEPTH_8U, 1 );
    CvMat* cvMatDepth = cvCreateMat( height, width, CV_8U );

    if( show_progress )
        gimp_progress_init( _( "Calculating..." ) );

    if( show_progress ) gimp_progress_update( 0.1 );

    // B/W
    if( channels == 2 ) {
        printf( "L%i: B/W: Get image values\n", __LINE__ );

        for( i = 0; i < height; i++ ) { //rows
            for( j = 0; j < width; j++ ) { //columns
                ( ( uchar * )( cvImgLeft->imageData + i * cvImgLeft->widthStep ) )[j] = ( gint )rectLeft[coord( i, j, 0, channels, width )];
                ( ( uchar * )( cvImgRight->imageData + i * cvImgRight->widthStep ) )[j] = ( gint )rectRight[coord( i, j, 0, channels, width )];
            }
        }

        // Color
    } else {
        printf( "L%i: Color: Get image values\n", __LINE__ );

        for( i = 0; i < height; i++ ) { //rows
            for( j = 0; j < width; j++ ) { //columns
                //Luminance: 0.2126R + 0.7152G + 0.0722B
                ( ( uchar * )( cvImgLeft->imageData + i * cvImgLeft->widthStep ) )[j] = 0.2126 * ( gint )rectLeft[coord( i, j, 0, channels, width )] +
                        0.7152 * ( gint )rectLeft[coord( i, j, 1, channels, width )] +
                        0.0722 * ( gint )rectLeft[coord( i, j, 2, channels, width )];
                ( ( uchar * )( cvImgRight->imageData + i * cvImgRight->widthStep ) )[j] = 0.2126 * ( gint )rectRight[coord( i, j, 0, channels, width )] +
                        0.7152 * ( gint )rectRight[coord( i, j, 1, channels, width )] +
                        0.0722 * ( gint )rectRight[coord( i, j, 2, channels, width )];
            }
        }
    }

    if( show_progress ) gimp_progress_update( 0.2 );

    // http://opencv.willowgarage.com/documentation/c/camera_calibration_and_3d_reconstruction.html#findstereocorrespondencegc
    calcDepthmap( cvImgLeft, cvImgRight, cvMatDepth,
                  iters, parallax, side, change );

    if( show_progress ) gimp_progress_update( 0.8 );

    //     // write out the OpenCV matrix as Octave matrix
    //     char* home = getenv("HOME");
    //     char dir[PATH_MAX + 1];
    //     char file[PATH_MAX + 1];
    //     sprintf (dir, "%s/%s", home, "depthmap");
    //     sprintf (file, "%s/%s/%s", home, "depthmap", "depthmap");
    //     mkdir( dir, S_IRWXU );
    //     write_matrix(cvMatDepth, file);

    // B/W
    if( channels == 2 ) {
        printf( "L%i: B/W: Set depth values\n", __LINE__ );

        for( i = 0; i < height; i++ ) { //rows
            for( j = 0; j < width; j++ ) { //columns
                rectDepth[coord( i, j, 0, channels, width )] = ( ( uchar* )( cvMatDepth->data.ptr + cvMatDepth->step * i ) )[j];
                rectDepth[coord( i, j, 1, channels, width )] = 255;
            }
        }

        // Color
    } else {
        printf( "L%i: Color: Set depth values\n", __LINE__ );

        for( i = 0; i < height; i++ ) { //rows
            for( j = 0; j < width; j++ ) { //columns
                value = ( ( uchar* )( cvMatDepth->data.ptr + cvMatDepth->step * i ) )[j];
                rectDepth[coord( i, j, 0, channels, width )] = value;
                rectDepth[coord( i, j, 1, channels, width )] = value;
                rectDepth[coord( i, j, 2, channels, width )] = value;
                rectDepth[coord( i, j, 3, channels, width )] = 255;
            }
        }
    }

    //save depthmap in array
    gimp_pixel_rgn_set_rect( prDepth,
                             rectDepth,
                             x, y,
                             width, height );

    if( show_progress ) gimp_progress_update( 1.0 );

    //free memory
    g_free( rectLeft );
    g_free( rectRight );
    g_free( rectDepth );

    //cvimages
    cvReleaseImage( &cvImgLeft );
    cvReleaseImage( &cvImgRight );
    cvReleaseMat( &cvMatDepth );

    printf( "L%i: **** End of depthmap ****\n\n\n", __LINE__ );
}

//http://opencv.willowgarage.com/documentation/c/camera_calibration_and_3d_reconstruction.html#findstereocorrespondencegc
static void
calcDepthmap( IplImage* cvImgLeft,
              IplImage* cvImgRight,
              CvMat* cvMatDepth,
              int iters,
              int parallax,
              int side,
              int change ) {

    CvSize size = cvGetSize( cvImgLeft );
    CvMat* disparityLeft = cvCreateMat( size.height, size.width, CV_8S );
    CvMat* disparityRight = cvCreateMat( size.height, size.width, CV_8S );
    CvStereoBMState* state = cvCreateStereoBMState( parallax, iters );

    if( change ) {
        cvFindStereoCorrespondenceBM( cvImgRight, cvImgLeft, disparityLeft, state );
    } else {
        cvFindStereoCorrespondenceBM( cvImgLeft, cvImgRight, disparityLeft, state );
    }

    cvReleaseStereoBMState( &state );

    if( side ) {
        cvConvertScale( disparityRight, cvMatDepth, -8, 0 );
    } else {
        cvConvertScale( disparityLeft, cvMatDepth, -8, 0 );
    }

    cvReleaseMat( &disparityRight );
    cvReleaseMat( &disparityLeft );

}

// debug function to write out the OpenCV matrix as Octave matrix
static gint
write_matrix( CvMat*  cvMatDepth,
              char   *filename ) {
    gint i, j, k, height, width;
    FILE *file;
    gint error = FALSE;
    height = cvMatDepth->rows;
    width  = cvMatDepth->cols;

    file = fopen( filename, "w" );

    if( file != NULL ) {
        // # Created by elsamuko-depthmap
        // # name: depthmap
        // # type: matrix
        // # ndims: 3
        fputs( "# Created by elsamuko-depthmap\n", file );
        fputs( "# name:  depthmap\n", file );
        fputs( "# type:  matrix\n", file );
        fprintf( file, "# ndims: %i\n", 3 );
        fprintf( file, "%i %i %i\n", height, width, 1 );

        for( j = 0; j < width; j++ ) {
            for( i = 0; i < height; i++ ) {
                fprintf( file, "%i\n", ( int )( ( uchar* )( cvMatDepth->data.ptr + cvMatDepth->step * i ) )[j] );
            }
        }

        fclose( file );
    } else {
        gimp_message( "Error: Could not open input matrix." );
        printf( "L%i: Error: Could not open input matrix.\n", __LINE__ );
        error = TRUE;
    }

    return error; //zero, if there is no problem
};

static gboolean
depthmap_dialog( GimpDrawable *drawable ) {
    GtkWidget *dialog;
    GtkWidget *main_vbox;
    GtkWidget *preview;
    GtkWidget *table;
    GtkObject *adj;
    GtkWidget *frame;
    GtkWidget *frame2;
    GtkWidget *hbox;
    GtkWidget *button;
    GtkWidget *button2;
    gboolean   run;

    gimp_ui_init( PLUG_IN_BINARY, TRUE );

    dialog = gimp_dialog_new( _( "Depthmap" ), PLUG_IN_BINARY,
                              NULL, ( GtkDialogFlags )0,
                              gimp_standard_help_func, PLUG_IN_PROC,

                              GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                              GTK_STOCK_OK,     GTK_RESPONSE_OK,

                              NULL );

    gtk_dialog_set_alternative_button_order( GTK_DIALOG( dialog ),
            GTK_RESPONSE_OK,
            GTK_RESPONSE_CANCEL,
            -1 );

    gimp_window_set_transient( GTK_WINDOW( dialog ) );

    main_vbox = gtk_vbox_new( FALSE, 12 );
    gtk_container_set_border_width( GTK_CONTAINER( main_vbox ), 12 );
    gtk_container_add( GTK_CONTAINER( gtk_dialog_get_content_area( GTK_DIALOG( dialog ) ) ),
                       main_vbox );
    gtk_widget_show( main_vbox );

    preview = gimp_drawable_preview_new( drawable, NULL );
    gtk_box_pack_start( GTK_BOX( main_vbox ), preview, TRUE, TRUE, 0 );
    gtk_widget_show( preview );

    g_signal_connect( preview, "invalidated",
                      G_CALLBACK( preview_update ),
                      NULL );

    table = gtk_table_new( 3, 3, FALSE );
    gtk_table_set_col_spacings( GTK_TABLE( table ), 6 );
    gtk_table_set_row_spacings( GTK_TABLE( table ), 6 );
    gtk_box_pack_start( GTK_BOX( main_vbox ), table, FALSE, FALSE, 0 );
    gtk_widget_show( table );

    adj = gimp_scale_entry_new( GTK_TABLE( table ), 0, 0,
                                _( "_Iterations:" ), SCALE_WIDTH, ENTRY_WIDTH,
                                depthmap_params.iters, 1, 8, 1, 2, 0,
                                TRUE, 0, 0,
                                NULL, NULL );

    g_signal_connect( adj, "value-changed",
                      G_CALLBACK( gimp_int_adjustment_update ),
                      &depthmap_params.iters );
    g_signal_connect_swapped( adj, "value-changed",
                              G_CALLBACK( gimp_preview_invalidate ),
                              preview );

    adj = gimp_scale_entry_new( GTK_TABLE( table ), 0, 1,
                                _( "_Parallax:" ), SCALE_WIDTH, ENTRY_WIDTH,
                                depthmap_params.parallax, 1.0, 32.0, 1, 2, 0,
                                TRUE, 0, 0,
                                NULL, NULL );

    g_signal_connect( adj, "value-changed",
                      G_CALLBACK( gimp_int_adjustment_update ),
                      &depthmap_params.parallax );
    g_signal_connect_swapped( adj, "value-changed",
                              G_CALLBACK( gimp_preview_invalidate ),
                              preview );

    hbox = gtk_hbox_new( FALSE, 12 );
    gtk_box_pack_start( GTK_BOX( main_vbox ), hbox, FALSE, FALSE, 0 );
    gtk_widget_show( hbox );

    frame = gimp_int_radio_group_new( TRUE, _( "Depthmap" ),
                                      G_CALLBACK( gimp_radio_button_update ),
                                      &depthmap_params.side, depthmap_params.side,
                                      _( "_Left" ), 0, &button,
                                      _( "_Right" ), 1,
                                      NULL, NULL );

    g_signal_connect_swapped( button, "toggled",
                              G_CALLBACK( gimp_preview_invalidate ),
                              preview );
    gtk_box_pack_start( GTK_BOX( hbox ), frame, FALSE, FALSE, 0 );
    gtk_widget_show( frame );

    frame2 = gimp_int_radio_group_new( TRUE, _( "Switch layers" ),
                                       G_CALLBACK( gimp_radio_button_update ),
                                       &depthmap_params.change, depthmap_params.change,
                                       _( "_False" ), 0, &button2,
                                       _( "_True" ), 1,
                                       NULL, NULL );

    g_signal_connect_swapped( button2, "toggled",
                              G_CALLBACK( gimp_preview_invalidate ),
                              preview );

    gtk_box_pack_start( GTK_BOX( hbox ), frame2, FALSE, FALSE, 0 );
    gtk_widget_show( frame2 );

    gtk_widget_show( dialog );

    run = ( gimp_dialog_run( GIMP_DIALOG( dialog ) ) == GTK_RESPONSE_OK );

    gtk_widget_destroy( dialog );

    return run;
}

static void
preview_update( GimpPreview *preview ) {
    GimpDrawable *drawable;
    gint32        image;
    GimpPixelRgn  destPR;
    gint          x, y;
    gint          width, height;

    drawable = gimp_drawable_preview_get_drawable( GIMP_DRAWABLE_PREVIEW( preview ) );

    image = gimp_drawable_get_image( drawable->drawable_id );
    printf( "L%i: Preview: Image ID: %i\n", __LINE__, image );

    gimp_pixel_rgn_init( &destPR, drawable, 0, 0, drawable->width, drawable->height, TRUE, TRUE );

    gimp_preview_get_position( preview, &x, &y );
    gimp_preview_get_size( preview, &width, &height );
    printf( "L%i: Preview: x:%i, y:%i\n", __LINE__, x, y );
    printf( "L%i: Preview: w:%i, h:%i\n", __LINE__, width, height );

    depthmap_region( &destPR,
                     depthmap_params.iters,
                     depthmap_params.parallax,
                     depthmap_params.side,
                     depthmap_params.change,
                     image,
                     x, y,
                     width, height,
                     FALSE );

    gimp_pixel_rgn_init( &destPR, drawable, x, y, width, height, FALSE, TRUE );
    gimp_drawable_preview_draw_region( GIMP_DRAWABLE_PREVIEW( preview ), &destPR );
}
