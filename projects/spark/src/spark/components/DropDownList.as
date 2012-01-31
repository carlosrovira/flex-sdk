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

/*  NOTES

Keyboard Interaction
- List current dispatches selectionChanged on arrowUp/Down. Should we subclass List
and change behavior to commit value only on ENTER, SPACE, or CTRL-UP?

- Handle commitData 
- Add typicalItem support for measuredSize (lower priority) 

*  @langversion 3.0
*  @playerversion Flash 10
*  @playerversion AIR 1.5
*  @productversion Flex 4

*/

package spark.components
{

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;

import mx.collections.IList;
import mx.core.mx_internal;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;

import spark.components.supportClasses.ButtonBase;
import spark.components.supportClasses.DropDownController;
import spark.components.supportClasses.ListBase;
import spark.events.DropDownEvent;
import spark.layouts.VerticalLayout;
import spark.layouts.supportClasses.LayoutBase;
import spark.primitives.supportClasses.TextGraphicElement;
import spark.utils.LabelUtil;

/**
 *  Dispatched when the dropDown is dismissed for any reason such when 
 *  the user:
 *  <ul>
 *      <li>selects an item in the dropDown</li>
 *      <li>clicks outside of the dropDown</li>
 *      <li>clicks the dropDown button while the dropDown is 
 *  displayed</li>
 *  </ul>
 *
 *  @eventType spark.events.DropDownEvent.CLOSE
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Event(name="close", type="spark.events.DropDownEvent")]

/**
 *  Dispatched when the user clicks the dropDown button
 *  to display the dropDown.  It is also dispatched if the user
 *  uses the keyboard and types Ctrl-Down to open the dropDown.
 *
 *  @eventType spark.events.DropDownEvent.OPEN
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Event(name="open", type="spark.events.DropDownEvent")]

/**
 *  Open State of the DropDown component
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[SkinState("open")]


//--------------------------------------
//  Excluded APIs
//--------------------------------------

[Exclude(name="allowMultipleSelection", kind="property")]
[Exclude(name="selectedIndices", kind="property")]
[Exclude(name="selectedItems", kind="property")]


/**
 *  DropDownList control contains a drop-down list
 *  from which the user can select a single value.
 *  Its functionality is very similar to that of the
 *  SELECT form element in HTML.
 * 
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class DropDownList extends List
{
 
    //--------------------------------------------------------------------------
    //
    //  Skin Parts
    //
    //--------------------------------------------------------------------------	
    /**
     *  An optional skin part that holds the prompt or the text of the selectedItem 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    [SkinPart(required="false")]
    public var labelElement:TextGraphicElement;
	
	/**
     *  A skin part that defines the dropDown area. When the DropDownList is open,
     *  clicking anywhere outside of the dropDown skin part will close the   
     *  DropDownList. 
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    [SkinPart(required="false")]
    public var dropDown:DisplayObject;
    
    /**
     *  A skin part that defines the anchor button.  
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    [SkinPart(required="true")]
    public var openButton:ButtonBase;
    	
	/**
     *  Constructor. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
	public function DropDownList()
	{
		super();
		super.allowMultipleSelection = false;
		
		dropDownController = new DropDownController();
	}
	
	//--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
	
    private var labelChanged:Boolean = false;
    // TODO (jszeto) Should this be protected?
    private var proposedSelectedIndex:Number = -1;
	
	//--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
	
	//----------------------------------
    //  dropDownController
    //----------------------------------
	
	private var _dropDownController:DropDownController;	
	
	/**
     *  Instance of the helper class that handles all of the mouse, keyboard 
     *  and focus user interactions. The type of this class is determined by the
     *  <code>dropDownControllerClass</code> property. 
     * 
     *  The <code>initializeDropDownController()</code> function is called after 
     *  the dropDownController is created in the constructor.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
	protected function get dropDownController():DropDownController
	{
		return _dropDownController;
	}
	
	protected function set dropDownController(value:DropDownController):void
	{
		if (_dropDownController == value)
			return;
			
		_dropDownController = value;
			
		_dropDownController.addEventListener(DropDownEvent.OPEN, dropDownController_openHandler);
		_dropDownController.addEventListener(DropDownEvent.CLOSE, dropDownController_closeHandler);
			
		if (openButton)
			_dropDownController.openButton = openButton;
		if (dropDown)
			_dropDownController.dropDown = dropDown;	
	}

	//----------------------------------
    //  prompt
    //----------------------------------

    private var _prompt:String = "";

    /**
     *  The prompt for the DropDownList control. A prompt is
     *  a String that is displayed in the TextInput portion of the
     *  DropDownList when <code>selectedIndex</code> = -1.  It is usually
     *  a String like "Select one...". 
     *  
     *  @default ""
     *       
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get prompt():String
    {
        return _prompt;
    }

    /**
     *  @private
     */
    public function set prompt(value:String):void
    {
    	if (_prompt == value)
    		return;
    		
    	_prompt = value;
        labelChanged = true;
        invalidateProperties();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  allowMultipleSelection
    //----------------------------------
    
    /**
     *  @private
     */
    override public function set allowMultipleSelection(value:Boolean):void
    {
    	// Don't allow this value to be set
        return;
    }
    
    //----------------------------------
    //  baselinePosition
    //----------------------------------
    
    /**
     *  @private
     */
    override public function get baselinePosition():Number
    {
    	if (openButton)
    		return openButton.baselinePosition;
    	else
    		return NaN;
    }
    
    //----------------------------------
    //  dataProvider
    //----------------------------------
    
    /**
     *  @private
     *  Update the label if the dataProvider has changed
     */
    override public function set dataProvider(value:IList):void
    {	
    	if (dataProvider === value)
    		return;
    		
    	super.dataProvider = value;
    	labelChanged = true;
    	invalidateProperties();
    }
    
    //----------------------------------
    //  enabled
    //----------------------------------
    
    /**
     *  @private
     */
    override public function set enabled(value:Boolean):void
    {
    	if (value == enabled)
    		return;
    	
    	super.enabled = value;
    	if (openButton)
    		openButton.enabled = value;
    }
    
    //----------------------------------
    //  labelField
    //----------------------------------
    
     /**
     *  @private
     */
    override public function set labelField(value:String):void
    {
    	if (labelField == value)
    		return;
    		
    	super.labelField = value;
    	labelChanged = true;
    	invalidateProperties();
    }
    
    //----------------------------------
    //  labelFunction
    //----------------------------------
    
    /**
     *  @private
     */
    override public function set labelFunction(value:Function):void
    {
    	if (labelFunction == value)
    		return;
    		
    	super.labelFunction = value;
    	labelChanged = true;
    	invalidateProperties();
    }
    
    //----------------------------------
    //  layout
    //----------------------------------
    
    /**
     *  @private
     */
    override public function get layout():LayoutBase
    {
    	// Since the dataGroup is optional, if it doesn't exist yet,
    	// then just default to using a VerticalLayout so that keyboard
        // navigation will still work. 
        return (dataGroup) 
            ? super.layout 
            : new VerticalLayout();
    }
    
    //----------------------------------
    //  selectedIndices
    //----------------------------------
    
    /**
     *  @private
     */
    override public function set selectedIndices(value:Array):void
    {
    	throw new Error(resourceManager.getString("components", "selectedIndicesDropDownListError"));
    }
    
    //----------------------------------
    //  selectedItems
    //----------------------------------
    
    /**
     *  @private
     */
    override public function set selectedItems(value:Array):void
    {
    	throw new Error(resourceManager.getString("components", "selectedItemsDropDownListError"));
    }
    
    
 	//--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------   

	/**
     *  Opens the dropDown. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */ 
    public function openDropDown():void
    {
    	dropDownController.openDropDown();
    }
	
	 /**
     *  Closes the dropDown. 
     *   
     *  @param commit Flag indicating if the component should commit the selected
     *  data from the dropDown. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function closeDropDown(commit:Boolean):void
    {
    	dropDownController.closeDropDown(commit);
    }
	
	/**
     *  @private
     *  Called whenever we need to update the text passed to the labelElement skin part
     */
    // TODO (jszeto) Make this protected and make the name more generic (passing data to skin) 
	private function updateLabelElement():void
	{
		if (labelElement)
    	{
    		if (selectedItem)
    			labelElement.text = LabelUtil.itemToLabel(selectedItem, labelField, labelFunction);
	    	else
	    		labelElement.text = prompt;
    	}	
	}
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------
	
	/**
	 *  @private
	 */ 
	override protected function commitSelectedIndex():Boolean
    {
    	var result:Boolean = super.commitSelectedIndex();
       	updateLabelElement();
   
    	return result;   	
    }
    
    /**
 	 *  @private
 	 */ 
	override protected function commitProperties():void
    {
        super.commitProperties();
        
        if (labelChanged)
		{
			labelChanged = false;
        	updateLabelElement();
  		}
    }
    
    /**
 	 *  @private
 	 */ 
    override protected function dataProvider_collectionChangeHandler(event:Event):void
    {    	
    	super.dataProvider_collectionChangeHandler(event);
    	
    	if (event is CollectionEvent)
        {
			labelChanged = true;
			invalidateProperties();        	
        }
    }
       
    /**
 	 *  @private
 	 */ 
    override protected function getCurrentSkinState():String
    {
		return !enabled ? "disabled" : dropDownController.isOpen ? "open" : "normal";
    }   
       
    /**
	 *  @private
	 */ 
    override protected function partAdded(partName:String, instance:Object):void
    {
    	super.partAdded(partName, instance);
 
 		if (instance == openButton)
    	{
    		if (dropDownController)
    			dropDownController.openButton = openButton;
    		openButton.enabled = enabled;
    	}
    	
    	if (instance == labelElement)
    	{
    		labelChanged = true;
        	invalidateProperties();
    	}
    	
    	if (instance == dropDown && dropDownController)
    		dropDownController.dropDown = dropDown;
    }
    
    /**
     *  @private
     */
    override protected function partRemoved(partName:String, instance:Object):void
    {
    	if (dropDownController)
    	{
    		if (instance == openButton)
	    		dropDownController.openButton = null;
    	
    		if (instance == dropDown)
    			dropDownController.dropDown = null;
     	}
     	
        super.partRemoved(partName, instance);
    }
    
    /**
     *  @private
     */
    override protected function item_clickHandler(event:MouseEvent):void
	{
		super.item_clickHandler(event);
		proposedSelectedIndex = selectedIndex;
		closeDropDown(true);
	}
            
    /**
	 *  @private
	 */
	override protected function keyDownHandler(event:KeyboardEvent) : void
	{
		if(!enabled)
            return; 
        
        if (!dropDownController.processKeyDown(event))
        {
			if (dropDownController.isOpen)
			{	
	        	var navigationUnit:uint = mapEventToNavigationUnit(event);
	        	var proposedNewIndex:int = layout.getDestinationIndex(navigationUnit, proposedSelectedIndex)
	        	
	        	if (proposedNewIndex != -1)
	        	{
	        		itemSelected(proposedSelectedIndex, false);
	        		proposedSelectedIndex = proposedNewIndex;
	        		itemSelected(proposedSelectedIndex, true);
	        		ensureItemIsVisible(proposedSelectedIndex);
	        	}
	   		}
	   		else
	   		{
	   			super.keyDownHandler(event);
	   		}
        }

	}
	
	/**
     *  @private
     */
    override protected function focusOutHandler(event:FocusEvent):void
    {
		dropDownController.processFocusOut(event);

        super.focusOutHandler(event);
    }
    
    //--------------------------------------------------------------------------
    //
    //  Event handling
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Event handler for the <code>dropDownController</code> 
     *  <code>DropDownEvent.OPEN</code> event. Updates the skin's state and 
     *  ensures that the selectedItem is visible. 
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function dropDownController_openHandler(event:DropDownEvent):void
    {
    	addEventListener(FlexEvent.UPDATE_COMPLETE, open_updateCompleteHandler);
    	proposedSelectedIndex = selectedIndex;
    	invalidateSkinState();	
    }
    
    /**
     *  @private
     */
    private function open_updateCompleteHandler(event:FlexEvent):void
	{	
		removeEventListener(FlexEvent.UPDATE_COMPLETE, open_updateCompleteHandler);
    	ensureItemIsVisible(selectedIndex);
    	
		dispatchEvent(new DropDownEvent(DropDownEvent.OPEN));
	}
    
    /**
     *  Event handler for the <code>dropDownController</code> 
     *  <code>DropDownEvent.CLOSE</code> event. Updates thbe skin's state.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function dropDownController_closeHandler(event:DropDownEvent):void
    {
    	addEventListener(FlexEvent.UPDATE_COMPLETE, close_updateCompleteHandler);
    	invalidateSkinState();
    	
    	if (!event.isDefaultPrevented())
    	{
    		selectedIndex = proposedSelectedIndex;	
    	}
    }

	/**
     *  @private
     */
    private function close_updateCompleteHandler(event:FlexEvent):void
	{	
		removeEventListener(FlexEvent.UPDATE_COMPLETE, close_updateCompleteHandler);
    	
		dispatchEvent(new DropDownEvent(DropDownEvent.CLOSE));
	}
	
}
}
