////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2003-2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.accessibility
{

import flash.accessibility.Accessibility;
import flash.events.Event;
import mx.containers.TabNavigator;
import mx.controls.TabBar;
import mx.controls.tabBarClasses.Tab;
import mx.core.UIComponent;
import mx.core.mx_internal;

use namespace mx_internal;

/**
 *  TabBarAccImpl is a subclass of AccessibilityImplementation
 *  which implements accessibility for the TabBar class.
 */
public class TabBarAccImpl extends AccImpl
{
    include "../core/Version.as";

	//--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	private static const ROLE_SYSTEM_PAGETAB:uint = 0x25;

	/**
	 *  @private
	 */
	private static const STATE_SYSTEM_FOCUSABLE:uint = 0x00100000;

	/**
	 *  @private
	 */
	private static const STATE_SYSTEM_FOCUSED:uint = 0x00000004;

	/**
	 *  @private
	 */
	private static const STATE_SYSTEM_SELECTABLE:uint = 0x00200000;

	/**
	 *  @private
	 */
	private static const STATE_SYSTEM_SELECTED:uint = 0x00000002;

	/**
	 *  @private
	 */
	private static const EVENT_OBJECT_FOCUS:uint = 0x8005;

	/**
	 *  @private
	 */
	private static const EVENT_OBJECT_SELECTION:uint = 0x8006;

	/**
	 *  @private
	 */
	private static const MAX_NUM:uint = 100000;	

	//--------------------------------------------------------------------------
	//
	//  Class methods
	//
	//--------------------------------------------------------------------------

	/**
	 *  Enables accessibility in the TabBar class.
	 * 
	 *  <p>This method is called by application startup code
	 *  that is autogenerated by the MXML compiler.
	 *  Afterwards, when instances of TabBar are initialized,
	 *  their <code>accessibilityImplementation</code> property
	 *  will be set to an instance of this class.</p>
	 */
	public static function enableAccessibility():void
	{
		TabBar.createAccessibilityImplementation =
			createAccessibilityImplementation;
	}

	/**
	 *  @private
	 *  Creates a TabBar's AccessibilityImplementation object.
	 *  This method is called from UIComponent's
	 *  initializeAccessibility() method.
	 */
	mx_internal static function createAccessibilityImplementation(
								component:UIComponent):void
	{
		component.accessibilityImplementation =
			new TabBarAccImpl(component);
	}

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 *
	 *  @param master The UIComponent instance that this AccImpl instance
	 *  is making accessible.
	 */
	public function TabBarAccImpl(master:UIComponent)
	{
		super(master);

		role = 0x3C; // ROLE_SYSTEM_PAGETABLIST
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden properties: AccImpl
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  eventsToHandle
	//----------------------------------

	/**
	 *  @private
	 *	Array of events that we should listen for from the master component.
	 */
	override protected function get eventsToHandle():Array
	{
		return super.eventsToHandle.concat([ "itemClick", "focusDraw" ]);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods: AccessibilityImplementation
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  Gets the role for the component.
	 *
	 *  @param childID children of the component
	 */
	override public function get_accRole(childID:uint):uint
	{
		return childID == 0 ? role : ROLE_SYSTEM_PAGETAB;
	}

	/**
	 *  @private
	 *  IAccessible method for returning the state of the Tabs.
	 *  States are predefined for all the components in MSAA. Values are assigned to each state.
	 *  Depending upon the Tab being Focusable, Focused and Moveable, a value is returned.
	 *
	 *  @param childID:uint
	 *
	 *  @return STATE:uint
	 */
	override public function get_accState(childID:uint):uint
	{
		var accState:uint = getState(childID);

		var tabBar:TabBar = TabBar(master);
		
		if (childID > 0)
		{
			accState = STATE_SYSTEM_SELECTABLE | STATE_SYSTEM_FOCUSABLE;

			var index:int = childID < MAX_NUM ? 
					childID - 1 : childID - MAX_NUM - 1;

			if (index == tabBar.selectedIndex)
				accState |= STATE_SYSTEM_SELECTED;
				
			if (index == tabBar.focusedIndex)
				accState |= STATE_SYSTEM_FOCUSED;
		}		
		return accState;
	}

	/**
	 *  @private
	 *  IAccessible method for returning the Default Action.
	 *
	 *  @param childID uint
	 *
	 *  @return focused childID.
	 */
	override public function get_accDefaultAction(childID:uint):String
	{
		return "Switch";
	}

	/**
	 *  @private
	 *  IAccessible method for executing the Default Action.
	 *
	 *  @param childID uint
	 *
	 *  @return focused childID.
	 */
	override public function accDoDefaultAction(childID:uint):void
	{
		if (childID > 0)
		{
			var index:int = childID < MAX_NUM ?
						    childID - 1 :
							childID - MAX_NUM - 1;

			TabBar(master).selectButton(index, true);
		}
	}

	/**
	 *  @private
	 *  Method to return the childID Array.
	 *
	 *  @return Array
	 */
	override public function getChildIDArray():Array
	{
		var childIDs:Array = [];
		
		var n:int = TabBar(master).numChildren;
		for (var i:int = 0; i < n; i++)
		{
			childIDs[i] = i + 1;
		}
		
		return childIDs;
	}

	/**
	 *  @private
	 *  IAccessible method for returning the bounding box of the Tabs.
	 *
	 *  @param childID:uint
	 *
	 *  @return Location:Object
	 */
	override public function accLocation(childID:uint):*
	{
		var index:int = childID < MAX_NUM ?
						childID - 1 :
						childID - MAX_NUM - 1;

		return TabBar(master).getChildAt(index);
	}

	/**
	 *  @private
	 *  IAccessible method for returning the childFocus of the TabBar.
	 *
	 *  @param childID uint
	 *
	 *  @return focused childID.
	 */
	override public function get_accFocus():uint
	{
		var index:int = TabBar(master).focusedIndex;
		
		return index >= 0 ? index + 1 : 0;
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden methods: AccImpl
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  method for returning the name of the Tab
	 *  which is spoken out by the screen reader.
	 *
	 *  @param childID:uint
	 *
	 *  @return Name:String
	 */
	override protected function getName(childID:uint):String
	{
		if (childID == 0)
			return "";

		var name:String;

		var tabBar:TabBar = TabBar(master);
		// Assuming childID is always ItemID + 1
		// because getChildIDArray is not always invoked.
		var index:int = childID < MAX_NUM ?
						childID - 1 :
						childID - MAX_NUM - 1;
		//With new version of JAWS, when we add a new child, we get nonsense number
		//not caught above. In this case, return last tab.
		if (index > tabBar.numChildren || index < 0)
			index = tabBar.numChildren -1;
		var item:Tab = Tab(tabBar.getChildAt(index));

		name = item.label;

		if (index == tabBar.selectedIndex)
			name += " Tab, Active";
		else
			name += " Tab";

		return name;
	}

	//--------------------------------------------------------------------------
	//
	//  Overridden event handlers: AccImpl
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 *  Override the generic event handler.
	 *  All AccImpl must implement this to listen for events
	 *  from its master component. 
	 */
	override protected function eventHandler(event:Event):void
	{
		var index:int;
				
		switch (event.type)
		{
			case "focusDraw":
			{
				index = TabBar(master).focusedIndex;
				
				if (index >= 0)
				{
					Accessibility.sendEvent(master, index + MAX_NUM + 1,
											EVENT_OBJECT_FOCUS);
				}
				break;
			}
			
			case "itemClick":
			{
				// use selectedIndex until #126565 is fixed.
				index = TabBar(master).selectedIndex;
				
				if (index >= 0)
				{
					Accessibility.sendEvent(master, index + 1,
											EVENT_OBJECT_SELECTION);
				}
				break;
			}
		}
	}
}

}
