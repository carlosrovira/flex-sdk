////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2003-2006 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.utils
{

import flash.display.DisplayObject;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 *  Documentation is not currently available.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public class MatrixUtil
{
    include "../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------
    
    public static function composeMatrix(x:Number = 0,
                                         y:Number = 0,
                                         scaleX:Number = 1,
                                         scaleY:Number = 1,
                                         rotation:Number = 0,
                                         transformX:Number = 0,
                                         transformY:Number = 0):Matrix
    {
        var m:Matrix = new Matrix();
        m.translate(-transformX, -transformY);
        m.scale(scaleX, scaleY);
        if (rotation != 0) 
            m.rotate(rotationInRadians(rotation));
        m.translate(transformX + x, transformY + y);
        return m;
    }

    public static function applyTransforms(target:DisplayObject, matrix:Matrix = null, 
                                                x:Number = NaN, y:Number = NaN,
                                                scaleX:Number = NaN, scaleY:Number = NaN,
                                                rotation:Number = NaN,
                                                transformX:Number = NaN, transformY:Number = NaN):void
    {
        if (matrix == null)
        {
            var newX:Number = !isNaN(x) ? x : target.x;
            var newY:Number = !isNaN(y) ? y : target.y;
            var newScaleX:Number = !isNaN(scaleX) ? scaleX : target.scaleX;
            var newScaleY:Number = !isNaN(scaleY) ? scaleY : target.scaleY;
            var newRotation:Number = !isNaN(rotation) ? rotation : target.rotation;
            transformX = isNaN(transformX) ? 0 : transformX;
            transformY = isNaN(transformY) ? 0 : transformY;
			target.transform.matrix = composeMatrix(newX, newY, newScaleX, newScaleY, newRotation, transformX, transformY);
		}
		else
		{
			target.transform.matrix = matrix;
		}
	} 
		
	public static function rotationInRadians(value:Number):Number
	{
		return value / 180 * Math.PI;
	}

    
    /**
     *  @return Returns the union of <code>rect</code> and
     *  <code>Rectangle(left, top, right - left, bottom - top)</code>.
     *  Note that if rect is non-null, it will be updated to reflect the return value.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function rectUnion(left:Number, top:Number, right:Number, bottom:Number,
                                     rect:Rectangle):Rectangle
    {
        if (!rect)
            return new Rectangle(left, top, right - left, bottom - top);
        
        var minX:Number = Math.min(rect.left,   left);
        var minY:Number = Math.min(rect.top,    top);
        var maxX:Number = Math.max(rect.right,  right);
        var maxY:Number = Math.max(rect.bottom, bottom);

        rect.x      = minX;
        rect.y      = minY;
        rect.width  = maxX - minX;
        rect.height = maxY - minY;
        return rect;
    }

    /**
     *  Calculates the bounding box of a post-transformed ellipse.
     *   
     *  @param cx The x coordinate of the ellipse's center
     *  @param cy The y coordinate of the ellipse's center
     *  @param rx The horizontal radius of the ellipse
     *  @param ry The vertical radius of the ellipse
     *  @param matrix The transformation matrix.
     *  @param rect If non-null, rect will be updated to the union of rect and
     *  the segment bounding box.
     *  @return Returns the union of the passed in rect with the
     *  bounding box of the the post-transformed ellipse.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */ 
    public static function getEllipseBoundingBox(cx:Number, cy:Number,
                                                 rx:Number, ry:Number,
                                                 matrix:Matrix,
                                                 rect:Rectangle = null):Rectangle
    {
        var a:Number = matrix.a;
        var b:Number = matrix.b;
        var c:Number = matrix.c;
        var d:Number = matrix.d;
        
        // Ellipse can be represented by the following parametric equations:         
        //
        // (1) x = cx + rx * cos(t)
        // (2) y = cy + ry * sin(t)
        //
        // After applying transformation with matrix m(a, c, b, d) we get:
        //
        // (3) x = a * cx + a * cos(t) * rx + c * cy + c * sin(t) * ry + m.tx
        // (4) y = b * cx + b * cos(t) * rx + d * cy + d * sin(t) * ry + m.ty
        //
        // In (3) and (4) x and y are functions of a parameter t. To find the extremums we need
        // to find where dx/dt and dy/dt reach zero:
        //
        // (5) dx/dt = - a * sin(t) * rx + c * cos(t) * ry
        // (6) dy/dt = - b * sin(t) * rx + d * cos(t) * ry
        // (7) dx/dt = 0 <=> sin(t) / cos(t) = (c * ry) / (a * rx);   
        // (8) dy/dt = 0 <=> sin(t) / cos(t) = (d * ry) / (b * rx);
        
        if(rx == 0 && ry == 0)
        {
            var pt:Point = new Point(cx, cy);
            pt = matrix.transformPoint(pt);
            return rectUnion(pt.x, pt.y, pt.x, pt.y, rect);
        }

        var t:Number;
        var t1:Number;
        
        if (a * rx == 0)
            t = Math.PI / 2;
        else
            t = Math.atan((c * ry) / (a * rx));

        if (b * rx == 0)
            t1 = Math.PI / 2;
        else
            t1 = Math.atan((d * ry) / (b * rx));            
    
        // TODO EGeorgie: optimize
        var x1:Number = a * Math.cos(t) * rx + c * Math.sin(t) * ry;             
        var x2:Number = -x1;
        x1 += a * cx + c * cy + matrix.tx;
        x2 += a * cx + c * cy + matrix.tx;
    
        var y1:Number = b * Math.cos(t1) * rx + d * Math.sin(t1) * ry;             
        var y2:Number = -y1;
        y1 += b * cx + d * cy + matrix.ty;
        y2 += b * cx + d * cy + matrix.ty;
        
        return rectUnion(Math.min(x1, x2), Math.min(y1, y2), Math.max(x1, x2), Math.max(y1, y2), rect); 
    }

    /**
     *  @param x0 x coordinate of the first control point
     *  @param y0 y coordinate of the first control point
     *  @param x1 x coordinate of the second control point
     *  @param y1 y coordinate of the second control point
     *  @param x2 x coordinate of the third control point
     *  @param y2 y coordinate of the third control point
     *  @param sx The pre-transform scale factor for x coordinates.
     *  @param sy The pre-transform scale factor for y coordinates.
     *  @param matrix The transformation matrix.
     *  @param rect If non-null, rect will be updated to the union of rect and
     *  the segment bounding box.
     *  @return Returns the union of the post-transformed quadratic
     *  bezier segment's axis aligned bounding box and the passed in rect.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */	
    static public function getQBezierSegmentBBox(x0:Number, y0:Number,
                                                 x1:Number, y1:Number,
                                                 x2:Number, y2:Number,
                                                 sx:Number, sy:Number,
                                                 matrix:Matrix,
                                                 rect:Rectangle):Rectangle
    {
        var pt0:Point = matrix.transformPoint(new Point(x0 * sx, y0 * sy)); 
        var pt1:Point = matrix.transformPoint(new Point(x1 * sx, y1 * sy));
        var pt2:Point = matrix.transformPoint(new Point(x2 * sx, y2 * sy));
        
        var minX:Number = Math.min(pt0.x, pt2.x);
        var maxX:Number = Math.max(pt0.x, pt2.x);
        
        var minY:Number = Math.min(pt0.y, pt2.y);
        var maxY:Number = Math.max(pt0.y, pt2.y);
        
        var txDiv:Number = pt0.x - 2 * pt1.x + pt2.x;
        if (txDiv != 0)
        {
            var tx:Number = (pt0.x - pt1.x) / txDiv;
            if (0 <= tx && tx <= 1)
            {
                var x:Number = (1 - tx) * (1 - tx) * pt0.x + 2 * tx * (1 - tx) * pt1.x + tx * tx * pt2.x;
                minX = Math.min(x, minX);
                maxX = Math.max(x, maxX);
            }  
        }
         
        var tyDiv:Number = pt0.y - 2 * pt1.y + pt2.y;
        if (tyDiv != 0)
        {
            var ty:Number = (pt0.y - pt1.y) / tyDiv;
            if (0 <= ty && ty <= 1)
            {
                var y:Number = (1 - ty) * (1 - ty) * pt0.y + 2 * ty * (1 - ty) * pt1.y + ty * ty * pt2.y;
                minY = Math.min(y, minY);
                maxY = Math.max(y, maxY);
            }  
        }

        return rectUnion(minX, minY, maxX, maxY, rect);
    }

	/**
	 *  @param bounds Bounds to be transformed.
	 *  @param matrix The transfomration matrix. 
	 *  
	 *  @param vec If vec is non-null it will be set to the vector from the
	 *  transformed bounds top left to the untransformed bounds top left
	 *  in the coordinate space defined by <code>matrix</code>.
	 *  This is useful if you want to align the transformed bounds to x,y
	 *  by modifying the object's position. Moving the object by
	 *  <code>x + vec.x</code> and <code>y + vec.y</code> respectively
	 *  will offset the transformed bounds top left corner by x,y.
	 *
	 *  @return Returns the transformed bounds.
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	public static function transformSize(bounds:Point, matrix:Matrix):Point
	{
		// TODO EGeorgie: don't use new points, but do the math ourselves?
	    var pt1:Point = matrix.deltaTransformPoint(bounds);
	    var pt2:Point = matrix.deltaTransformPoint(new Point());
	    var pt3:Point = matrix.deltaTransformPoint(new Point(bounds.x, 0));
	    var pt4:Point = matrix.deltaTransformPoint(new Point(0, bounds.y));

        var maxX:Number = Math.max(Math.max(pt1.x, pt2.x), Math.max(pt3.x, pt4.x));
        var minX:Number = Math.min(Math.min(pt1.x, pt2.x), Math.min(pt3.x, pt4.x));
        var maxY:Number = Math.max(Math.max(pt1.y, pt2.y), Math.max(pt3.y, pt4.y));
        var minY:Number = Math.min(Math.min(pt1.y, pt2.y), Math.min(pt3.y, pt4.y));

	    pt1.x = maxX - minX;
	    pt1.y = maxY - minY;
	    return pt1;
	}

		
	/**
	 *  @param bounds width and height to be transformed.
	 *  @param matrix The transfomration matrix. 
	 *  
	 *  @param topleft If topLeft is non-null it will be used as the origin of the bounds
	 *  rectangle to be transformed.  On return, it will be set to the top left of the rectangle
	 *  after transformation.
	 *
	 *  @return Returns the transformed width and height
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	public static function transformBounds(bounds:Point, matrix:Matrix, topLeft:Point = null):Point
	{
		// TODO EGeorgie: don't use new points, but do the math ourselves?
		var x:Number = 0;
		var y:Number = 0;
		
		if (topLeft)
		{
			x = topLeft.x;
			y = topLeft.y;
		}	 
		
	    var pt1:Point = matrix.transformPoint(new Point(bounds.x + x, bounds.y + y));
	    var pt2:Point = matrix.transformPoint(new Point(x, y));
	    var pt3:Point = matrix.transformPoint(new Point(bounds.x + x, 0 + y));
	    var pt4:Point = matrix.transformPoint(new Point(0 + x, bounds.y + y));

	    var maxX:Number = Math.max(Math.max(pt1.x, pt2.x), Math.max(pt3.x, pt4.x));
	    var minX:Number = Math.min(Math.min(pt1.x, pt2.x), Math.min(pt3.x, pt4.x));
	    var maxY:Number = Math.max(Math.max(pt1.y, pt2.y), Math.max(pt3.y, pt4.y));
	    var minY:Number = Math.min(Math.min(pt1.y, pt2.y), Math.min(pt3.y, pt4.y));

	    if (topLeft )
	    {
	        topLeft.x = minX;
	        topLeft.y = minY;
		}

	    pt1.x = maxX - minX;
	    pt1.y = maxY - minY;
	    return pt1;
	}
	
	/**
	 *  @param matrix
	 *  @return Returns true when <code>pt == matrix.DeltaTransformPoint(pt)</code>
	 *  for any <code>pt:Point</code> (<code>matrix</code> is identity matrix,
	 *  when disregarding the translation part).   
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	public static function isDeltaIdentity(matrix:Matrix):Boolean
	{
	    // TODO EGeorgie: 2.5D support
	    if( matrix.a == 1 && matrix.d == 1 &&
	    	matrix.b == 0 && matrix.c == 0)
            return true;
        return false;
    }
    
    /**
     *  <code>fitBounds</code> Calculates a size (x,y) for a bounding box (0,0,x,y)
     *  such that the bounding box transformed with <code>matrix</code> will fit
     *  into (0,0,width,height).
     *  
     *  @param width This is the width of the bounding box that calculated size
     *  needs to fit in.
     * 
     *  @param height This is the height of the bounding box that the calculated
     *  size needs to fit in.
     * 
     *  @param matrix This defines the transformations that the function will take
     *  into account when calculating the size. The bounding box (0,0,x,y) of the
     *  calculated size (x,y) transformed with <code>matrix</code> will fit in the
     *  specified <code>width</code> and <code>height</code>.
     * 
     *  @param preferredWidth Preferred width for the calculated size. If possible
     *  the function will set the calculated size width to this value.
     * 
     *  @param preferredHeight Preferred height for the calculated size. If possible
     *  the function will set the calculated size height to this value.
     * 
     *  @param minWidth The minimum allowed value for the calculated size width.
     * 
     *  @param minHeight The minimum allowed value for the calculated size height.
     * 
     *  @param maxWidth The maximum allowed value for the calculated size width.
     * 
     *  @param maxHeight The maximum allowed value for the calculated size height.
     * 
     *  @return Returns the size (x,y) such that the bounding box (0,0,x,y) will
     *  fit into (0,0,width,height) after transformation with <code>matrix</code>.
     *  Returns null if there is no possible solution.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */ 
    public static function fitBounds(width:Number, height:Number, matrix:Matrix,
                                     preferredWidth:Number, preferredHeight:Number,
                                     minWidth:Number, minHeight:Number,
                                     maxWidth:Number, maxHeight:Number):Point
    {
        if (isNaN(width) && isNaN(height))
            return new Point(preferredWidth, preferredHeight);
            
        if (!isNaN(width) && !isNaN(height))
        {
            var actualSize:Point = calcUBoundsToFitTBounds(width, height, matrix,
                                                           minWidth, minHeight, 
                                                           maxWidth, maxHeight); 
            
            // If we couldn't fit in both dimensions, try to fit only one and
            // don't stick out of the other
            if (!actualSize)
            {
                actualSize = calcUBoundsToFitTBoundsWidth(width, matrix,
                                                          preferredWidth, preferredHeight, 
                                                          minWidth, minHeight, 
                                                          maxWidth, maxHeight);

                // If we fit the width, but not the height                                                          
                if (actualSize && transformSize(actualSize, matrix).y > height)
                {
                    actualSize = calcUBoundsToFitTBoundsHeight(height, matrix,
                                                               preferredWidth, preferredHeight, 
                                                               minWidth, minHeight, 
                                                               maxWidth, maxHeight);

                    // If we fit the height, but not the width
                    if (actualSize && transformSize(actualSize, matrix).x > width)
                       actualSize = null; // No solution
                }
            }
            return actualSize;
        }
        else if (!isNaN(width))
        {
            return calcUBoundsToFitTBoundsWidth(width, matrix,
                                                preferredWidth, preferredHeight, 
                                                minWidth, minHeight, 
                                                maxWidth, maxHeight);
        }
        else
        {
            return calcUBoundsToFitTBoundsHeight(height, matrix,
                                                 preferredWidth, preferredHeight, 
                                                 minWidth, minHeight, 
                                                 maxWidth, maxHeight);
        }
    }

    /**
     *  Calculates (x,y) such that the bounding box (0,0,x,y) transformed
     *  with <code>matrix</code> will have bounding box with
     *  height equal to <code>h</code>.
     *  x and y are restricted by <code>minX</code>, <code>maxX</code> and
     *  <code>minY</code>, <code>maxY</code>.
     *
     *  If possible x will be set to <code>preferredX</code> or
     *  y will be set to <code>preferredY</code>.
     *  
     *  When there are multiple solutions, the function picks the one that
     *  minimizes the bounding box area of transformed (0,0,x,y).
     * 
     *  The functon assumes <code>minX >= 0</code> and <code>minY >= 0</code>
     *  (solution components x and y are non-negative).
     *  
     *  @return Returns Point(x,y) or null if no solution exists. 
     * 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */        
    static public function calcUBoundsToFitTBoundsHeight(h:Number,
                                                         matrix:Matrix,
                                                         preferredX:Number,
                                                         preferredY:Number,
                                                         minX:Number,
                                                         minY:Number,
                                                         maxX:Number, 
                                                         maxY:Number):Point
    {
        // Make sure preferredX, preferredY are between minX and maxX
        preferredX = Math.max(minX, Math.min(maxX, preferredX));
        preferredY = Math.max(minY, Math.min(maxY, preferredY));
        
        // Untransformed bounds size is (x,y). The corners of the untransformed
        // bounding box are p1(0,0) p2(x,0) p3(0,y) p4(x,y).
        // Matrix is | a c tx |
        //           | b d ty |
        //
        // After transfomation with the matrix those four points are:
        // t1 = (0, 0)              = matrix.deltaTransformPoint(p1)
        // t2 = (ax, bx)            = matrix.deltaTransformPoint(p2)
        // t3 = (cy, dy)            = matrix.deltaTransformPoint(p3)
        // t4 = (ax + cy, cx + dy)  = matrix.deltaTransformPoint(p4)
        //
        // The transformed bounds bounding box dimensions are (w,h):
        // (1) w = max( t1.x, t2.x, t3.x, t4.x ) - min( t1.x, t2.x, t3.x, t4.x)
        // (2) h = max( t1.y, t2.y, t3.y, t4.y ) - min( t1.y, t2.y, t3.y, t4.y)
        //
        // Looking at all the possible cases for min and max functions above,
        // we can construct and solve simple linear systems for x and y.
        // For example in the case of
        // t1.x <= t2.x <= t3.x <= t4.x
        // our first equation is
        // (1) w = t4.x - t1.x <==> w = ax + cy
        //
        // To minimize the cases we're looking at we can take advantage of
        // the limits we have: x >= 0, y >= 0;
        // Taking into account these limits we deduce that:
        // a*c >= 0  gives us (1) w = abs( t4.x - t1.x ) = abs( ax + cy )
        // a*c <  0  gives us (1) w = abs( t2.x - t3.x ) = abs( ax - cy )
        // b*d >= 0  gives us (2) h = abs( t4.y - t1.y ) = abs( bx + dy )
        // b*d <  0  gives us (2) h = abs( t2.y - t3.y ) = abs( bx - dy )
        //
        // If we do a substitution such that
        // c1 = a*c >= 0 ? c : -c
        // d1 = b*d >= 0 ? d : -d
        // we get the following linear system:
        // (1) w = abs( ax + c1y )
        // (2) h = abs( bx + d1y )
        //
        // Since we're matching height we only care about (2) 

        const b:Number = matrix.b;
        const d:Number = matrix.d;

        // Handle special cases first
        if (b == 0)
            return new Point( preferredX, h / Math.abs(d) );               
        else if (d == 0)
            return new Point( h / Math.abs(b), preferredY );    

        const d1:Number = (b*d >= 0) ? d : -d;
        // Now we have the following linear sytesm:
        // (1) x = preferredX or y = preferredY
        // (2) h = abs( bx + d1y )

        var s:Point;
        var x:Number;
        var y:Number;
        
        if (d1 != 0)
        {
            const invD1:Number = 1 / d1;
            x = preferredX;
            
            // Case1:
            // bx + d1y >= 0
            // x = preferredX
            y = (h - b * x) * invD1;
            if (minY <= y && y <= maxY &&
                b * x + d1 * y >= 0 ) // Satisfy Case1
            {
                s = new Point(x, y);
            }
            
            // Case2:
            // bx + d1y < 0
            // x = preferredX
            y = (-h - b * x) * invD1;
            if (minY <= y && y <= maxY &&
                b * x + d1 * y < 0 ) // Satisfy Case2
            {
                // If there is no solution, or the new solution yields smaller value, pick the new solution.
                if (!s || transformSize(s, matrix).x > transformSize(new Point(x,y), matrix).x)
                   s = new Point(x, y);
            }
        }
        
        if (b != 0)
        {
            const invB:Number = 1 / b;
            y = preferredY;
            
            // Case3:
            // bx + d1y >= 0
            // y = preferredY
            x = ( h - d1 * y ) * invB;
            if (minX <= x && x <= maxX &&
                b * x + d1 * y >= 0) // Satisfy Case3
            {
                // If there is no solution, or the new solution yields smaller value, pick the new solution.
                if (!s || transformSize(s, matrix).x > transformSize(new Point(x,y), matrix).x)
                   s = new Point(x, y);
            }
            
            // Case4:
            // bx + d1y < 0
            // y = preferredY
            x = ( -h - d1 * y ) * invB;
            if (minX <= x && x <= maxX &&
                b * x + d1 * y < 0) // Satisfy Case4
            {
                // If there is no solution, or the new solution yields smaller value, pick the new solution.
                if (!s || transformSize(s, matrix).x > transformSize(new Point(x,y), matrix).x)
                   s = new Point(x, y);
            }
        }

        // If there's already a solution that matches preferred dimention, return
        if (s)
           return s;
        
        // Find a solution that matches the width and minimizes the height: 
        const a:Number = matrix.a;
        const c:Number = matrix.c;
        const c1:Number = ( a*c >= 0 ) ? c : -c;
        return solveEquation(b, d1, h, minX, minY, maxX, maxY, a, c1);
    }
    
    /**
     *  Calculates (x,y) such that the bounding box (0,0,x,y) transformed
     *  with <code>matrix</code> will have bounding box with
     *  width equal to <code>w</code>.
     *  x and y are restricted by <code>minX</code>, <code>maxX</code> and
     *  <code>minY</code>, <code>maxY</code>.
     *
     *  If possible x will be set to <code>preferredX</code> or
     *  y will be set to <code>preferredY</code>.
     *  
     *  When there are multiple solutions, the function picks the one that
     *  minimizes the bounding box area of transformed (0,0,x,y).
     * 
     *  The functon assumes <code>minX >= 0</code> and <code>minY >= 0</code>
     *  (solution components x and y are non-negative).
     *  
     *  @return Returns Point(x,y) or null if no solution exists. 
     * 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */        
    static public function calcUBoundsToFitTBoundsWidth(w:Number,
                                                        matrix:Matrix,
                                                        preferredX:Number,
                                                        preferredY:Number,
                                                        minX:Number,
                                                        minY:Number,
                                                        maxX:Number,
                                                        maxY:Number):Point
    {
        // Make sure preferredX, preferredY are between minX and maxX
        preferredX = Math.max(minX, Math.min(maxX, preferredX));
        preferredY = Math.max(minY, Math.min(maxY, preferredY));
        
        // Untransformed bounds size is (x,y). The corners of the untransformed
        // bounding box are p1(0,0) p2(x,0) p3(0,y) p4(x,y).
        // Matrix is | a c tx |
        //           | b d ty |
        //
        // After transfomation with the matrix those four points are:
        // t1 = (0, 0)              = matrix.deltaTransformPoint(p1)
        // t2 = (ax, bx)            = matrix.deltaTransformPoint(p2)
        // t3 = (cy, dy)            = matrix.deltaTransformPoint(p3)
        // t4 = (ax + cy, cx + dy)  = matrix.deltaTransformPoint(p4)
        //
        // The transformed bounds bounding box dimensions are (w,h):
        // (1) w = max( t1.x, t2.x, t3.x, t4.x ) - min( t1.x, t2.x, t3.x, t4.x)
        // (2) h = max( t1.y, t2.y, t3.y, t4.y ) - min( t1.y, t2.y, t3.y, t4.y)
        //
        // Looking at all the possible cases for min and max functions above,
        // we can construct and solve simple linear systems for x and y.
        // For example in the case of
        // t1.x <= t2.x <= t3.x <= t4.x
        // our first equation is
        // (1) w = t4.x - t1.x <==> w = ax + cy
        //
        // To minimize the cases we're looking at we can take advantage of
        // the limits we have: x >= 0, y >= 0;
        // Taking into account these limits we deduce that:
        // a*c >= 0  gives us (1) w = abs( t4.x - t1.x ) = abs( ax + cy )
        // a*c <  0  gives us (1) w = abs( t2.x - t3.x ) = abs( ax - cy )
        // b*d >= 0  gives us (2) h = abs( t4.y - t1.y ) = abs( bx + dy )
        // b*d <  0  gives us (2) h = abs( t2.y - t3.y ) = abs( bx - dy )
        //
        // If we do a substitution such that
        // c1 = a*c >= 0 ? c : -c
        // d1 = b*d >= 0 ? d : -d
        // we get the following linear system:
        // (1) w = abs( ax + c1y )
        // (2) h = abs( bx + d1y )
        //
        // Since we're matching width we only care about (1) 

        const a:Number = matrix.a;
        const c:Number = matrix.c;

        // Handle special cases first
        if (a == 0)
            return new Point( preferredX, w / Math.abs(c) );               
        else if (c == 0)
            return new Point( w / Math.abs(a), preferredY );    

        const c1:Number = ( a*c >= 0 ) ? c : -c;
        // Now we have the following linear sytesm:
        // (1) w = abs( ax + c1y )
        // (2) x = preferredX or y = preferredY

        var s:Point;
        var x:Number;
        var y:Number;
        
        if (c1 != 0)
        {
            const invC1:Number = 1 / c1;
            x = preferredX;

            // Case1:
            // a * x + c1 * y >= 0
            // x = preferredX
            y = (w - a * x) * invC1;
            if (minY <= y && y <= maxY &&
                a * x + c1 * y >= 0 ) // Satisfy Case1
            {
                s = new Point(x, y);        
            }
        
            // Case2:
            // a * x + c1 * y < 0
            // x = preferredX
            y = (-w - a * x) * invC1;
            if (minY <= y && y <= maxY &&
                a * x + c1 * y < 0 ) // Satisfy Case2
            {
                // If there is no solution, or the new solution yields smaller value, pick the new solution.
                if (!s || transformSize(s, matrix).y > transformSize(new Point(x,y), matrix).y)
                   s = new Point(x, y);
            }
        }
        
        if (a != 0)
        {
            const invA:Number = 1 / a;
            y = preferredY;

            // Case3:
            // a * x + c1 * y >= 0
            // y = preferredY
            x = (w - c1 * y ) * invA;
            if (minX <= x && x <= maxX &&
                a * x + c1 * y >= 0) // Satisfy Case3
            {
                // If there is no solution, or the new solution yields smaller value, pick the new solution.
                if (!s || transformSize(s, matrix).y > transformSize(new Point(x,y), matrix).y)
                   s = new Point(x, y);
            }
            
            // Case4:
            // a * x + c1 * y < 0
            // y = preferredY
            x = (-w - c1 * y ) * invA;
            if (minX <= x && x <= maxX &&
                a * x + c1 * y < 0) // Satisfy Case4
            {
                // If there is no solution, or the new solution yields smaller value, pick the new solution.
                if (!s || transformSize(s, matrix).y > transformSize(new Point(x,y), matrix).y)
                   s = new Point(x, y);
            }
        }
        
        // If there's already a solution that matches preferred dimention, return
        if (s)
           return s;
        
        // Find a solution that matches the width and minimizes the height: 
        const b:Number = matrix.b;
        const d:Number = matrix.d;
        const d1:Number = (b*d >= 0) ? d : -d;
        return solveEquation(a, c1, w, minX, minY, maxX, maxY, b, d1);
    }
    
    /**
     *  Finds a solution (x,y) for the equation abs(a*x + c*y) = w such that
     *  abs(b*x +d*y) is minimized.
     *  If there is infinate number of solutions, x and y are picked to be
     *  as close as possible.
     * 
     *  Doesn't handle cases where <code>a</code> or <code>c</code> are zero.
     * 
     *  @return Returns Point(x,y)
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */        
    static private function solveEquation(a:Number,
                                          c:Number,
                                          w:Number,
                                          minX:Number,
                                          minY:Number, 
                                          maxX:Number, 
                                          maxY:Number, 
                                          b:Number, 
                                          d:Number):Point
    {
        if (a == 0 || c == 0)
           return null; // x and y are not co-dependent

        // (1) w = abs( ax + cy )
        // Find the range of solutsion for y and pick:
        var x:Number;
        var y:Number;
        var s:Point;
        
        // Case1: ax + cy >= 0, from (1) above we get:
        // (1) x = (w - cy) / a
        //
        // Lets find the possible range of values for y:
        // We know that
        // (3) minX <= x <= maxX
        //
        // Substitute x with (w - cy)/a in (3):
        // (3) minX - w/a <= -cy/a <= maxX - w/a
        // (3) min( A, B ) <= y <= max( A, B ), where
        // A = (minX - w/a) * (-a/c)
        // B = (maxX - w/a) * (-a/c)

        var A:Number = (w - minX * a) / c;              
        var B:Number = (w - maxX * a) / c;              
        var rangeMinY:Number = Math.max(minY, Math.min(A, B));
        var rangeMaxY:Number = Math.min(maxY, Math.max(A, B));
        const det:Number = ( b * c - a * d );

        // We have a possible solution for Case1 if the range for y is valid
        if (rangeMinY <= rangeMaxY)
        {
            // Now that we have a valid range for y, we need to pick a value within
            // that range.
            //
            // We calculate the value based on a custom condition.
            //
            // The custom condition that we use could be anything that defines
            // another equation for x and y. Some examples are:
            // "make x and y as close as possible": y = w / ( a + c );  
            // "minimize abs(bx + dy)": y = b * w / det    
            // "preserve aspect ratio": y = w / ( a * preferredX / preferredY + c );
            if (det == 0)
            {
                // There is infinate number of solutions, lets pick x == y
                y = w / ( a + c );
            }
            else
            {
                // Minimize abs(bx + dy) - we need to solve:
                // abs( b * ( w - c * y ) / a + d * y ) = 0
                // which gives us:
                y = b * w / det;
            }

            // Now that we have the y value calculated from the custom condition,
            // we clamp with the range. This gives us a solution with
            // values as close as possible to satisfy our custom condition when
            // the condition is a linear function of x and y (in our case it is).
            y = Math.max(rangeMinY, Math.min(y, rangeMaxY));
           
            x = ( w - c * y ) / a;
            return new Point(x, y);
        }
        
        // Case2: ax + cy < 0, from (1) above we get:
        // (1) x = (-w - cy) / a
        //
        // Lets find the possible range of values for y:
        // We know that
        // (3) minX <= x <= maxX
        //
        // Substitute x with (-w - cy)/a in (3):
        // (3) minX + w/a <= -cy/a <= maxX + w/a
        // (3) min( A, B ) <= y <= max( A, B ), where
        // A = (minX + w/a) * (-a/c)
        // B = (maxX + w/a) * (-a/c)
        
        A = -( minX * a + w ) / c;
        B = -( maxX * a + w ) / c;
        rangeMinY = Math.max(minY, Math.min(A, B));
        rangeMaxY = Math.min(maxY, Math.max(A, B));

        // We have a possible solution for Case2 if the range for y is valid
        if (rangeMinY <= rangeMaxY)
        {
            // Now that we have a valid range for y, we need to pick a value within
            // that range.
            //
            // We calculate the value based on a custom condition.
            //
            // The custom condition that we use could be anything that defines
            // another equation for x and y. Some examples are:
            // "make x and y as close as possible": y = -w / ( a + c );  
            // "minimize abs(bx + dy)": y = -b * w / det    
            // "preserve aspect ratio": y = w / ( a * preferredX / preferredY + c );
            if( det == 0 )
            {
                // There is infinate number of solutions, lets pick x == y
                y = -w / ( a + c );
            }
            else
            {
                // Minimize abs(bx + dy) - we need to solve:
                // abs( b * ( -w - c * y ) / a + d * y ) = 0
                // which gives us:
                y = -b * w / det;
            }
           
            // Now that we have the y value calculated from the custom condition,
            // we clamp with the range. This gives us a solution with
            // values as close as possible to satisfy our custom condition when
            // the condition is a linear function of x and y (in our case it is).
            y = Math.max( rangeMinY, Math.min( y, rangeMaxY));
            x = ( -w - c * y ) / a;
            return new Point(x,y);

        }
        return null; // No solution
    }

    /**
     *  Calculates (x,y) such that the bounding box (0,0,x,y) transformed
     *  with <code>matrix</code> will have bounding box (0,0,w,h).
     *  x and y are restricted by <code>minX</code>, <code>maxX</code> and
     *  <code>minY</code>, <code>maxY</code>.
     * 
     *  When there is infinate number of solutions, the function will
     *  calculate x and y to be as close as possible.
     * 
     *  The functon assumes <code>minX >= 0</code> and <code>minY >= 0</code>
     *  (solution components x and y are non-negative). 
     *  
     *  @return Point(x,y) or null if no solution exists.
     * 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    static public function calcUBoundsToFitTBounds(w:Number, 
                                                   h:Number,
                                                   matrix:Matrix,
                                                   minX:Number,
                                                   minY:Number, 
                                                   maxX:Number, 
                                                   maxY:Number):Point
    {
        // Untransformed bounds size is (x,y). The corners of the untransformed
        // bounding box are p1(0,0) p2(x,0) p3(0,y) p4(x,y).
        // Matrix is | a c tx |
        //           | b d ty |
        //
        // After transfomation with the matrix those four points are:
        // t1 = (0, 0)              = matrix.deltaTransformPoint(p1)
        // t2 = (ax, bx)            = matrix.deltaTransformPoint(p2)
        // t3 = (cy, dy)            = matrix.deltaTransformPoint(p3)
        // t4 = (ax + cy, cx + dy)  = matrix.deltaTransformPoint(p4)
        //
        // The transformed bounds bounding box dimensions are (w,h):
        // (1) w = max( t1.x, t2.x, t3.x, t4.x ) - min( t1.x, t2.x, t3.x, t4.x)
        // (2) h = max( t1.y, t2.y, t3.y, t4.y ) - min( t1.y, t2.y, t3.y, t4.y)
        //
        // Looking at all the possible cases for min and max functions above,
        // we can construct and solve simple linear systems for x and y.
        // For example in the case of
        // t1.x <= t2.x <= t3.x <= t4.x
        // our first equation is
        // (1) w = t4.x - t1.x <==> w = ax + cy
        //
        // To minimize the cases we're looking at we can take advantage of
        // the limits we have: x >= 0, y >= 0;
        // Taking into account these limits we deduce that:
        // a*c >= 0  gives us (1) w = abs( t4.x - t1.x ) = abs( ax + cy )
        // a*c <  0  gives us (1) w = abs( t2.x - t3.x ) = abs( ax - cy )
        // b*d >= 0  gives us (2) h = abs( t4.y - t1.y ) = abs( bx + dy )
        // b*d <  0  gives us (2) h = abs( t2.y - t3.y ) = abs( bx - dy )
        //
        // If we do a substitution such that
        // c1 = a*c >= 0 ? c : -c
        // d1 = b*d >= 0 ? d : -d
        // we get the following linear system:
        // (1) w = abs( ax + c1y )
        // (2) h = abs( bx + d1y )
        // 

        const a:Number = matrix.a;
        const b:Number = matrix.b;
        const c:Number = matrix.c;
        const d:Number = matrix.d;

        // Handle special cases.
        if (b == 0 && c == 0)
        {
            // No solution in the following cases since the matrix collapses
            // all points into a line.
            if (a == 0 || d == 0)
               return null;

            // (1) w = abs( ax + cy ) <=> w = abs( ax ) <=> w = abs(a)x
            // (2) h = abs( bx + dy ) <=> h = abs( dy ) <=> h = abs(d)y
            return new Point(w / Math.abs(a), h / Math.abs(d));
        }
        
        if (a == 0 && d == 0)
        {
            // No solution in the following cases since the matrix collapses
            // all points into a line.
            if(b == 0 || c==0)
               return null;

            // (1) w = abs( ax + cy ) <=> w = abs( cy ) <=> w = abs(c)y
            // (2) h = abs( bx + dy ) <=> h = abs( bx ) <=> h = abs(b)x
            return new Point(h / Math.abs(b), w / Math.abs(c));
        }

        // Handle general cases.
        const c1:Number = ( a*c >= 0 ) ? c : -c;
        const d1:Number = ( b*d >= 0 ) ? d : -d;
        // we get the following linear system:
        // (1) w = abs( ax + c1y )
        // (2) h = abs( bx + d1y )
        
        // Calculate the determinant of the system
        const det:Number = a * d1 - b * c1;
        if( det == 0 )
        {
            // No solution in these cases since the matrix
            // collapses all points into a line.
            if (c1 == 0 || a == 0 || a == -c1)
               return null;
               
            if( Math.abs( a * h ) - Math.abs( b * w ) > 1.0e-9 )
               return null; // No solution in this case
               
            // Determinant is zero, the equations (1) & (2) are equivalent and
            // we have only one equation:
            // (1) w = abs( ax + c1y )
            //
            // Solve it finding x and y as close as possible:   
            return solveEquation(a, c1, w, minX, minX, maxX, maxY, b, d1);
        }
        
        // Pre-multiply w & h by the inverse dteterminant
        const invDet:Number = 1 / det;
        w *= invDet;
        h *= invDet;

        // Case 1:
        // a * x + c1 * y >= 0
        // b * x + d1 * y >= 0
        var s:Point;
        s = solveSystem( a, c1, b, d1, w, h);
        if( s &&
            minX <= s.x && s.x <= maxX && minY <= s.y && s.y <= maxY &&
            a * s.x + c1 * s.x >= 0 &&
            b * s.x + d1 * s.y >= 0 )
            return s;

        // Case 2:
        // a * x + c1 * y >= 0
        // b * x + d1 * y < 0
        s = solveSystem( a, c1, b, d1, w, -h);
        if( s &&
            minX <= s.x && s.x <= maxX && minY <= s.y && s.y <= maxY &&
            a * s.x + c1 * s.x >= 0 &&
            b * s.x + d1 * s.y < 0 )
            return s;

        // Case 3:
        // a * x + c1 * y < 0
        // b * x + d1 * y >= 0
        s = solveSystem( a, c1, b, d1, -w, h);
        if( s &&
            minX <= s.x && s.x <= maxX && minY <= s.y && s.y <= maxY &&
            a * s.x + c1 * s.x < 0 &&
            b * s.x + d1 * s.y >= 0 )
            return s;

        // Case 4:
        // a * x + c1 * y < 0
        // b * x + d1 * y < 0
        s = solveSystem( a, c1, b, d1, -w, -h);
        if( s &&
            minX <= s.x && s.x <= maxX && minY <= s.y && s.y <= maxY &&
            a * s.x + c1 * s.x < 0 &&
            b * s.x + d1 * s.y < 0 )
            return s;

        return null; // No solution.
    }

    /**
     *  Calculates (x,y) such as to satisfy the linear system:
     *  | a * x + c * y = m
     *  | b * x + d * y = n
     * 
     *  @param mOverDet <code>mOverDet must be equal to m / (a*d - b*c)</code>
     *  @param nOverDet <code>mOverDet must be equal to n / (a*d - b*c)</code>
     *
     *  @return returns Point(x,y)
     *
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    static private function solveSystem(a:Number, 
                                        c:Number, 
                                        b:Number, 
                                        d:Number, 
                                        mOverDet:Number, 
                                        nOverDet:Number):Point
    {
        return new Point(d * mOverDet - c * nOverDet,
                         a * nOverDet - b * mOverDet);
    }
}

}
