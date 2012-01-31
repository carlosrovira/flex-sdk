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

package spark.effects
{
import flash.events.IEventDispatcher;

import mx.effects.Effect;
import mx.effects.IEffectInstance;
import spark.effects.supportClasses.CallActionInstance;

//--------------------------------------
//  Excluded APIs
//--------------------------------------

[Exclude(name="duration", kind="property")]

/**
 * The CallAction effect calls the function specified by 
 * <code>functionName</code> property on the <code>target</code> object with
 * optional parameters specified by the <code>parameters</code> property. 
 * The effect is useful in
 * effect sequences where some function call can be choreographed
 * with other effects.
 *  
 *  @mxml
 *
 *  <p>The <code>&lt;mx:CallAction&gt;</code> tag
 *  inherits all of the tag attributes of its superclass,
 *  and adds the following tag attributes:</p>
 *
 *  <pre>
 *  &lt;mx:CallAction
 *    <b>Properties</b>
 *    id="ID"
 *    functionName="no default"
 *    parameters="no default"
 *  /&gt;
 *  </pre>
 *  
 * @see spark.effects.supportClasses.CallActionInstance
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class CallAction extends Effect
{
    include "../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     *
     *  @param target The Object to animate with this effect.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function CallAction(target:Object = null)
    {
        super(target);
        duration = 0;
        instanceClass = CallActionInstance;
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  functionName
    //----------------------------------

    /** 
     * Name of the function called on the target when this effect plays.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var functionName:String;
    
    //----------------------------------
    //  parameters
    //----------------------------------

    /** 
     * Parameters passed to the function that is called
     * by this effect.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var parameters:Array;

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    override protected function initInstance(instance:IEffectInstance):void
    {
        super.initInstance(instance);
        
        var callInstance:CallActionInstance = CallActionInstance(instance);

        callInstance.functionName = functionName;
        callInstance.parameters = parameters;
    }

}

}
