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

package mx.effects
{
import flash.events.IEventDispatcher;

import mx.effects.Effect;
import mx.effects.IEffectInstance;
import mx.effects.effectClasses.CallActionInstance;

//--------------------------------------
//  Excluded APIs
//--------------------------------------

[Exclude(name="duration", kind="property")]

/**
 * This effect, when played, calls the function specified by 
 * <code>functionName</code> on the <code>target</code> object with
 * optional <code>parameters</code>. The effect may be useful in
 * effect sequences where some function call can be choreographed
 * with other effects.
 *  
 * @see mx.effects.effectClasses.CallFunctionActionInstance
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
     */
    public function CallAction(target:Object = null)
    {
        super(target);

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
     * Name of the function that will be called on the target when this effect plays
     */
    public var functionName:String;
    
    //----------------------------------
    //  parameters
    //----------------------------------

    /** 
     * Parameters that will be supplied to the function that is called
     * by this effect
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
