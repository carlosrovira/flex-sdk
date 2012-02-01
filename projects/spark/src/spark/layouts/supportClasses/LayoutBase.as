////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.layout
{

import flash.events.Event;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.ui.Keyboard;

import mx.components.baseClasses.GroupBase;
import mx.layout.ILayoutItem;
import flash.events.EventDispatcher;

    
public class LayoutBase extends EventDispatcher
{
    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------

    protected static function hasPercentWidth(layoutItem:ILayoutItem):Boolean
    {
        return !isNaN( layoutItem.percentSize.x );
    }
    
    protected static function hasPercentHeight(layoutItem:ILayoutItem):Boolean
    {
        return !isNaN( layoutItem.percentSize.y );
    }

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function LayoutBase()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  target
    //----------------------------------    

    private var _target:GroupBase;
    
    public function get target():GroupBase
    {
        return _target;
    }
    
    public function set target(value:GroupBase):void
    {
        _target = value;
    }
    
    //----------------------------------
    //  horizontalScrollPosition
    //----------------------------------
        
    private var _horizontalScrollPosition:Number = 0;
    
    [Bindable]
    [Inspectable(category="General")]
    
    /**
     *  @copy flex.intf.IViewport#horizontalScrollPosition
     */
    public function get horizontalScrollPosition():Number 
    {
        return _horizontalScrollPosition;
    }
    
    /**
     *  @private
     */
    public function set horizontalScrollPosition(value:Number):void 
    {
        if (value == _horizontalScrollPosition) 
            return;
    
        _horizontalScrollPosition = value;
        scrollPositionChanged();
    }
    
    //----------------------------------
    //  verticalScrollPosition
    //----------------------------------

    private var _verticalScrollPosition:Number = 0;
    
    [Bindable]
    [Inspectable(category="General")]    
    
    /**
     *  @copy flex.intf.IViewport#verticalScrollPosition
     */
    public function get verticalScrollPosition():Number 
    {
        return _verticalScrollPosition;
    }
    
    /**
     *  @private
     */
    public function set verticalScrollPosition(value:Number):void 
    {
        if (value == _verticalScrollPosition)
            return;
            
        _verticalScrollPosition = value;
        scrollPositionChanged();
    }    
    
    //----------------------------------
    //  clipContent
    //----------------------------------
        
    private var _clipContent:Boolean = true;
    
    [Inspectable(category="General")]
    
    /**
     *  @copy flex.intf.IViewport#clipContent
     */
    public function get clipContent():Boolean 
    {
        return _clipContent;
    }
    
    /**
     *  @private
     */
    public function set clipContent(value:Boolean):void 
    {
        if (value == _clipContent) 
            return;
    
        _clipContent = value;
        var g:GroupBase = target;
        if (g)
            updateScrollRect(g.width, g.height);
    }
        

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @copy flex.intf.IViewport#horizontalScrollPositionDelta
     */
    public function horizontalScrollPositionDelta(unit:uint):Number
    {
        var g:GroupBase = target;
        if (!g)
            return 0;     

        var maxIndex:int = g.numLayoutItems -1;
        if (maxIndex < 0)
            return 0;

        var scrollR:Rectangle = g.scrollRect;
        if (!scrollR)
            return 0;
            
        var maxDelta:Number = g.contentWidth - scrollR.width - scrollR.x;
        var minDelta:Number = -scrollR.x; 
            
        switch (unit)
        {
            case Keyboard.UP:
                return (scrollR.x <= 0) ? 0 : -1;
                
            case Keyboard.DOWN:
                return (scrollR.x >= maxDelta) ? 0 : 1;
                
            case Keyboard.PAGE_UP:
                return Math.max(minDelta, -scrollR.width);
                
            case Keyboard.PAGE_DOWN:
                return Math.min(maxDelta, scrollR.width);
                
            case Keyboard.HOME: 
                return minDelta;
                
            case Keyboard.END: 
                return maxDelta;
                
            default:
                return 0;
        }       
    }
    
    /**
     *  @copy flex.intf.IViewport#verticalScrollPositionDelta
     */
    public function verticalScrollPositionDelta(unit:uint):Number
    {
        var g:GroupBase = target;
        if (!g)
            return 0;     

        var maxIndex:int = g.numLayoutItems -1;
        if (maxIndex < 0)
            return 0;

        var scrollR:Rectangle = g.scrollRect;
        if (!scrollR)
            return 0;
            
        var maxDelta:Number = g.contentHeight - scrollR.height - scrollR.y;
        var minDelta:Number = -scrollR.y; 
            
        switch (unit)
        {
        	case Keyboard.UP:
        	    return (scrollR.y <= 0) ? 0 : -1;
        	    
        	case Keyboard.DOWN:
        	    return (scrollR.y >= maxDelta) ? 0 : 1;
        	    
            case Keyboard.PAGE_UP:
                return Math.max(minDelta, -scrollR.height);
                
            case Keyboard.PAGE_DOWN:
                return Math.min(maxDelta, scrollR.height);
                
            case Keyboard.HOME: 
                return minDelta;
                
            case Keyboard.END: 
                return maxDelta;
                
            default:
                return 0;
        }    	
    } 
     
    /**
     *  Called when the verticalScrollPosition or horizontalScrollPosition 
     *  properties change.
     * 
     *  Resets the target's scrollRect property by calling
     *  <code>updateScrollRect()</code>.
     * 
     *  Subclasses can override this method to compute other values that are
     *  based on the current scrollPosition or scrollRect.
     * 
     *  @see updateScrollRect
     */  
    protected function scrollPositionChanged():void
    {
        var g:GroupBase = target;
        if (!g)
            return;

        updateScrollRect(g.width, g.height);
    }
    
    /**
     *  Conditionally sets the origin of the scrollRect to 
     *  verticalScrollPosition,horizontalScrollPosition and its width
     *  width,height to w,h (the target's unscaled width,height).
     * 
     *  This method must be called by updateDisplayList after the 
     *  target's contentWidth and contentHeight properties have been 
     *  set to the display list's actual limits.
     * 
     *  The target's scrollRect property is set if its contentWidth,Height
     *  is larger than its width,height, or the target's 
     *  vertical,horizontalScrollPosition is non-zero.
     * 
     *  If none of the above conditions are true, or if clipContent
     *  is false, then the scrollRect is set to null.
     * 
     *  @param w The target's unscaled width.
     *  @param h The target's unscaled height.
     * 
     *  @see target
     *  @see flash.display.DisplayObject#scrollRect
     *  @see updateDisplayList
     *  @see mx.components.GroupBase#contentWidth
     *  @see mx.components.GroupBase#contentHeight
     */ 
    protected function updateScrollRect(w:Number, h:Number):void
    {
        var g:GroupBase = target;
        if (!g)
            return;
            
        if (!clipContent)
        {
            g.scrollRect = null;
            return;
        }            

        var hsp:Number = horizontalScrollPosition;
        var vsp:Number = verticalScrollPosition;
        var cw:Number = g.contentWidth;
        var ch:Number = g.contentHeight;
            
        // Don't set the scrollRect needlessly.
        if ((hsp != 0) || (vsp != 0) || (cw > w) || (ch > h))
            g.scrollRect = new Rectangle(hsp, vsp, w, h);
        else 
            g.scrollRect = null;
    } 
    
    /**
     *  Convenience function for subclasses that invalidates the
     *  target's size and displayList if the target is non-null.
     * 
     *  @see mx.core.UIComponent#invalidateSize
     *  @see mx.core.UIComponent#invalidateDisplayList
     */
    protected function invalidateTargetSizeAndDisplayList():void
    {
        var g:GroupBase = target;
        if (!g)
            return;

        g.invalidateSize();
        g.invalidateDisplayList();
    }
    
    /**
     *  @copy mx.core.UIComponent#measure
     */
    public function measure():void
    {
    }
    
    /**
     *  @copy mx.core.UIComponent#updateDisplayList
     */
    public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
    }          
}

}