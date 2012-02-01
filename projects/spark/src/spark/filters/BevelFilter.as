////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2003-2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.filters
{
import flash.events.IEventDispatcher;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.filters.BevelFilter;
import flash.filters.BitmapFilter;
import flash.filters.BitmapFilterQuality;
import flash.filters.BitmapFilterType;
import mx.filters.IFlexBitmapFilter;

/**
 *  @review 
 *  Dispatched when a property value has changed. 
 */ 
[Event(name="change", type="flash.events.Event")]

/**
 *  @review 
 * 
 * 	The mx.filters.BevelFilter class supports dynamically updating property values. 
 *  When a property changes, it dispatches an event that tells the filter owner to
 *  reapply the filter. Use this class instead of flash.filters.BevelFilter if you plan
 *  to dynamically change the filter property values.  
 * 
 *  @see flash.filters.BevelFilter
 */
public class BevelFilter extends EventDispatcher implements IFlexBitmapFilter
{
	include "../core/Version.as";
	
	//--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
	
	/**
	 * @copy flash.filters.BevelFilter
	 */ 
	public function BevelFilter(distance:Number = 4.0, angle:Number = 45, 
								highlightColor:uint = 0xFFFFFF, highlightAlpha:Number = 1.0, 
								shadowColor:uint = 0x000000, shadowAlpha:Number = 1.0, 
								blurX:Number = 4.0, blurY:Number = 4.0, strength:Number = 1, 
								quality:int = 1, type:String = "inner", 
								knockout:Boolean = false)
	{
		super();
		
		this.distance = distance;
		this.angle = angle;
		this.highlightColor = highlightColor;
		this.highlightAlpha = highlightAlpha;
		this.shadowColor = shadowColor;
		this.shadowAlpha = shadowAlpha;
		this.blurX = blurX;
		this.blurY = blurY;
		this.strength = strength;
		this.quality = quality;
		this.type = type;
		this.knockout = knockout;	
	}

	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
    //  angle
    //----------------------------------
	
	private var _angle:Number = 45;
	
	/**
	 *   The angle of the bevel. Valid values are from 0 to 360°. 
	 *   The angle value represents the angle of the theoretical light source falling on the 
	 *   object and determines the placement of the effect relative to the object. 
	 *   If the distance property is set to 0, the effect is not offset from the object and, 
	 *   therefore, the angle property has no effect.
	 * 
	 *   @default 45
	 */
	public function get angle():Number
	{
		return _angle;
	}
	
	public function set angle(value:Number):void
	{
		if (value != _angle)
		{
			_angle = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  blurX
    //----------------------------------
	
	private var _blurX:Number = 4.0;
	
	/**
	 *  The amount of horizontal blur. Valid values are 0 to 255. A blur of 1
	 *  or less means that the original image is copied as is. The default 
	 *  value is 4. Values that are a power of 2 (such as 2, 4, 8, 16, and 32) 
	 *  are optimized to render more quickly than other values.
	 */
	public function get blurX():Number
	{
		return _blurX;
	}
	
	public function set blurX(value:Number):void
	{
		if (value != _blurX)
		{
			_blurX = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  blurY
    //----------------------------------
    
	private var _blurY:Number = 4.0;
	
	/**
	 *  The amount of vertical blur. Valid values are 0 to 255. A blur of 1 
	 *  or less means that the original image is copied as is. The default 
	 *  value is 4. Values that are a power of 2 (such as 2, 4, 8, 16, and 32)
	 *  are optimized to render more quickly than other values.
	 */
	public function get blurY():Number
	{
		return _blurY;
	}
	
	public function set blurY(value:Number):void
	{
		if (value != _blurY)
		{
			_blurY = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  distance
    //----------------------------------
	
	private var _distance:Number = 4.0;
	
	/**
	 *  The offset distance of the bevel. Valid values are in pixels (floating point). 
	 * 	@default 4
	 */
	public function get distance():Number
	{
		return _distance;
	}
	
	public function set distance(value:Number):void
	{
		if (value != _distance)
		{
			_distance = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  highlightAlpha
    //----------------------------------
	
	private var _highlightAlpha:Number = 1.0;
	
	/**
	 *  The alpha transparency value of the highlight color. The value is specified as a normalized 
	 *  value from 0 to 1. For example, .25 sets a transparency value of 25%. 
	 *  @default 1
	 */
	public function get highlightAlpha():Number
	{
		return _highlightAlpha;
	}
	
	public function set highlightAlpha(value:Number):void
	{
		if (value != _highlightAlpha)
		{
			_highlightAlpha = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  highlightColor
    //----------------------------------
	
	private var _highlightColor:uint = 0xFFFFFF;
	
	/**
	 *  The highlight color of the bevel. Valid values are in hexadecimal format, 0xRRGGBB. 
	 *  @default 0xFFFFFF
	 */
	public function get highlightColor():uint
	{
		return _highlightColor;
	}
	
	public function set highlightColor(value:uint):void
	{
		if (value != _highlightColor)
		{
			_highlightColor = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  knockout
    //----------------------------------
	
	private var _knockout:Boolean = false;
	
	/**
	 *  Specifies whether the object has a knockout effect. A knockout effect
	 *  makes the object's fill transparent and reveals the background color 
	 *  of the document. The value true specifies a knockout effect; the 
	 *  default value is false (no knockout effect).
	 */
	public function get knockout():Boolean
	{
		return _knockout;
	}
	
	public function set knockout(value:Boolean):void
	{
		if (value != _knockout)
		{
			_knockout = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  quality
    //----------------------------------
	
	private var _quality:int = BitmapFilterQuality.LOW;
	
	/**
	 *  The number of times to apply the filter. The default value is 
	 *  BitmapFilterQuality.LOW, which is equivalent to applying the filter 
	 *  once. The value BitmapFilterQuality.MEDIUM  applies the filter twice; 
	 *  the value BitmapFilterQuality.HIGH applies it three times. Filters 
	 *  with lower values are rendered more quickly. 
	 * 
	 *  For most applications, a quality value of low, medium, or high is 
	 *  sufficient. Although you can use additional numeric values up to 15 
	 *  to achieve different effects, higher values are rendered more slowly. 
	 *  Instead of increasing the value of quality, you can often get a similar 
	 *  effect, and with faster rendering, by simply increasing the values of 
	 *  the blurX and blurY properties.
	 */
	public function get quality():int
	{
		return _quality;
	}
	
	public function set quality(value:int):void
	{
		if (value != _quality)
		{
			_quality = value;
			notifyFilterChanged();
		}
	}
			
	//----------------------------------
    //  shadowAlpha
    //----------------------------------
	
	private var _shadowAlpha:Number = 1.0;
	
	/**
	 *  The alpha transparency value of the shadow color. This value is specified as a 
	 *  normalized value from 0 to 1. For example, .25 sets a transparency value of 25%.
	 * 
	 *  @default 1
	 */
	public function get shadowAlpha():Number
	{
		return _shadowAlpha;
	}
	
	public function set shadowAlpha(value:Number):void
	{
		if (value != _shadowAlpha)
		{
			_shadowAlpha = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  shadowColor
    //----------------------------------
	
	private var _shadowColor:uint = 0x000000;
	
	/**
	 *  The shadow color of the bevel. Valid values are in hexadecimal format, 0xRRGGBB. 
	 *  @default 0x000000
	 */
	public function get shadowColor():uint
	{
		return _shadowColor;
	}
	
	public function set shadowColor(value:uint):void
	{
		if (value != _shadowColor)
		{
			_shadowColor = value;
			notifyFilterChanged();
		}
	}
	
	//----------------------------------
    //  strength
    //----------------------------------
	
	private var _strength:Number = 1;
	
	/**
	 *  The strength of the imprint or spread. The higher the value, the more 
	 *  color is imprinted and the stronger the contrast between the glow and 
	 *  the background. Valid values are 0 to 255. A value of 0 means that the 
	 *  filter is not applied. The default value is 1. 
	 */
	public function get strength():Number
	{
		return _strength;
	}
	
	public function set strength(value:Number):void
	{
		if (value != _strength)
		{
			_strength = value;
			notifyFilterChanged();
		}
	}	
		
	//----------------------------------
    //  type
    //----------------------------------
	
	private var _type:String = BitmapFilterType.INNER;
	
	/**
	 *  The placement of the filter effect. Possible values are 
	 *  flash.filters.BitmapFilterType constants:
 	 *  BitmapFilterType.OUTER — Glow on the outer edge of the object
	 *  BitmapFilterType.INNER — Glow on the inner edge of the object; the default.
	 *  BitmapFilterType.FULL — Glow on top of the object
	 */
	public function get type():String
	{
		return _type;
	}
	
	public function set type(value:String):void
	{
		if (value != _type)
		{
			_type = value;
			notifyFilterChanged();
		}
	}

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
   
   	/**
     * @private
     * Notify of a change to our filter, so that filter stack is ultimately 
     * re-applied by the framework.
     */ 
	private function notifyFilterChanged():void
	{
		dispatchEvent(new Event(Event.CHANGE));
	}

	//--------------------------------------------------------------------------
	//
	//  IFlexBitmapFilter 
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  Creates a flash.filters.BevelFilter instance using the current 
	 *  property values. 
	 * 
	 *  @return flash.filters.BevelFilter instance
	 */
	public function createBitmapFilter():BitmapFilter 
	{
		return new flash.filters.BevelFilter(distance, angle, highlightColor, highlightAlpha,
											 shadowColor, shadowAlpha, blurX, blurY, strength,
											 quality, type, knockout);
	} 

}

}