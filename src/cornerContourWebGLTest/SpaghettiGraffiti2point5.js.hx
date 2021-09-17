package cornerContourWebGLTest;

import cornerContour.io.Float32Array;

// contour code
import cornerContour.Sketcher;
import cornerContour.SketcherGrad;
import cornerContour.Pen2D;
import cornerContour.Pen2DGrad;
import cornerContour.StyleSketch;
import cornerContour.StyleEndLine;
// SVG path parser
import justPath.*;
import justPath.transform.ScaleContext;
import justPath.transform.ScaleTranslateContext;
import justPath.transform.TranslationContext;

// webgl gl stuff
import cornerContourWebGLTest.ShaderColor2D;
import cornerContourWebGLTest.HelpGL;
import cornerContourWebGLTest.BufferGL;
import cornerContourWebGLTest.GL;

// html stuff
import cornerContourWebGLTest.Sheet;
import cornerContourWebGLTest.DivertTrace;

// js webgl 
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Program;
import js.html.webgl.Texture;


function main(){
    new SpaghettiGraffiti2point5();
}

class SpaghettiGraffiti2point5 {
    
    var sketcher:       SketcherGrad;
    var pen2D:          Pen2DGrad;
    
    // WebGL/Html specific code
    public var gl:               RenderingContext;
        // general inputs
    final vertexPosition         = 'vertexPosition';
    final vertexColor            = 'vertexColor';

    // general
    public var width:            Int;
    public var height:           Int;
    public var mainSheet:        Sheet;

    // Color
    public var programColor:     Program;
    public var bufColor:         Buffer;
    var divertTrace:             DivertTrace;
    var arr32:                   Float32Array;
    var len:                     Int;
    var totalTriangles:          Int;
    var bufferLength:            Int;
    public function new(){
        divertTrace = new DivertTrace();
        trace('Contour Test - 2.5D Spaghetti Graffiti');
        width = 1024;
        height = 768;
        // use Pen to draw to Array
        drawContours();
        rearrageDrawData();
        renderOnce();
    }
    
    public
    function rearrageDrawData(){
        trace( 'rearrangeDrawData' );
        var pen = pen2D;
        //trace( pen );
        var data = pen.arr;
        var redA    = 0.;   
        var greenA  = 0.;
        var blueA   = 0.; 
        var alphaA  = 0.;
        var colorA: Int  = 0;
        var redB    = 0.;   
        var greenB  = 0.;
        var blueB   = 0.; 
        var alphaB  = 0.;
        var colorB: Int  = 0;
        var redC    = 0.;   
        var greenC  = 0.;
        var blueC   = 0.; 
        var alphaC  = 0.;
        var colorC: Int  = 0;
        // triangle length
        totalTriangles = Std.int( data.size/9 );//7
        bufferLength = totalTriangles*3;
         // xy rgba = 6
        len = Std.int( totalTriangles * 6 * 3 );//6
        var j = 0;
        arr32 = new Float32Array( len );
        trace('total triangles ' + len );
        for( i in 0...totalTriangles ){
            pen.pos = i;
            
            colorA = Std.int( data.colorA );
            
            alphaA = alphaChannel( colorA );
            redA   = redChannel(   colorA );
            greenA = greenChannel( colorA );
            blueA  = blueChannel(  colorA );
            
            colorB = Std.int( data.colorB );
            
            alphaB = alphaChannel( colorB );
            redB   = redChannel(   colorB );
            greenB = greenChannel( colorB );
            blueB  = blueChannel(  colorB );
            
            colorC = Std.int( data.colorC );
            
            alphaC = alphaChannel( colorC );
            redC   = redChannel(   colorC );
            greenC = greenChannel( colorC );
            blueC  = blueChannel(  colorC );
            
            // populate arr32.
            arr32[ j ] = gx( data.ax );
            j++;
            arr32[ j ] = gy( data.ay );
            j++;
            arr32[ j ] = redA;
            j++;
            arr32[ j ] = greenA;
            j++;
            arr32[ j ] = blueA;
            j++;
            arr32[ j ] = alphaA;
            j++;
            arr32[ j ] = gx( data.bx );
            j++;
            arr32[ j ] = gy( data.by );
            j++;
            arr32[ j ] = redB;
            j++;
            arr32[ j ] = greenB;
            j++;
            arr32[ j ] = blueB;
            j++;
            arr32[ j ] = alphaB;
            j++;
            arr32[ j ] = gx( data.cx );
            j++;
            arr32[ j ] = gy( data.cy );
            j++;
            arr32[ j ] = redC;
            j++;
            arr32[ j ] = greenC;
            j++;
            arr32[ j ] = blueC;
            j++;
            arr32[ j ] = alphaC;
            j++;
        }
    }
    public
    function drawContours(){
        trace( 'drawContours' );
        pen2D = new Pen2DGrad( 0xFF0000FF, 0xFF00FF00, 0xFF0000FF );
        pen2D.currentColor = 0xFF0000FF;
        pen2D.colorB = 0xFF00FF00;
        pen2D.colorC = 0xFF0000FF;
        cubicSVG();
        randomTest();
    }
    public
    function randomTest(){
        var sketcher = new SketcherGrad( pen2D, StyleSketch.Fine, StyleEndLine.no );
        sketcher.width = 20;
        sketcher.moveTo( 40, 100 );
        for( i in 0...200 ){
            randomDraw( sketcher, pen2D );
        }
    }
    public function randomDraw( s: Sketcher, p: Pen2DGrad ){
        var n = Std.random(4);
        switch( n ){
            case 0:
                s.lineTo( 30 + 500*Math.random(),30+ 500*Math.random() );
            case 1:
                s.quadThru( 30+500*Math.random(),30+500*Math.random(), 30+500*Math.random(),30+500*Math.random() );
            case 2:
                var max = 0xFFFFFF;
                p.currentColor = 0xFF000000 + Std.random( max );
                p.colorB =  0xFF000000 + Std.random( max );
            case 3:
                s.width = 30+ 5*Math.random();
        }
    }
    public
    function renderOnce(){
        trace( 'renderOnce' );
        //return;
        mainSheet = new Sheet();
        mainSheet.create( width, height, true );
        gl = mainSheet.gl;
        clearAll( gl, width, height, 0., 0., 0., 1. );
        programColor = programSetup( gl, vertexString, fragmentString );
        gl.bindBuffer( GL.ARRAY_BUFFER, null );
        gl.useProgram( programColor );
        bufColor = interleaveXY_RGBA( gl
                       , programColor
                       , arr32
                       , vertexPosition, vertexColor, true );
        gl.bindBuffer( GL.ARRAY_BUFFER, bufColor );
        gl.useProgram( programColor );
        gl.drawArrays( GL.TRIANGLES, 0, bufferLength );
        
    }
    public static inline
    function alphaChannel( int: Int ) : Float
        return ((int >> 24) & 255) / 255;
    public static inline
    function redChannel( int: Int ) : Float
        return ((int >> 16) & 255) / 255;
    public static inline
    function greenChannel( int: Int ) : Float
        return ((int >> 8) & 255) / 255;
    public static inline
    function blueChannel( int: Int ) : Float
        return (int & 255) / 255;
    public inline
    function gx( v: Float ): Float {
        return -( 1 - 2*v/width );
    }
    public inline
    function gy( v: Float ): Float {
        return ( 1 - 2*v/height );
    }
    /** 
     * draws cubic SVG
     */
    public
    function cubicSVG(){
        var sketcher = new SketcherGrad( pen2D, StyleSketch.Medium, StyleEndLine.no );
        
        sketcher.width = 30;
        // function to adjust color of curve along length
        sketcher.colourFunction = function( colour: Int, x: Float, y: Float, x_: Float, y_: Float ):  Int {
            return Math.round( colour-1*x*y );
        }
        sketcher.colourFunctionB = function( colour: Int, x: Float, y: Float, x_: Float, y_: Float ):  Int {
            return Math.round( colour+x/y );
        }
        var translateContext = new TranslationContext( sketcher, 470, 200 );
        var p = new SvgPath( translateContext );
        p.parse( cubictest_d );
    }
    /**
     * draws quad SVG
     */
    /*
    public
    function quadSVG(){
        var sketcher = new SketcherGrad( pen2D, StyleSketch.Fine, StyleEndLine.no );
        
        sketcher.width = 1;
        // function to adjust width of curve along length
        sketcher.widthFunction = function( width: Float, x: Float, y: Float, x_: Float, y_: Float ): Float{
            return width+0.008*2;
        }
        var translateContext = new ScaleTranslateContext( sketcher, 0, 100, 0.5, 0.5 );
        var p = new SvgPath( translateContext );
        p.parse( quadtest_d );
    }*/
    /**
     * draws elipse arcs
     */
    var quadtest_d      = "M200,300 Q400,50 600,300 T1000,300";
    var cubictest_d     = "M100,200 C100,100 250,100 250,200S400,300 400,200";
}