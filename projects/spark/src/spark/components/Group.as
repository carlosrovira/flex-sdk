package flex.core {
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.geom.Transform;
import flash.utils.Dictionary;

import flex.events.FlexEvent;
import flex.events.ItemExistenceChangedEvent;
import flex.intf.ILayout; 
import flex.layout.BasicLayout;

import mx.collections.IList;
import flex.graphics.Graphic;
import mx.controls.Label;
import mx.core.IDataRenderer;
import mx.core.IDeferredInstance;
import mx.core.IFactory;
import mx.core.UIComponent;
import mx.events.ChildExistenceChangedEvent;
import mx.events.CollectionEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;
import flex.graphics.IAssignableDisplayObjectElement;
import flex.graphics.IDisplayObjectElement;
import flex.graphics.IGraphicElement;
import flex.graphics.IGraphicElementHost;
import mx.managers.ILayoutManagerClient;
import flex.graphics.MaskType;
import flex.geom.Transform;
import flex.graphics.TransformUtil;
import flex.filters.IBitmapFilter;
import flex.filters.BaseFilter;
import mx.collections.ICollectionView;
import mx.collections.ListCollectionView;

/**
 *  Dispatched prior to the group's content being changed. This is only
 *  dispatched when all content of the group is changing.
 */
[Event(name="contentChanging", type="flex.events.FlexEvent")]

/**
 *  Dispatched after the group's content has changed. This is only
 *  dispatched when all content of the group has changed.
 */
[Event(name="contentChanged", type="flex.events.FlexEvent")]

/**
 *  Dispatched when an item is added to the content holder.
 *  event.relatedObject is the visual item that was added.
 */
[Event(name="itemAdd", type="flex.events.ItemExistenceChangedEvent")]

/**
 *  Dispatched when an item is removed from the content holder.
 *  event.relatedObject is the visual item that was removed.
 */
[Event(name="itemRemove", type="flex.events.ItemExistenceChangedEvent")]

[DefaultProperty("content")] 

/**
 *  The Group class.
 */
public class Group extends UIComponent implements IDataRenderer, IGraphicElementHost // TODO!! , IDisplayObjectElement
{
    public function Group():void
    {
    	tabChildren = true;
    }
    
    private var skinRegistry:Dictionary;
    private var contentChanged:Boolean = false;
    private var layoutChanged:Boolean = true;
    private var transformChanged:Boolean = false;
    
    // item renderer
    public var itemRenderer:IFactory;   
    public var itemRendererFunction:Function; // signature: itemRendererFunction(item:*):IFactory
    public var alwaysUseItemRenderer:Boolean = false; // if true, always use the itemRenderer
    private var _layoutClass:Class;
    private var _layout:ILayout;
    private var _content:*;
    private var _contentType:int;
    private var contentCollection:ICollectionView;
    
    private static const CONTENT_TYPE_UNKNOWN:int = 0;
    private static const CONTENT_TYPE_ARRAY:int = 1;
    private static const CONTENT_TYPE_ILIST:int = 2;
    
    public function set content(value:*):void
    {
        if (contentCollection)
        {
            contentCollection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
            contentCollection = null;
        }
        
        _content = value;
        
        // Need to convert null to undefined here, since subsequent content checks test for undefined
        if (_content === null)
            _content = undefined;
            
        if (_content is IList)
        {
            _contentType = CONTENT_TYPE_ILIST;
            contentCollection = new ListCollectionView(IList(_content));
            contentCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
        }
        else if (_content is Array)
            _contentType = CONTENT_TYPE_ARRAY;
        else
            _contentType = CONTENT_TYPE_UNKNOWN;
            
        contentChanged = true;
        invalidateProperties();
    }
    
    public function get content():*
    {
        return _content;
    }
    
    private var _data:Object;
    [Bindable]
    public function get data():Object
    {
        return _data;
    }
    
    public function set data(value:Object):void
    {
        _data = value;
    }
    
    public function get layout():Class
    {
        return _layoutClass;
    }
    
    public function set layout(value:Class):void
    {
        _layoutClass = value;
        
        layoutChanged = true;
        invalidateProperties();
    }

    protected function initializeChildrenArray():void
    {   
    	dispatchEvent(new FlexEvent(FlexEvent.CONTENT_CHANGING));  
    	  
        // Get rid of existing display object children.
        // !!!!! This should probably be done through change notification
        // TODO!! This should be removing the last child b/c we want to 
        // send an event for each content child. This logic will send
        // remove event for the 0th content child x times. 
        for (var idx:int = numChildren; idx > 0; idx--)
            itemRemoved(0);
        
        if (_content !== undefined)
        {
            for (var i:int = 0; i < numItems; i++)
            {
                itemAdded(getItemAt(i), i);
            }
        }
        
        if (maskElements)
        {
            for (var k:Object in maskElements)
            {
                var maskElement:DisplayObject = k as DisplayObject;
                if (maskElement && (!maskElement.parent || maskElement.parent !== this))
                {
                    super.addChild(maskElement);
                    var maskComp:UIComponent = maskElement as UIComponent;
                    if (maskComp)
                    {
                        maskComp.validateNow();
                        maskComp.setActualSize(maskComp.getExplicitOrMeasuredWidth(), 
                                               maskComp.getExplicitOrMeasuredHeight());
                    }
                    
                    var maskTarget:IGraphicElement = maskElements[k] as IGraphicElement;
                    if (maskTarget)
                    {
                        maskTarget.applyMask();
                    }
                }
            }
        }
        
        dispatchEvent(new FlexEvent(FlexEvent.CONTENT_CHANGED)); 
    }
    
    protected function createVisualForItem(item:*):DisplayObject
    {
        var itemSkin:DisplayObject;
        
        if (item === undefined || item === null)
            throw new Error("Group content can not contain null or undefined items.");
        
        // Rules for skin lookup:
        // 0. if the item is a deferred instance, instantiate it and fall through to the other item(s)
        // 1. if the item is a display object, use it directly
        // 2. if itemRendererFunction is defined, call it to get the renderer factory and instantiate it
        // 3. if itemRenderer is defined, instantiate one
        // 4. create a Label component and call toString() on the item
            
        // 0. if the item is a deferred instance, instantiate it and fall through to the other item(s)
        if (item is IDeferredInstance)
            item = IDeferredInstance(item).getInstance();
        
        // 1. if the item is a display object, use it directly unless the alwaysUseItemRenderer
        // flag is set.
        if (item is DisplayObject && !(alwaysUseItemRenderer && (itemRenderer || itemRendererFunction)))
            itemSkin = item;
            
        // 2. if itemRendererFunction is defined, call it to get the renderer factory and instantiate it
        if (!itemSkin && itemRendererFunction != null)
        {
            var rendererFactory:IFactory = itemRendererFunction(item);
            
            if (rendererFactory)
                itemSkin = rendererFactory.newInstance();
        }
        
        // 3. if itemRenderer is defined, instantiate one
        if (!itemSkin && itemRenderer != null)
            itemSkin = itemRenderer.newInstance();
                    
        // 4. create a Label component and call toString() on the item
        if (!itemSkin)
        {
            // No custom skin, use a Label
            itemSkin = new Label();
            Label(itemSkin).condenseWhite = true;
            Label(itemSkin).htmlText = item.toString();
        }
        
        // Set the skin data to the item, but only if the item and skin are different
        if (itemSkin is IDataRenderer && itemSkin != item)
            IDataRenderer(itemSkin).data = item;
    
        registerSkin(item, itemSkin);

        return itemSkin;
    }
    
    protected function registerSkin(item:*, itemSkin:DisplayObject):void
    {
        if (!skinRegistry)
            skinRegistry = new Dictionary(true);
        
        skinRegistry[item] = itemSkin;
    }
    
    protected function unregisterSkin(item:*, itemSkin:DisplayObject):void
    {
        if (!skinRegistry)
            return;
        
        delete skinRegistry[item];
    }
    
    override protected function commitProperties():void
    {
        super.commitProperties();
        
        if (layoutChanged)
        {
            layoutChanged = false;
            initializeLayoutObject();
        }
        
        if (contentChanged)
        {
            contentChanged = false;
            initializeChildrenArray();
            
            maskChanged = true;
        }
                
        if (maskChanged)
        {
            maskChanged = false;
            if (_mask && (!_mask.parent || _mask.parent !== this))
            {
                super.addChild(_mask);
                if (_mask is UIComponent)
                {
                    var maskComp:UIComponent = _mask as UIComponent;
                    maskComp.validateSize();
                    maskComp.setActualSize(maskComp.getExplicitOrMeasuredWidth(), 
                                           maskComp.getExplicitOrMeasuredHeight());
                }
            }
        }
        
        if (maskTypeChanged)    
        {
            maskTypeChanged = false;
            
            if (_mask)
            {
                if (_maskType == MaskType.CLIP)
                {
                    // Turn off caching on mask
                    _mask.cacheAsBitmap = false;
                    // Save the original filters and clear the filters property
                    originalMaskFilters = _mask.filters;
                    _mask.filters = []; 
                }
                else if (_maskType == MaskType.ALPHA)
                {
                    _mask.cacheAsBitmap = true;
                    cacheAsBitmap = true;
                }
            }
        }
    }
    
    override protected function measure():void
    {
        super.measure();
        
        if (_layout)
            _layout.measure();
    }
    
    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
        super.updateDisplayList(unscaledWidth, unscaledHeight);

        // TODO!!! Move this above the GraphicElement drawing once layout objects 
        // understand how to layout GraphicElements. 
        if (_layout)
            _layout.updateDisplayList(unscaledWidth, unscaledHeight);

        // Iterate through the graphic elements, clear their graphics and draw them
        var length:int = numItems;
        for (var i:int = 0; i < length; i++)
        {
            var element:IGraphicElement = getItemAt(i) as IGraphicElement;
            
            if (element && !alwaysUseItemRenderer)
            {
                var g:Graphics;
                var elementShape:Shape = elementToDisplayObjectMap[element] as Shape;
                if (elementShape)
                {
                    g = elementShape.graphics;
                }
                else
                {
                    var elementSprite:Sprite = elementToDisplayObjectMap[element] as Sprite;
                    if (elementSprite)
                        g = elementSprite.graphics;
                }
                                
                if (g)
                {
                    g.clear();
                    if (element.visible)
                        element.draw(g); 
                }
            }
        }
            
        if (transformChanged)
        {
            transformChanged = false;
            // Apply the transform props or matrix
            TransformUtil.applyTransforms(this, _matrix, _x, _y, _scaleX, _scaleY, 
                                          _rotation, _transformX, _transformY);
        }
    }
    
    override public function addChild(child:DisplayObject):DisplayObject
    {
        throw(new Error("addChild is not available in Group. Use addItem instead."));
    }
    
    override public function addChildAt(child:DisplayObject, index:int):DisplayObject
    {
        throw(new Error("addChildAt is not available in Group. Use addItemAt instead."));
    }
    
    override public function removeChild(child:DisplayObject):DisplayObject
    {
        throw(new Error("removeChild is not available in Group. Use removeItem instead."));
    }
    
    override public function removeChildAt(index:int):DisplayObject
    {
        throw(new Error("removeChildAt is not available in Group. Use removeItemAt instead."));
    }
    
    override public function setChildIndex(child:DisplayObject, index:int):void
    {
        throw(new Error("setChildIndex is not available in Group. Use setItemIndex instead."));
    }
    
    override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
    {
        throw(new Error("swapChildren is not available in Group. Use swapItems instead."));
    }
    
    override public function swapChildrenAt(index1:int, index2:int):void
    {
        throw(new Error("swapChildrenAt is not available in Group. Use swapItemsAt instead."));
    }
    
    protected function invalidateSizeAndLayout():void
    {
        invalidateSize();
        invalidateDisplayList();
        
        if (parent && parent is UIComponent)
        {
            UIComponent(parent).invalidateSize();
            UIComponent(parent).invalidateDisplayList();
        }
    }
    
        //--------------------------------------------------------------------------
    //
    //  Properties: Overriden Focus management
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  focusPane
    //----------------------------------

    /**
     *  @private
     *  Storage for the focusPane property.
     */
    private var _focusPane:Sprite;

    [Inspectable(environment="none")]
    
    // TODO (rfrishbe): only reason we need to override focusPane getter/setter
    // is because addChild/removeChild for Groups throw an RTE.
    // This is the same as UIComponent's focusPane getter/setter but it uses
    // super.add/removeChild.

    override public function get focusPane():Sprite
    {
        return _focusPane;
    }

    override public function set focusPane(value:Sprite):void
    {
        if (value)
        {
            super.addChild(value);

            value.x = 0;
            value.y = 0;
            value.scrollRect = null;

            _focusPane = value;
        }
        else
        {
             super.removeChild(_focusPane);
             
             // TODO: remove mask?  SDK-15310
            _focusPane = null;
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  Content management
    //
    //--------------------------------------------------------------------------
    
    public function get numItems():int
    {
        if (_content === undefined)
            return 0;
            
        switch (_contentType)
        {
            case CONTENT_TYPE_ARRAY:
            case CONTENT_TYPE_ILIST:
                return _content.length;
                break;
        }
        
        return 1;
    }
    
    public function getItemAt(index:int):*
    {
        if (_content === undefined)
            return null;
        
        switch (_contentType)
        {
            case CONTENT_TYPE_ARRAY:
                return _content[index];
                break;
            
            case CONTENT_TYPE_ILIST:
                return _content.length > index ? _content.getItemAt(index) : null;
                break;
        }
        
        return _content;
    }
    
    public function addItem(item:*):*
    {
        return addItemAt(item, numItems);
    }
    
    public function addItemAt(item:*, index:int):*
    {
        // If we don't have any content yet, initialize it to an empty array
        if (_content === undefined)
        {
            content = [];
            contentChanged = false;
        }
        
        // If we have unknown content (ie a single item), convert to an Array
        if (_contentType == CONTENT_TYPE_UNKNOWN)
        {
            _contentType = CONTENT_TYPE_ARRAY;
            _content = [_content];
        }
        
        switch (_contentType)
        {
            case CONTENT_TYPE_ARRAY:
                _content.splice(index, 0, item);
                break;
            
            case CONTENT_TYPE_ILIST:
                _content.addItemAt(item, index);
                break;
        }
        
        itemAdded(item, index);
        
        return item;
    }
    
    public function removeItem(item:*):*
    {
        return removeItemAt(getItemIndex(item));
    }
    
    public function removeItemAt(index:int):*
    {       
        var item:*;
        
        if (_content === undefined)
            return null;
        
        // Need to call itemRemoved before removing the item so anyone listening
        // for the event can access the item.
        
        itemRemoved(index);
        
        switch (_contentType)
        {
            case CONTENT_TYPE_ARRAY:
            {
                var removed:Array = _content.splice(index, 1);
                if (removed && removed.length > 0)
                    item = removed[0];
                break;  
            }
            
            case CONTENT_TYPE_ILIST:
                item = _content.removeItemAt(index);
                break;
                
            case CONTENT_TYPE_UNKNOWN:
            {
            	item = _content;
            	_content = undefined;
            	break;
            }    
        }
            
        return item;
    }
    
    public function getItemIndex(item:*):int
    {
        if (_content === undefined)
            return -1;
        
        switch (_contentType)
        {
            case CONTENT_TYPE_ARRAY:
                return _content.indexOf(item);
                break;
            
            case CONTENT_TYPE_ILIST:
                return _content.getItemIndex(item);
                break;
        }
        
        return 0;
    }
    
    public function setItemIndex(item:*, index:int):void
    {
        removeItem(item);
        addItemAt(item, index);
    }
    
    public function swapItems(item1:*, item2:*):void
    {
        swapItemsAt(getItemIndex(item1), getItemIndex(item2));
    }
    
    public function swapItemsAt(index1:*, index2:*):void
    {
        var item1:* = getItemAt(index1);
        var item2:* = getItemAt(index2);
        
        removeItem(item1);
        removeItem(item2);
        
        addItemAt(item2, index1);
        addItemAt(item1, index2);
    }
    
    //--------------------------------------------------------------------------
    //
    //  Layout item iteration
    //
    //  Iterators used by Layout objects. For visual items, the layout item
    //  is the item itself. For data items, the layout item is the item renderer
    //  instance that is associated with the item.
    //--------------------------------------------------------------------------
     /**
     *  The number of layout items in this Group. Typically this is the same
     *  as the number of items in the Group.
     */
    public function get numLayoutItems():int
    {
        return numItems;
    }
    
    /**
     *  Gets the <i>n</i>th layout item in the Group. For visual items, the 
     *  layout item is the item itself. For data items, the layout item is the 
     *  item renderer instance that is associated with the item.
     *
     *  @param index The index of the item to retrieve.
     *
     *  @return The layout item at the specified index.
     */
    public function getLayoutItemAt(index:int):*
    {
        var item:* = getItemAt(index);   
               
        if (item is IGraphicElement)
            return item;
        else
            return getItemSkin(item);
    }

    
    //--------------------------------------------------------------------------
    //
    //  Content management (internal)
    //
    //--------------------------------------------------------------------------
    
    protected function itemAdded(item:*, index:int):void
    {
        var child:DisplayObject;
        
        // TODO!! Don't add Group this way
        if (item is IGraphicElement && !alwaysUseItemRenderer) 
        {
            child = initElement(IGraphicElement(item), index);
        }   
        else
        {
            child = super.addChildAt(createVisualForItem(item), index);
        }
        
        dispatchEvent(new ItemExistenceChangedEvent(
                      ItemExistenceChangedEvent.ITEM_ADD, false, false, item));
        
        invalidateSize();
        invalidateDisplayList();
    }
    
    protected function itemRemoved(index:int):void
    {       
        var item:* = getItemAt(index);
        var skin:* = getItemSkin(item);
        
        /* if (item is IGraphicElement)
        {
            removeElement(IGraphicElement(item));   
        } */
        dispatchEvent(new ItemExistenceChangedEvent(
                      ItemExistenceChangedEvent.ITEM_REMOVE, false, false, item));        
        if (item && (item is IGraphicElement))
            item.elementHost = null;
        
        // If the item and skin are different objects, set the skin data to 
        // null here to clear it out. Otherwise, the skin keeps a reference to the item,
        // which can cause problems later.
        if (item && skin && item != skin)
            skin.data = null;
            
        super.removeChildAt(index);
        
        invalidateSize();
        invalidateDisplayList();
    }
    
    protected function collectionChangeHandler(event:Event):void
    {
        if (event is CollectionEvent)
        {
            var ce:CollectionEvent = CollectionEvent(event);

            /* if (ce.kind == CollectionEventKind.ADD)
            {
                
            }
            else if (ce.kind == CollectionEventKind.REPLACE)
            {
                
            }
            else if (ce.kind == CollectionEventKind.REMOVE)
            {
                
            }
            else if (ce.kind == CollectionEventKind.MOVE)
            {
                
            }
            else if (ce.kind == CollectionEventKind.REFRESH)
            {
                
            }
            else if (ce.kind == CollectionEventKind.RESET)
            {
            }
            else if (ce.kind == CollectionEventKind.UPDATE)
            {
                
            } */
            
            // TODO!! Fow now, always reapply the content. This needs to
            // be optimized in the future            
           contentChanged = true;
           invalidateProperties();
        }
            
    }
    
    //--------------------------------------------------------------------------
    //
    //  Item -> Skin mapping
    //
    //--------------------------------------------------------------------------
    
    public function getItemSkin(item:*):DisplayObject
    {
        var result:DisplayObject = null;
                    
        if (skinRegistry)
            result = skinRegistry[item];
        
        if (!result && item is DisplayObject)
            result = item;
                
        return result;
    }
    
    public function getSkinItem(skin:DisplayObject):*
    {
        // !! This implementation is really slow... 
        var item:*;
        
        for (var i:int = 0; i < numItems; i++)
        {
            item = getItemAt(i);
            if (getItemSkin(item) == skin)
                return item;
        }
        
        return null;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Layout
    //
    //--------------------------------------------------------------------------
    
    protected function initializeLayoutObject():void
    {
        if (_layoutClass == null)
            _layout = new BasicLayout();
        else
            _layout = new _layoutClass();
        
        _layout.target = this;
            
        invalidateSize();
        invalidateDisplayList();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Graphic Elements Management
    //
    //--------------------------------------------------------------------------
    
    private var elementToDisplayObjectMap:Dictionary;
    
    protected function initElement(element:IGraphicElement, index:int):DisplayObject
    {
        var result:DisplayObject;
        
        element.elementHost = this;
        
        if (!elementToDisplayObjectMap)
            elementToDisplayObjectMap = new Dictionary();
                
        if (element is IDisplayObjectElement)
        {
            var elementDO:DisplayObject = IDisplayObjectElement(element).displayObject;
            elementToDisplayObjectMap[element] = elementDO;
            result = super.addChildAt(elementDO, index);
        }
        else if (element is IAssignableDisplayObjectElement)
        {
            // TODO!!! For now we will always create a DO for the element. 
            // This needs optimization      
            var newShape:DisplayObject = IAssignableDisplayObjectElement(element).createDisplayObject();
            elementToDisplayObjectMap[element] = newShape;
            IAssignableDisplayObjectElement(element).displayObject = newShape;
            result = super.addChildAt(newShape, index);
        }
    
        if (element is ILayoutManagerClient)
            ILayoutManagerClient(element).nestLevel = nestLevel + 1;
        
        return result;
    }
    
    protected function removeElement(element:IGraphicElement):void
    {
        // Find the DO associated with the element
        var assignableElement:IAssignableDisplayObjectElement = element as IAssignableDisplayObjectElement;
        
        if (assignableElement)
        {
            // CLear the DO
            //assignableElement.displayObject = null;
        }
        else
        {
            // TODO!!! Figure out what to do here. 
            var displayElement:IDisplayObjectElement = element as IDisplayObjectElement;
            //if (displayElement)
                
        }
        
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  IGraphicElement Implementation
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  filters
    //----------------------------------
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    private var _actualFilters:Array;
    
    override public function set filters(value:Array):void
    {
        var oldFilters:Array = super.filters ? super.filters.slice() : null;
        var clonedFilters:Array = new Array();
        
        var len:int = value.length;
        _actualFilters = value;
        
        for (var i:int = 0; i < len; i++)
        {
            if (value[i] is IBitmapFilter)
            {
                var edFilter:EventDispatcher = value[i] as EventDispatcher;
                if (edFilter)
                    edFilter.addEventListener(BaseFilter.FILTER_CHANGED_TYPE, filterChangedHandler);
                clonedFilters.push(IBitmapFilter(value[i]).clone());
            }
            else
                clonedFilters.push(value[i]);
        }
        
        super.filters = clonedFilters;
    }
    
    override public function get filters():Array
    {
        return _actualFilters;
    }
    
    //----------------------------------
    //  mask
    //----------------------------------
    private var _mask:DisplayObject;
    private var maskChanged:Boolean;
    
    [Inspectable(category="General")]
    override public function get mask():DisplayObject
    {
        return _mask;
    }
    
    /*
     *  sets the mask. The mask will be added to the display list. The mask must
     *  not already on a display list nor in the elements array.  
     */ 
    override public function set mask(value:DisplayObject):void
    {
        if (_mask !== value)
        {
            _mask = value;
            maskChanged = true;
            invalidateProperties();
            //addDrawnElements();
            
        }
        super.mask = value;         
    } 
    
    //----------------------------------
    //  maskType
    //----------------------------------
    
    [Bindable("propertyChange")]
    [Inspectable(category="General",enumeration="clip,alpha", defaultValue="clip")]
    private var _maskType:String = MaskType.CLIP;
    private var _oldMaskType:String = MaskType.CLIP;
    private var maskTypeChanged:Boolean;
    private var originalMaskFilters:Array;
    
    public function get maskType():String
    {
        return _maskType;
    }
    
    public function set maskType(value:String):void
    {
        if (_maskType != value)
        {
            _oldMaskType = _maskType;
            _maskType = value;
            maskTypeChanged = true;
        }
    }
    
    //----------------------------------
    //  rotation
    //----------------------------------
    
    /**
     *  @private
     */
    private var _rotation:Number = 0;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  The rotation for this group, in degrees.
     */
    override public function get rotation():Number
    {
        return !isNaN(_rotation) ? _rotation : super.rotation;
    }
    
    override public function set rotation(value:Number):void
    {
        if (_rotation != value)
        {
            var oldValue:Number = _rotation;
            
            _rotation = value;
            transformChanged = true;
            invalidateDisplayList();
        }
    }
    
    //----------------------------------
    //  scaleX
    //----------------------------------
    
    private var _scaleX:Number;
    
    /**
     *  Indicates the horizontal scale (percentage) of the element as applied from the transform point.
     */
    override public function get scaleX():Number
    {
        return !isNaN(_scaleX) ? _scaleX : super.scaleX;
    }
    
    
    override public function set scaleX(value:Number):void
    {
        if (_scaleX != value)
        {
            _scaleX = value;
            transformChanged = true;
            invalidateDisplayList();
        }
        
    }
    
    //----------------------------------
    //  scaleY 
    //----------------------------------
    private var _scaleY:Number;
    
    /**
     *  Indicates the vertical scale (percentage) of the element as applied from the transform point.
     */
    override public function get scaleY():Number
    {
        return !isNaN(_scaleY) ? _scaleY : super.scaleY;
    } 
     
    override public function set scaleY(value:Number):void
    {
        if (_scaleY != value)
        {
            _scaleY = value;
            transformChanged = true;
            invalidateDisplayList();
        }
    } 

    //----------------------------------
    //  transform
    //----------------------------------
    private var _transform:flash.geom.Transform;
    private var _matrix:Matrix;
    private var _colorTransform:ColorTransform;
    
    override public function set transform(value:flash.geom.Transform):void
    {
        // Clean up the old event listeners
        var oldTransform:flex.geom.Transform = _transform as flex.geom.Transform;       
        if (oldTransform)
        {
            oldTransform.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, transformPropertyChangeHandler);
        }
        
        var newTransform:flex.geom.Transform = value as flex.geom.Transform;
        
        if (newTransform)
        {   
            newTransform.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, transformPropertyChangeHandler);
            _matrix = value.matrix.clone(); // Make sure it is a copy
            _colorTransform = value.colorTransform; 
        }
    
        _transform = value; 
        super.transform = value; 
    } 
    
    //----------------------------------
    //  transformX
    //----------------------------------
    private var _transformX:Number = 0;
        
    /**
     *  The x position transform point of the element. 
     */
    public function get transformX():Number
    {
        return _transformX;
    }
    
    public function set transformX(value:Number):void
    {
        if (_transformX != value)
        {
            _transformX = value;
            transformChanged = true;
            invalidateDisplayList();
        }
    }
    
    //----------------------------------
    //  transformY
    //----------------------------------
    private var _transformY:Number = 0;
    
    /**
     *  The y position transform point of the element. 
     */
    public function get transformY():Number
    {
        return _transformY;
    }
    
    public function set transformY(value:Number):void
    {
        if (_transformY != value)
        {
            _transformY = value;
            transformChanged = true;
            invalidateDisplayList();
        }
    }

    //----------------------------------
    //  x
    //----------------------------------
    
    private var _x:Number;
    
    override public function get x():Number
    {
        return !isNaN(_x) ? _x : super.x;
    }
    
    override public function set x(value:Number):void
    {
        if (_x != value)
        {
            _x = value;
            transformChanged = true;
            invalidateDisplayList();
        }
    }

    //----------------------------------
    //  y
    //----------------------------------
    
    private var _y:Number;
    
    override public function get y():Number
    {
        return !isNaN(_y) ? _y : super.y;
    }
    
    override public function set y(value:Number):void
    {
        if (_y != value)
        {
            _y = value;
            transformChanged = true;
            invalidateDisplayList();
        }
    }
    
    private function transformPropertyChangeHandler(event:PropertyChangeEvent):void
    {
        if (event.kind == PropertyChangeEventKind.UPDATE)
        {           
            if (event.property == "matrix")
            {
                // Apply matrix
                if (_transform)
                {
                    _matrix = _transform.matrix.clone();
                    transformChanged = true;
                    invalidateDisplayList();
                } 
            }
            else if (event.property == "colorTransform")
            {
                // Apply colorTranform
                if (_transform)
                {
                    _colorTransform = _transform.colorTransform;
                    transformChanged = true;
                    invalidateDisplayList();
                }
            }
        }
    }
    
    private function filterChangedHandler(event:Event):void
    {
        // Reapply the filters
        filters = _actualFilters;
    }
    
    //--------------------------------------------------------------------------
    //
    //  IGraphicElementHost Implementation
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @inheritDoc
     */
    public function elementChanged(e:IGraphicElement):void
    {
        // TODO!!! Optimize
        invalidateSize();
        invalidateDisplayList();    
    }
    
    /**
     *  @inheritDoc
     */
    public function elementSizeChanged(e:IGraphicElement):void
    {
        // TODO!!! Optimize
        invalidateSize();
        invalidateDisplayList();    
    }
    
    /**
     * @inheritDoc
     */
    public function elementLayerChanged(e:IGraphicElement):void
    {
        // TODO!!! Optimize
        // TODO!!! Need to recalculate the elements
        invalidateSize();
        invalidateDisplayList();    
    }
    
    /**
     *  @inheritDoc
     */
    public function get parentGraphic():Graphic
    {
        return null;
    }
    
    protected var maskElements:Dictionary;
    
    public function addMaskElement(mask:DisplayObject, target:IGraphicElement):void
    {
        if (!maskElements)
            maskElements = new Dictionary();
            
        maskElements[mask] = target;
        contentChanged = true;
        invalidateProperties();
            
    }
    
    public function removeMaskElement(mask:DisplayObject, target:IGraphicElement):void
    {
        if (maskElements && mask in maskElements)
        {
            delete maskElements[mask];
            contentChanged = true;
            invalidateProperties();
        }
    }
    
    
    //--------------------------------------------------------------------------
    //
    //  ScaleGrid Implementation
    //
    //--------------------------------------------------------------------------

    private var scaleGridChanged:Boolean = false;

    //----------------------------------
    //  scaleGridBottom
    //----------------------------------

    private var _scaleGridBottom:Number;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     * Specfies the bottom coordinate of the scale grid.
     */
    public function get scaleGridBottom():Number
    {
        return _scaleGridBottom;
    }
    
    public function set scaleGridBottom(value:Number):void
    {
        var oldValue:Number = _scaleGridBottom;
        
        if (value != oldValue)
        {
            _scaleGridBottom = value;
            scaleGridChanged = true;
            invalidateDisplayList();
            dispatchPropertyChangeEvent("scaleGridBottom", oldValue, value);
        }
    }
    
    //----------------------------------
    //  scaleGridLeft
    //----------------------------------

    private var _scaleGridLeft:Number;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     * Specfies the left coordinate of the scale grid.
     */
    public function get scaleGridLeft():Number
    {
        return _scaleGridLeft;
    }
    
    public function set scaleGridLeft(value:Number):void
    {
        var oldValue:Number = _scaleGridLeft;
        
        if (value != oldValue)
        {
            _scaleGridLeft = value;
            scaleGridChanged = true;
            invalidateDisplayList();
            dispatchPropertyChangeEvent("scaleGridLeft", oldValue, value);
        }
    }

    //----------------------------------
    //  scaleGridRight
    //----------------------------------

    private var _scaleGridRight:Number;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     * Specfies the right coordinate of the scale grid.
     */
    public function get scaleGridRight():Number
    {
        return _scaleGridRight;
    }
    
    public function set scaleGridRight(value:Number):void
    {
        var oldValue:Number = _scaleGridRight;
        
        if (value != oldValue)
        {
            _scaleGridRight = value;
            scaleGridChanged = true;
            invalidateDisplayList();
            dispatchPropertyChangeEvent("scaleGridRight", oldValue, value);
        }
    }

    //----------------------------------
    //  scaleGridTop
    //----------------------------------

    private var _scaleGridTop:Number;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     * Specfies the top coordinate of the scale grid.
     */
    public function get scaleGridTop():Number
    {
        return _scaleGridTop;
    }
    
    public function set scaleGridTop(value:Number):void
    {
        var oldValue:Number = _scaleGridTop;
        
        if (value != oldValue)
        {
            _scaleGridTop = value;
            scaleGridChanged = true;
            invalidateDisplayList();
            dispatchPropertyChangeEvent("scaleGridTop", oldValue, value);
        }
    }

    private function dispatchPropertyChangeEvent(prop:String, oldValue:*, value:*):void
    {
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, prop, oldValue, value));
    }
    
}
}
